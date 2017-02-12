import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:jaguar/jaguar.dart';

final ZLibEncoder gzip = new ZLibEncoder(gzip: true);
final Utf8Encoder utf8 = new Utf8Encoder();

Response compressToGzip(Response response) {
  if (response.value is Stream<List<int>>) {
    return response
      ..headers.set(HttpHeaders.CONTENT_ENCODING, 'gzip')
      ..value = gzip.bind(response.value);
  } else if (response.value is String) {
    return response
      ..headers.set(HttpHeaders.CONTENT_ENCODING, 'gzip')
      ..headers.charset = 'utf-8'
      ..value = gzip.bind(utf8.bind(response.value));
  }
  return response;
}

enum Compression { None, Gzip }

const Map<String, Compression> compressionMapper = const {
  'NONE': Compression.None,
  'GZIP': Compression.Gzip
};
