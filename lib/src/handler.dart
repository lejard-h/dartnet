library dartnet.handler;

import 'dart:async';
import 'package:jaguar/jaguar.dart';
import 'config.dart';
import 'utils.dart';

DartnetConfiguration dartnet;

FutureOr<Response> cacheHandler(Context context) async {
  final timer = Stopwatch()..start();
  final entity = await responseFromCache(context.req, context.req.uri.path);
  if (entity != null) {
    logResponse(entity, context.req, timer.elapsed);
  }
  timer.stop();
  return entity;
}

FutureOr<Response> dartnetHandler(Context context) async {
  final timer = new Stopwatch()..start();

  Response response;

  response = await findEntity(context.req.uri.path);

  response ??= await onNotFound();

  response ??= errorTemplate(404);

  logResponse(response, context.req, timer.elapsed);
  timer.stop();
  return response;
}

RouteHandler pathRedirectionHandler(Uri redirect) => (Context ctx) async {
      Stopwatch timer = new Stopwatch()..start();
      if (redirect.scheme == "http" || redirect.scheme == "https") {
        dartnet.cache[ctx.req.uri.path] = redirect;
      } else {
        dartnet.cache[ctx.req.uri.path] = findEntity(redirect.path);
      }
      final response = await responseFromCache(ctx.req, ctx.req.uri.path);
      if (response != null) {
        logResponse(response, ctx.req, timer.elapsed);
      }
      return response;
    };
