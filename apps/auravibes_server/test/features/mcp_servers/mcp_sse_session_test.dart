import 'dart:convert';
import 'dart:io';

import 'package:auravibes_server/src/features/mcp_servers/mcp_sse_session.dart';
import 'package:test/test.dart';

void main() {
  test(
    'handshake, pagination, and tool call use pinned SSE endpoint',
    () async {
      final fixture = await _SseFixture.start();
      addTearDown(fixture.close);
      final session = await McpSseSession.connect(
        fixture.uri,
        InternetAddress.loopbackIPv4,
        bearerToken: 'token',
      );
      addTearDown(session.close);
      final initialized = await session.request(1, 'initialize', {});
      await session.notify('notifications/initialized', {});
      final first = await session.request(2, 'tools/list', {});
      final second = await session.request(3, 'tools/list', {'cursor': 'next'});
      final called = await session.request(4, 'tools/call', {
        'name': 'echo',
        'arguments': {'message': 'hello'},
      });
      expect(initialized['protocolVersion'], '2025-06-18');
      expect(first['nextCursor'], 'next');
      expect((second['tools'] as List).single['name'], 'echo');
      expect((called['content'] as List).single['text'], 'hello');
      expect(fixture.bearerHeaders, everyElement('Bearer token'));
    },
  );

  test('rejects cross-origin endpoint before posting', () async {
    final fixture = await _SseFixture.start(
      endpoint: 'https://other.example/messages',
    );
    addTearDown(fixture.close);
    await expectLater(
      McpSseSession.connect(fixture.uri, InternetAddress.loopbackIPv4),
      throwsFormatException,
    );
    expect(fixture.posts, 0);
  });

  test('rejects handshake redirect and oversized event', () async {
    final redirect = await _SseFixture.start(redirect: true);
    addTearDown(redirect.close);
    await expectLater(
      McpSseSession.connect(redirect.uri, InternetAddress.loopbackIPv4),
      throwsA(isA<HttpException>()),
    );
    final oversized = await _SseFixture.start(oversized: true);
    addTearDown(oversized.close);
    await expectLater(
      McpSseSession.connect(oversized.uri, InternetAddress.loopbackIPv4),
      throwsFormatException,
    );
  });

  test('rejects message endpoint redirect', () async {
    final fixture = await _SseFixture.start(redirectPosts: true);
    addTearDown(fixture.close);
    final session = await McpSseSession.connect(
      fixture.uri,
      InternetAddress.loopbackIPv4,
    );
    addTearDown(session.close);
    await expectLater(
      session.request(1, 'initialize', {}),
      throwsA(isA<HttpException>()),
    );
  });
}

class _SseFixture {
  _SseFixture(
    this.server,
    this.endpoint,
    this.redirect,
    this.oversized,
    this.redirectPosts,
  );

  final HttpServer server;
  final String? endpoint;
  final bool redirect;
  final bool oversized;
  final bool redirectPosts;
  final bearerHeaders = <String?>[];
  HttpResponse? events;
  int posts = 0;

  Uri get uri => Uri.parse('http://example.com:${server.port}/sse');

  static Future<_SseFixture> start({
    String? endpoint,
    bool redirect = false,
    bool oversized = false,
    bool redirectPosts = false,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fixture = _SseFixture(
      server,
      endpoint,
      redirect,
      oversized,
      redirectPosts,
    );
    server.listen(fixture._handle);
    return fixture;
  }

  Future<void> _handle(HttpRequest request) async {
    bearerHeaders.add(request.headers.value(HttpHeaders.authorizationHeader));
    if (request.method == 'GET') {
      if (redirect) {
        request.response
          ..statusCode = HttpStatus.found
          ..headers.set(HttpHeaders.locationHeader, 'https://other.example/');
        await request.response.close();
        return;
      }
      events = request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('text', 'event-stream')
        ..bufferOutput = false;
      if (oversized) {
        events!.write('event: endpoint\ndata: ${'x' * (1024 * 1024 + 1)}\n\n');
      } else {
        events!.write('event: endpoint\ndata: ${endpoint ?? '/messages'}\n\n');
      }
      await events!.flush();
      return;
    }
    posts++;
    if (redirectPosts) {
      request.response
        ..statusCode = HttpStatus.found
        ..headers.set(HttpHeaders.locationHeader, 'https://other.example/');
      await request.response.close();
      return;
    }
    final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
    final id = body['id'];
    final method = body['method'];
    request.response.statusCode = HttpStatus.accepted;
    await request.response.close();
    if (id == null) return;
    final result = switch (method) {
      'initialize' => {'protocolVersion': '2025-06-18'},
      'tools/list' when body['params']['cursor'] == 'next' => {
        'tools': [
          {'name': 'echo'},
        ],
      },
      'tools/list' => {'tools': <Object>[], 'nextCursor': 'next'},
      'tools/call' => {
        'content': [
          {'type': 'text', 'text': body['params']['arguments']['message']},
        ],
      },
      _ => <String, Object>{},
    };
    events!.write(
      'event: message\ndata: ${jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result})}\n\n',
    );
    await events!.flush();
  }

  Future<void> close() async {
    await events?.close();
    await server.close(force: true);
  }
}
