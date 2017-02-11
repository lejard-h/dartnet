library dartnet.handler;

import 'dart:async';
import 'dart:io';

import 'package:resource/resource.dart';
import 'package:mustache/mustache.dart';
import 'package:jaguar/jaguar.dart';
import 'config.dart';
import 'utils.dart';
import 'logger.dart';

class ServeRoot extends RequestHandler {
  final JaguarServerConfiguration config;
  final Directory _rootDirectory;

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
  String _requestedPath(Request request) {
    String path = request.uri.path;
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
    String path = getFromMap(config.redirections, error);
    if (path != null) {
      File file = new File(_pathFromRootDir(path));
      if (file?.existsSync() == true) {
        return file;
      }
    }
    return null;
  }

  @override
  Future<Response> handleRequest(Request request, {String prefix}) async {
    Stopwatch timer = new Stopwatch()..start();
    int status = 200;
    String path = _requestedPath(request);
    FileSystemEntity entity = _pathInCache(path) ?? _findEntity(path);

    if (entity == null) {
      entity = _findEntity(config.redirectionDefault);
    }

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
    return _response(response, request, timer.elapsed);
  }

  Response _fileSystemToResponse(FileSystemEntity entity) {
    if (entity is File) {
      return _sendFile(entity);
    } else if (entity is Directory) {
      return _listDirectory(entity);
    }
    return null;
  }

  File get _notFoundFile {}

  FileSystemEntity _default() {
    File notFound = _notFoundFile;
    if (notFound != null && notFound.existsSync() == true) {
      return notFound;
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
      list.add({"href": '$currentPath${e.path.replaceFirst(dir.path,"")}', "text": e.path.replaceFirst(dir.path, "")});
    });

    String render = _listTmpl.renderString({"currentPath": currentPath, "list": list});
    return new Response(render)..headers.mimeType = "text/html";
  }

  Response _errorTemplate(int error) {
    String render = _errorTmpl.renderString({"name": config.pubspec.projectName, "error": error});
    return new Response(render)..headers.mimeType = "text/html";
  }

  Response _sendFile(File file) => new Response(file.openRead())..headers.mimeType = fileType(file);

  Response _response(Response response, Request request, Duration processingDuration) {
    config.log.info(
        "[${request.method}] ${request.uri.path} - ${response.statusCode.toString()} - ${processingDuration.inMicroseconds / 1000 }ms");
    return response;
  }
}
