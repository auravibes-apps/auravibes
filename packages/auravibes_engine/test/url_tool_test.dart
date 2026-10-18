import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('parses only safe URL tool requests', () {
    final request = parseUrlToolInput(
      '{"url":"https://example.com","method":"HEAD","headers":{"X-Test":"1"}}',
    );
    expect(request.method, UrlRequestMethod.head);
    expect(request.headers, {'X-Test': '1'});
    expect(
      () => parseUrlToolInput('https://user:pass@example.com'),
      throwsFormatException,
    );
    expect(
      () => parseUrlToolInput(
        '{"url":"https://example.com","headers":{"Host":"x"}}',
      ),
      throwsFormatException,
    );
  });

  for (final name in [
    'Cookie',
    'sEt-CoOkIe',
    'AUTHORIZATION',
    'Proxy-Authorization',
    'WWW-Authenticate',
    'Proxy-Authenticate',
    'X-Api-Key',
    'api_key',
    'ApiKey',
    'X-Auth-Token',
    'auth_token',
    'X-Access-Token',
    'AccessToken',
    'X-Amz-Security-Token',
    'X-Goog-Api-Key',
    'X-Custom-Api-Key',
  ]) {
    test('omits secret response header $name', () {
      final output = formatUrlToolResponse(
        .new(
          statusCode: 429,
          body: 'Retry later.',
          headers: {
            name: ['sentinel-first', 'sentinel-second'],
            'Content-Type': ['text/plain'],
            'Retry-After': ['30'],
            'X-Request-Id': ['request-123'],
          },
          elapsed: const Duration(milliseconds: 12),
        ),
        requestedFormat: .text,
      );

      expect(output, isNot(contains('sentinel-')));
      expect(output, isNot(contains('$name:')));
      expect(output, contains('Status: 429'));
      expect(output, contains('Elapsed: 12ms'));
      expect(output, contains('Content-Type: text/plain'));
      expect(output, contains('Retry-After: 30'));
      expect(output, contains('X-Request-Id: request-123'));
      expect(output, contains('Retry later.'));
    });
  }

  test('redacts headers and preserves output budgets', () {
    final output = formatUrlToolResponse(
      .new(
        statusCode: 200,
        body: List.filled(3000, 'line').join('\n'),
        headers: const {
          'Set-Cookie': ['secret'],
          'X-Visible': ['yes'],
        },
        elapsed: Duration.zero,
      ),
      requestedFormat: .text,
    );
    expect(output, contains('X-Visible: yes'));
    expect(output, isNot(contains('secret')));
    expect(utf8.encode(output).length, lessThanOrEqualTo(50 * 1024));
    expect(
      const LineSplitter().convert(output).length,
      lessThanOrEqualTo(2000),
    );
  });
}
