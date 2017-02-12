import 'dart:io';

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
