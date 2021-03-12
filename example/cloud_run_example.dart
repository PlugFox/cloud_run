import 'package:cloud_run/cloud_run.dart';

void main() => runServer(
      router: router,
      port: 8080,
    );

final router = {
  Route(
      method: 'get', path: '/', handler: (_, __) => ServerResponse.json(null)),
  Route(
    method: 'get',
    path: '/json',
    handler: (_, __) => ServerResponse.json(
      {'key': 'value'},
      headers: <String, String>{'A': 'B'},
    ),
  ),
  Route(
      method: 'get',
      path: '/text',
      handler: (_, __) => ServerResponse.text('Some text')),
};
