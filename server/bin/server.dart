import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:dotenv/dotenv.dart';

void main(List<String> args) async {
  load(); // Loads .env

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler((Request request) {
    return Response.ok('🟢 Dart server is running!');
  });

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  print('✅ Serving at http://${server.address.host}:${server.port}');
}
