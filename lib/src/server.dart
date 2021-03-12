import 'dart:async';
import 'dart:io' as io;

import 'favicon_stub.dart';
import 'log.dart';
import 'response.dart';

typedef Handler = FutureOr<ServerResponse> Function(
  Stream<List<int>> body,
  io.HttpHeaders requestHeaders,
);

class Route {
  final String path;
  final String method;
  final Handler handler;
  Route({
    required String path,
    required String method,
    required this.handler,
  })   : path = path.toLowerCase(),
        method = method.toUpperCase();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Route && path == other.path && method == other.method);

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => '[$method] $path';
}

final Map<int, Route> _innerRouter = <int, Route>{};

void runServer({
  required Set<Route> router,
  io.InternetAddress? address,
  int port = 8080,
  List<String> args = const [],
}) =>
    runZonedGuarded(
      () async {
        /// Приготовимся к завершению приложения
        // ignore: cancel_subscriptions
        StreamSubscription? sigIntSub, sigTermSub;
        final shutdownCompleter = Completer<bool>.sync();
        final shutdownSignal = shutdownCompleter.future;

        {
          Future<void> signalHandler(io.ProcessSignal signal) async {
            log('Received signal $signal - closing');

            final subCopy = sigIntSub;
            if (subCopy != null) {
              sigIntSub = null;
              await subCopy.cancel();
              sigIntSub = null;
              if (sigTermSub != null) {
                await sigTermSub!.cancel();
                sigTermSub = null;
              }
              shutdownCompleter.complete(true);
            }
          }

          sigIntSub = io.ProcessSignal.sigint.watch().listen(signalHandler);
          // SIGTERM is not supported on Windows. Attempting to register a SIGTERM
          // handler raises an exception.
          if (!io.Platform.isWindows) {
            sigTermSub = io.ProcessSignal.sigterm.watch().listen(signalHandler);
          }
        }

        /// Подготовим внутренний роутер
        {
          final faviconRoute =
              Route(path: '/favicon.ico', method: 'GET', handler: faviconStub);
          _innerRouter[faviconRoute.hashCode] = faviconRoute;
          for (final route in router) {
            _innerRouter[route.hashCode] = route;
          }
        }

        /// Start server
        final server = await io.HttpServer.bind(
          address ?? io.InternetAddress.anyIPv6,
          port,
        );

        /// Start handler
        final serverSubscription = server.listen(_requestHandler);
        log('Listening server on [${server.address.host}]:${server.port}');

        /// Shutdown
        {
          final force = await shutdownSignal;
          await server.close(force: force).timeout(const Duration(seconds: 25));
          await serverSubscription
              .cancel()
              .timeout(const Duration(seconds: 25));
          io.exit(0);
        }
      },
      (error, stackTrace) async {
        err('[ERR] ${error.toString()}');
        io.exit(2);
      },
    );

Future<void> _requestHandler(io.HttpRequest request) async {
  final method = request.method.toUpperCase();
  final path = request.uri.path.toLowerCase();
  final routeString = '[$method] $path';
  log('[REQ] $routeString');
  final route = _innerRouter[routeString.hashCode];
  if (route is! Route) {
    request.response.statusCode = io.HttpStatus.notFound;
    await request.response.close().timeout(const Duration(seconds: 15));
    log('[RSP] $routeString -> ${io.HttpStatus.notFound}');
    return;
  }
  try {
    final response = await route.handler(request, request.headers);
    request.response
      ..headers.persistentConnection = false
      ..statusCode = response.statusCode;
    for (final header in response.headers.entries) {
      request.response.headers.set(header.key, header.value);
    }
    await request.response
        .addStream(response.data)
        .timeout(const Duration(seconds: 25));
    await request.response.close().timeout(const Duration(seconds: 5));
    log('[RSP] $routeString -> ${response.statusCode}');
    return;
  } on Object {
    request.response.statusCode = io.HttpStatus.internalServerError;
    await request.response.close().timeout(const Duration(seconds: 5));
    err('[RSP] $routeString -> ${io.HttpStatus.internalServerError}');
    rethrow;
  }
}
