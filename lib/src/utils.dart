import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:jaguar/jaguar.dart';
import 'handler.dart';

const Map<String, String> extMapper = const {
  "html": "text/html",
  "js": "application/javascript",
  "css": "text/css",
  "dart": "application/dart",
  "png": "image/png",
  "jpg": "image/jpeg",
  "jpeg": "image/jpeg",
  "gif": "image/gif"
};

String fileType(File file) => extMapper[file.path.split(".").last] ?? "text/plain";

Response sendFile(File file) => new Response(file.openRead())..headers.mimeType = fileType(file);

Response sendResponse(Response response, Request request, Duration processingDuration) {
  dartnetConfiguration.log.info("[${request.method}] ${request.uri.path} - ${response.statusCode} - ${processingDuration
      .inMicroseconds / 1000 }ms");
  return response;
}

Response listDirectory(Directory dir) {
  List<FileSystemEntity> entities = dir.listSync();

  String currentPath = dir.path.replaceFirst(dartnetConfiguration.rootDirectory.path, "");
  while (currentPath.startsWith("/")) currentPath = currentPath.replaceFirst("/", "");
  currentPath = "/$currentPath";

  List<Map> list = [];
  entities.forEach((FileSystemEntity e) {
    list.add({"href": '$currentPath${e.path.replaceFirst(dir.path, "")}', "text": e.path.replaceFirst(dir.path, "")});
  });

  String render = dartnetConfiguration.listTmpl.renderString({"currentPath": currentPath, "list": list});
  return new Response(render)..headers.mimeType = "text/html";
}

String pathFromRootDir(String path) => "${dartnetConfiguration.rootDirectory.path}/$path";

FileSystemEntity findEntity(String path) {
  FileSystemEntity entity = new File(pathFromRootDir(path));
  if (entity?.existsSync() == true) {
    return entity;
  } else {
    entity = new Directory(pathFromRootDir(path));
    if (entity?.existsSync() == true && dartnetConfiguration.listDirectory == true) {
      return entity;
    }
  }
  return null;
}

FileSystemEntity pathInCache(String path) => dartnetConfiguration.cache[path];

FileSystemEntity onNotFound() {
  String path = dartnetConfiguration.redirections.onNotFound;
  if (path != null) {
    File file = new File(pathFromRootDir(path));
    if (file?.existsSync() == true) {
      return file;
    }
  }
  return null;
}

Response fileSystemToResponse(FileSystemEntity entity) {
  if (entity is File) {
    return sendFile(entity);
  } else if (entity is Directory) {
    return listDirectory(entity);
  }
  return null;
}

Response errorTemplate(int error) {
  String render = dartnetConfiguration.errorTmpl.renderString({"error": error});
  return new Response(render)
    ..headers.mimeType = "text/html"
    ..statusCode = error;
}

const String proxyName = "Darnet";
Future<Response> responseFromCache(Request request, String path) async {
  if (dartnetConfiguration.cache[path] != null) {
    if (dartnetConfiguration.cache[path] is FileSystemEntity) {
      return fileSystemToResponse(dartnetConfiguration.cache[path]);
    } else if (dartnetConfiguration.cache[path] is Uri) {
      return redirect(request, path, dartnetConfiguration.cache[path]);
    }
  }
  return null;
}

HttpClient _client = new HttpClient();

Future<Response> redirect(Request req, String from, Uri to) async {
  Uri requestUrl = to.resolve(from);
  _client.badCertificateCallback = (_, __, ___) {
    return true;
  };

  final HttpClientRequest clientReq = await _client.openUrl(req.method, requestUrl);

  req.headers.forEach((String key, dynamic val) {
    clientReq.headers.add(key, val);
  });
  clientReq.headers.set(HttpHeaders.HOST, requestUrl.authority);

  // Add a Via header. See
  // http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.45
  clientReq.headers.add(HttpHeaders.VIA, '${req.protocolVersion} $proxyName');

  clientReq.add(await req.body);
  final HttpClientResponse clientResp = await clientReq.close();

  final servResp = new Response<Stream<List<int>>>(clientResp, statusCode: clientResp.statusCode);

  clientResp.headers.forEach((String key, List<String> vals) {
    servResp.headers.headers[key] ??= [];
    for (String val in vals) {
      if (servResp.headers.headers[key].contains(val) == false) {
        servResp.headers.headers[key].add(val);
      }
    }
  });

  servResp.headers.removeAll('x-content-type-options');
  servResp.headers.removeAll('x-frame-options');
  servResp.headers.removeAll('x-xss-protection');

  // Add a Via header. See
  // http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.45
  servResp.headers.add(HttpHeaders.VIA, '1.1 $proxyName');

  // Remove the transfer-encoding since the body has already been decoded by
  // [client].
  servResp.headers.removeAll(HttpHeaders.TRANSFER_ENCODING);

  // If the original response was gzipped, it will be decoded by [client]
  // and we'll have no way of knowing its actual content-length.
  if (clientResp.headers.value(HttpHeaders.CONTENT_ENCODING) == 'gzip') {
    servResp.headers.removeAll(HttpHeaders.CONTENT_ENCODING);
    servResp.headers.removeAll(HttpHeaders.CONTENT_LENGTH);

    // Add a Warning header. See
    // http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13.5.2
    servResp.headers.add(HttpHeaders.WARNING, '214 $proxyName "GZIP decoded"');
  }

  // Make sure the Location header is pointing to the proxy server rather
  // than the destination server, if possible.
  if (clientResp.isRedirect && clientResp.headers.value(HttpHeaders.LOCATION) != null) {
    var location = requestUrl.resolve(clientResp.headers.value(HttpHeaders.LOCATION)).toString();
    if (p.url.isWithin(requestUrl.toString(), location)) {
      servResp.headers.set(HttpHeaders.LOCATION, '/' + p.url.relative(location, from: requestUrl.toString()));
    } else {
      servResp.headers.set(HttpHeaders.LOCATION, location);
    }
  }

  return servResp;
}
