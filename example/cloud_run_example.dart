import 'package:cloud_run/cloud_run.dart';

void main() => runServer(
      router: router,
      concurrency: 3,
    );

final router = {
  Route(
      method: 'GET',
      path: '/',
      handler: (_, __) => Future<void>.delayed(const Duration(seconds: 5))
          .then<ServerResponse>((_) => ServerResponse.text('Hello world'))),
  Route(
      method: 'GET',
      path: '/json',
      handler: (_, __) => ServerResponse.json({'key': 'value'})),
  Route(
      method: 'POST',
      path: '/text',
      handler: (_, __) => ServerResponse.text('Some text')),
};
