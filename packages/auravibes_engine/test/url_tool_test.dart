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

  test('redacts headers and preserves output budgets', () {
    final output = formatUrlToolResponse(
      UrlResponse(
        statusCode: 200,
        body: List.filled(3000, 'line').join('\n'),
        headers: const {
          'Set-Cookie': ['secret'],
          'X-Visible': ['yes'],
        },
        elapsed: Duration.zero,
      ),
      requestedFormat: UrlResponseFormat.text,
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
