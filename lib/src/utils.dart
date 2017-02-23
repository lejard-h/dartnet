import 'dart:io';
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

String fileType(File file) =>
    extMapper[file.path.split(".").last] ?? "text/plain";

Response sendFile(File file) => new Response(file.openRead())..headers.mimeType = fileType(file);

Response sendResponse(Response response, Request request, Duration processingDuration) {
  dartnetConfiguration.log.info("[${request.method}] ${request.uri.path} - ${response.statusCode.toString()} - ${processingDuration
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
  return new Response(render)..headers.mimeType = "text/html"..statusCode = error;
}

Response responseFromCache(String path) {
  if (dartnetConfiguration.cache[path] != null) {
    if (dartnetConfiguration.cache[path] is FileSystemEntity) {
      return fileSystemToResponse(dartnetConfiguration.cache[path]);
    } else if (dartnetConfiguration.cache[path] is Uri) {
      return new Response(dartnetConfiguration.cache[path])..statusCode = 301;
    }
  }
  return null;
}