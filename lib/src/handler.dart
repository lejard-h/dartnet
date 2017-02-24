library dartnet.handler;

import 'dart:async';
import 'package:glob/glob.dart';
import 'package:jaguar/jaguar.dart';
import 'config.dart';
import 'utils.dart';

DartnetConfiguration dartnetConfiguration;

class CacheHandler extends RequestHandler {
  @override
  Future<Response> handleRequest(Request request, {String prefix}) async {
    Stopwatch timer = new Stopwatch()..start();
    var entity = await responseFromCache(request, request.uri.path);
    if (entity != null) {
      return sendResponse(entity, request, timer.elapsed);
    }
    return null;
  }
}

class DartnetHandler extends RequestHandler {
  @override
  Future<Response> handleRequest(Request request, {String prefix}) async {
    Stopwatch timer = new Stopwatch()..start();
    var entity = fileSystemToResponse(findEntity(request.uri.path)) ??
        onNotFound() ??
        errorTemplate(404);
    return sendResponse(entity, request, timer.elapsed);
  }
}

class PathRedirectionHandler implements RequestHandler {
  final Uri _redirect;
  final String _from;

  PathRedirectionHandler(this._from, String to) : _redirect = Uri.parse(to);

  PathRedirectionHandler.toUri(this._from, this._redirect);

  @override
  Future<Response> handleRequest(Request request, {String prefix: ""}) async {
    Stopwatch timer = new Stopwatch()..start();
    Glob glob = new Glob(_from);
    if (_from == request.uri.path ||
        glob.allMatches(request.uri.path).isNotEmpty) {
      if (_redirect.scheme == "http" || _redirect.scheme == "https") {
        dartnetConfiguration.cache[request.uri.path] = _redirect;
      } else {
        dartnetConfiguration.cache[request.uri.path] =
            findEntity(_redirect.path);
      }
      return sendResponse(await responseFromCache(request, request.uri.path), request, timer.elapsed);
    }
    return null;
  }
}
