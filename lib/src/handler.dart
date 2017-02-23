library dartnet.handler;

import 'dart:async';
import 'dart:io';

import 'package:resource/resource.dart';
import 'package:mustache/mustache.dart';
import 'package:jaguar/jaguar.dart';
import 'package:path/path.dart' as p;
import 'config.dart';
import 'utils.dart';

class ServeRoot extends RequestHandler {
  final DartnetConfiguration config;
  final Directory _rootDirectory;
  final String proxyName = "Dartnet";

  Template _listTmpl;
  Template _errorTmpl;

  Map<String, FileSystemEntity> _cache = {};

  ServeRoot(this.config) : _rootDirectory = new Directory(config.rootDirectory) {
    Resource resourceList = new Resource("package:dartnet/src/template/list.html");
    resourceList.readAsString().then((template) {
      _listTmpl = new Template(template);
    });
    Resource resource404 = new Resource("package:dartnet/src/template/error.html");
    resource404.readAsString().then((template) {
      _errorTmpl = new Template(template);
    });
  }

  FileSystemEntity _pathInCache(String path) => _cache[path];

  String _requestedPath(String path) {
    if (path.isEmpty == true || path == "/") {
      path = "index.html";
    }
    return path;
  }

  FileSystemEntity _findEntity(String path) {
    FileSystemEntity entity = new File(_pathFromRootDir(path));
    if (entity?.existsSync() == true) {
      return entity;
    } else {
      entity = new Directory(_pathFromRootDir(path));
      if (entity?.existsSync() == true && config.listDirectory == true) {
        return entity;
      }
    }
    return null;
  }

  String _pathFromRootDir(String path) => "${_rootDirectory.path}/$path";

  FileSystemEntity _processError(int error) {
    String path = config.redirections.onError.redirectionFor(error);
    if (path != null) {
      File file = new File(_pathFromRootDir(path));
      if (file?.existsSync() == true) {
        return file;
      }
    }
    return null;
  }

  final HttpClient _client = new HttpClient();

  Future<Response> _redirectResponse(PathRedirection redirection, Request req, Stopwatch timer) async {
    // TODO: Handle TRACE requests correctly. See
    // http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.8

    Uri proxyBaseUrl = Uri.parse(redirection.from);

    try {
      _client.badCertificateCallback = (_, __, ___) {
        return true;
      };
      final HttpClientRequest clientReq = await _client.openUrl(req.method, redirection.to);
      clientReq.followRedirects = false;

      req.headers.forEach((String key, dynamic val) {
        clientReq.headers.add(key, val);
      });
      //TODO add forward headers
      clientReq.headers.set('Host', proxyBaseUrl.authority);

      // Add a Via header. See
      // http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.45
      clientReq.headers.add('via', '${req.protocolVersion} $proxyName');

      clientReq.add(await req.body);
      final HttpClientResponse clientResp = await clientReq.close();

      if (clientResp.statusCode == HttpStatus.NOT_FOUND) {
        return null;
      }

      final servResp = new Response<Stream<List<int>>>(clientResp, statusCode: clientResp.statusCode);

      clientResp.headers.forEach((String key, dynamic val) {
        servResp.headers.add(key, val);
      });

      // Add a Via header. See
      // http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.45
      servResp.headers.add('via', '0.2.0 $proxyName');

      // Remove the transfer-encoding since the body has already been decoded by
      // [client].
      servResp.headers.removeAll('transfer-encoding');

      // If the original response was gzipped, it will be decoded by [client]
      // and we'll have no way of knowing its actual content-length.
      if (clientResp.headers.value('content-encoding') == 'gzip') {
        servResp.headers.removeAll('content-encoding');
        servResp.headers.removeAll('content-length');

        // Add a Warning header. See
        // http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13.5.2
        servResp.headers.add('warning', '214 $proxyName "GZIP decoded"');
      }

      // Make sure the Location header is pointing to the proxy server rather
      // than the destination server, if possible.
      if (clientResp.isRedirect && clientResp.headers.value('location') != null) {
        var location = redirection.to.resolve(clientResp.headers.value('location')).toString();
        if (p.url.isWithin(proxyBaseUrl.toString(), location)) {
          servResp.headers.set('location', '/' + p.url.relative(location, from: proxyBaseUrl.toString()));
        } else {
          servResp.headers.set('location', location);
        }
      }

      return _response(servResp, req, timer.elapsed);
    } catch (e,s) {
      print(e);
      print(s);
    }
    return null;
  }

  Response _localResponse(Uri uri) {
    String path = _requestedPath(uri.path);
    var entity;

    int status = 200;
    entity = _pathInCache(path) ?? _findEntity(path);

    if (entity == null) {
      status = 404;
      entity = _processError(status);
    }

    _cache[path] = entity;

    Response response;
    if (entity == null) {
      status = 404;
      response = _errorTemplate(status);
    } else {
      response = _fileSystemToResponse(entity);
    }
    response.statusCode = status;
    return response;
  }

  @override
  Future<Response> handleRequest(Request request, {String prefix}) async {
    Stopwatch timer = new Stopwatch()..start();
    PathRedirection redirection = config.redirections.path.match(request.uri.path);
    if (redirection?.isOutside == true) {
      return _redirectResponse(redirection, request, timer);
    }
    Uri uri = redirection?.to ?? request.uri;
    return _response(_localResponse(uri), request, timer.elapsed);
  }

  Response _fileSystemToResponse(FileSystemEntity entity) {
    if (entity is File) {
      return _sendFile(entity);
    } else if (entity is Directory) {
      return _listDirectory(entity);
    }
    return null;
  }

  Response _listDirectory(Directory dir) {
    List<FileSystemEntity> entities = dir.listSync();

    String currentPath = dir.path.replaceFirst(_rootDirectory.path, "");
    while (currentPath.startsWith("/")) currentPath = currentPath.replaceFirst("/", "");
    currentPath = "/$currentPath";

    List<Map> list = [];
    entities.forEach((FileSystemEntity e) {
      list.add({"href": '$currentPath${e.path.replaceFirst(dir.path, "")}', "text": e.path.replaceFirst(dir.path, "")});
    });

    String render = _listTmpl.renderString({"currentPath": currentPath, "list": list});
    return new Response(render)..headers.mimeType = "text/html";
  }

  Response _errorTemplate(int error) {
    String render = _errorTmpl.renderString({"error": error});
    return new Response(render)..headers.mimeType = "text/html";
  }

  Response _sendFile(File file) => new Response(file.openRead())..headers.mimeType = fileType(file);

  Response _response(Response response, Request request, Duration processingDuration) {
    config.log.info("[${request.method}] ${request.uri.path} - ${response.statusCode.toString()} - ${processingDuration
            .inMicroseconds / 1000 }ms");
    return response;
  }
}
