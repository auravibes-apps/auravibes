import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auravibes_server/src/features/mcp_servers/mcp_oauth_credentials.dart';
import 'package:auravibes_server/src/features/mcp_servers/mcp_oauth_token_resolver.dart';
import 'package:test/test.dart';

void main() {
  final credentials = McpOAuthCredentials(
    clientId: 'client',
    tokenEndpoint: 'https://8.8.8.8/token',
    accessToken: 'old-access-secret',
    refreshToken: 'old-refresh-secret',
    issuedAt: DateTime.utc(2026),
    expiresIn: 3600,
  );

  Future<McpOAuthCredentials> refresh(
    int status,
    String body, {
    Exception? error,
  }) => HttpOverrides.runZoned(
    () => refreshMcpOAuthToken(credentials),
    createHttpClient: (_) => _Client(status, body, error),
  );

  test('structured invalid_grant needs reauthentication', () async {
    await expectLater(
      refresh(
        400,
        '{"error":"invalid_grant","error_description":"provider-secret"}',
      ),
      throwsA(isA<McpOAuthReauthRequired>()),
    );
  });

  for (final status in [429, 500, 503]) {
    test('HTTP $status stays retryable despite invalid_grant text', () async {
      await expectLater(
        refresh(
          status,
          '{"error":"invalid_grant","error_description":"provider-secret"}',
        ),
        throwsA(
          isA<McpOAuthRefreshFailed>().having(
            (e) => e.retryable,
            'retryable',
            true,
          ),
        ),
      );
    });
  }

  for (final error in [
    TimeoutException('provider-secret'),
    const SocketException('provider-secret'),
    const HttpException('provider-secret'),
  ]) {
    test('${error.runtimeType} stays retryable and sanitized', () async {
      await expectLater(
        refresh(200, '', error: error),
        throwsA(
          isA<McpOAuthRefreshFailed>()
              .having((e) => e.retryable, 'retryable', true)
              .having(
                (e) => e.toString(),
                'diagnostic',
                isNot(contains('provider-secret')),
              ),
        ),
      );
    });
  }

  for (final response in [
    (
      400,
      '{"error":"unknown","error_description":"invalid_grant old-refresh-secret"}',
    ),
    (401, '{"error_description":"revoked old-refresh-secret"}'),
    (200, 'not-json old-access-secret'),
    (200, '{"access_token":"old-access-secret"}'),
    (302, '{"error":"invalid_grant"}'),
  ]) {
    test(
      'unknown response ${response.$1} preserves credentials without automatic retry',
      () async {
        await expectLater(
          refresh(response.$1, response.$2),
          throwsA(
            isA<McpOAuthRefreshFailed>()
                .having((e) => e.retryable, 'retryable', false)
                .having(
                  (e) => e.toString(),
                  'diagnostic',
                  isNot(contains('secret')),
                ),
          ),
        );
      },
    );
  }

  test(
    'success rotates tokens and preserves refresh token when omitted',
    () async {
      final rotated = await refresh(
        200,
        '{"access_token":"new-access","refresh_token":"new-refresh","expires_in":3600}',
      );
      expect(rotated.accessToken, 'new-access');
      expect(rotated.refreshToken, 'new-refresh');
      final retained = await refresh(
        200,
        '{"access_token":"new-access","expires_in":3600}',
      );
      expect(retained.refreshToken, credentials.refreshToken);
    },
  );

  test('fences the token HTTP dispatch after address validation', () async {
    final client = _Client(
      200,
      '{"access_token":"new-access","expires_in":3600}',
      null,
    );
    var dispatches = 0;
    final rotated = await HttpOverrides.runZoned(
      () => refreshMcpOAuthToken(
        credentials,
        resolvedAddresses: [InternetAddress('8.8.8.8')],
        dispatchFence: <T>(Future<T> Function() start) async {
          dispatches++;
          return start();
        },
      ),
      createHttpClient: (_) => client,
    );

    expect(rotated.accessToken, 'new-access');
    expect(dispatches, 1);
    expect(client.postCalls, 1);
  });
}

class _Client(this.status, this.body, this.error) implements HttpClient {
  final int status;
  final String body;
  final Exception? error;
  var postCalls = 0;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    postCalls++;
    if (error case final failure?) throw failure;
    return _Request(status, body);
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Request(this.status, this.body) implements HttpClientRequest {
  final int status;
  final String body;

  @override
  final HttpHeaders headers = _Headers();

  @override
  void write(Object? object) {}

  @override
  Future<HttpClientResponse> close() async => _Response(status, body);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Headers implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Response(this.statusCode, this.body)
    extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  final int statusCode;
  final String body;

  @override
  bool get isRedirect => statusCode >= 300 && statusCode < 400;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(utf8.encode(body)).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
