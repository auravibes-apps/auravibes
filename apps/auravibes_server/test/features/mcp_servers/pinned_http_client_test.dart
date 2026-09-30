import 'dart:io';

import 'package:auravibes_server/src/features/mcp_servers/pinned_http_client.dart';
import 'package:test/test.dart';

void main() {
  test('HTTPS to pinned IP still starts TLS for the requested host', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final received = <int>[];
    final waiting = server.first.then((socket) async {
      await for (final bytes in socket) {
        received.addAll(bytes);
        break;
      }
      socket.destroy();
    });
    final client = pinnedHttpClient(
      Uri.parse('https://example.com:${server.port}/mcp'),
      InternetAddress.loopbackIPv4,
    );
    addTearDown(() => client.close(force: true));

    await expectLater(
      client.getUrl(Uri.parse('https://example.com:${server.port}/mcp')),
      throwsA(isA<HandshakeException>()),
    );
    await waiting;
    expect(received.take(3).toList(), isNot('GET'.codeUnits));
  });

  test('rejects another origin and proxy before connecting', () async {
    final client = pinnedHttpClient(
      Uri.parse('https://example.com/mcp'),
      InternetAddress.loopbackIPv4,
    )..findProxy = (_) => 'PROXY proxy.example:8080';
    addTearDown(() => client.close(force: true));
    await expectLater(
      client.getUrl(Uri.parse('https://example.com/mcp')),
      throwsA(isA<SocketException>()),
    );
    client.findProxy = (_) => 'DIRECT';
    await expectLater(
      client.getUrl(Uri.parse('https://another.example/mcp')),
      throwsA(isA<SocketException>()),
    );
  });

  test('does not follow redirects to another origin', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    var requests = 0;
    final serving = server.listen((request) async {
      requests++;
      request.response
        ..statusCode = HttpStatus.found
        ..headers.set(HttpHeaders.locationHeader, 'http://another.example/');
      await request.response.close();
    });
    addTearDown(serving.cancel);
    final uri = Uri.parse('http://example.com:${server.port}/mcp');
    final client = pinnedHttpClient(uri, InternetAddress.loopbackIPv4);
    addTearDown(() => client.close(force: true));
    final request = await client.getUrl(uri);
    request.followRedirects = false;
    final response = await request.close();
    await response.drain<void>();
    expect(response.isRedirect, isTrue);
    expect(requests, 1);
  });
}
