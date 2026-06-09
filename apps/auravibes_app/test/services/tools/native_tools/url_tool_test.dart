// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: no-empty-block
// Required: Tests use intentional no-op callbacks and fake hooks.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

import 'dart:convert';

import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tools/url_tool.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrlTool', () {
    test('accepts JSON input with leading whitespace', () async {
      final dio = Dio()
        ..httpClientAdapter = _SuccessAdapter(body: 'ok', statusCode: 200);
      final tool = UrlTool(urlService: UrlService(dio: dio));

      final result = await tool.runner('  {"url":"https://1.1.1.1"}').value;

      expect(result, contains('Status: 200'));
      expect(result, contains('ok'));
    });

    test('rejects localhost URLs', () {
      final tool = UrlTool();

      expect(
        tool.runner('http://localhost:8080').value,
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects non-string url value', () {
      final tool = UrlTool();

      expect(
        tool.runner('{"url": 123}').value,
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects non-string method value', () {
      final tool = UrlTool();

      expect(
        tool.runner('{"url": "https://example.com", "method": 456}').value,
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects Host header in input', () {
      final tool = UrlTool();

      expect(
        tool
            .runner(
              '{"url": "https://example.com", "headers": {"Host": "attacker.tld"}}',
            )
            .value,
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects malformed JSON-object input starting with {', () {
      final tool = UrlTool();

      expect(
        tool.runner('{bad}').value,
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects bare opening brace', () {
      final tool = UrlTool();

      expect(
        tool.runner('{').value,
        throwsA(isA<FormatException>()),
      );
    });

    test('getTool returns spec with url name', () {
      final tool = UrlTool();
      final spec = tool.getTool();

      expect(spec.name, 'url');
      expect(spec.description, isNotEmpty);
      expect(spec.inputJsonSchema, isNotNull);
    });

    test('accepts plain URL string input', () async {
      final dio = Dio()
        ..httpClientAdapter = _SuccessAdapter(body: 'page', statusCode: 200);
      final tool = UrlTool(urlService: UrlService(dio: dio));

      final result = await tool.runner('https://1.1.1.1').value;

      expect(result, contains('Status: 200'));
      expect(result, contains('page'));
    });

    test('rejects empty URL', () {
      final tool = UrlTool();

      expect(
        tool.runner('{"url": "  "}').value,
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects URL without scheme', () {
      final tool = UrlTool();

      expect(
        tool.runner('{"url": "example.com"}').value,
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects ftp scheme', () {
      final tool = UrlTool();

      expect(
        tool.runner('{"url": "ftp://example.com"}').value,
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects URL with user info', () {
      final tool = UrlTool();

      expect(
        tool.runner('{"url": "https://user:pass@example.com"}').value,
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unsupported HTTP method', () {
      final tool = UrlTool();

      expect(
        tool
            .runner(
              '{"url": "https://example.com", "method": "CONNECT"}',
            )
            .value,
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects headers that are not a map', () {
      final tool = UrlTool();

      expect(
        tool
            .runner(
              '{"url": "https://example.com", "headers": "bad"}',
            )
            .value,
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects JSON array input starting with [', () {
      final tool = UrlTool();

      expect(
        tool.runner('["url"]').value,
        throwsA(isA<FormatException>()),
      );
    });

    test('POST with structured body auto-adds content-type', () async {
      String? sentMethod;
      Map<String, dynamic>? sentHeaders;
      final dio = Dio()
        ..httpClientAdapter = _InspectAdapter(
          body: 'created',
          statusCode: 201,
          onInspect: (method, headers, body) {
            sentMethod = method;
            sentHeaders = headers;
          },
        );
      final tool = UrlTool(urlService: UrlService(dio: dio));

      final result = await tool
          .runner(
            '{"url": "https://1.1.1.1", "method": "POST", "body": {"key": "val"}}',
          )
          .value;

      expect(result, contains('Status: 201'));
      expect(sentMethod, 'POST');
      expect(
        sentHeaders?.keys.any((k) => k.toLowerCase() == 'content-type'),
        isTrue,
      );
    });

    test('formats response with headers', () async {
      final dio = Dio()
        ..httpClientAdapter = _SuccessAdapter(
          body: 'ok',
          statusCode: 200,
          extraHeaders: {
            'content-type': ['text/plain'],
            'x-custom': ['value'],
          },
        );
      final tool = UrlTool(urlService: UrlService(dio: dio));

      final result = await tool.runner('{"url": "https://1.1.1.1"}').value;

      expect(result, contains('Status: 200'));
      expect(result, contains('content-type: text/plain'));
      expect(result, contains('x-custom: value'));
      expect(result, contains('Elapsed:'));
      expect(result, contains('ok'));
    });

    test('type getter returns url', () {
      final tool = UrlTool();
      expect(tool.type, NativeToolType.url);
    });

    test(
      'POST with string body does not auto-add content-type header',
      () async {
        Map<String, dynamic>? sentHeaders;
        final dio = Dio()
          ..httpClientAdapter = _InspectAdapter(
            body: 'created',
            statusCode: 201,
            onInspect: (method, headers, body) {
              sentHeaders = headers;
            },
          );
        final tool = UrlTool(urlService: UrlService(dio: dio));

        final result = await tool
            .runner(
              '{"url": "https://1.1.1.1", '
              '"method": "POST", '
              '"body": "plain text body"}',
            )
            .value;

        expect(result, contains('Status: 201'));
        expect(
          (sentHeaders ?? fail('Expected sentHeaders to be non-null')).keys.map(
            (key) => key.toLowerCase(),
          ),
          isNot(contains('content-type')),
        );
      },
    );

    test('handles POST method correctly', () async {
      String? sentMethod;
      final dio = Dio()
        ..httpClientAdapter = _InspectAdapter(
          body: 'ok',
          statusCode: 200,
          onInspect: (method, headers, body) {
            sentMethod = method;
          },
        );
      final tool = UrlTool(urlService: UrlService(dio: dio));

      final _ = await tool
          .runner('{"url": "https://1.1.1.1", "method": "POST"}')
          .value;

      expect(sentMethod, 'POST');
    });

    test('handles PUT method correctly', () async {
      String? sentMethod;
      final dio = Dio()
        ..httpClientAdapter = _InspectAdapter(
          body: 'ok',
          statusCode: 200,
          onInspect: (method, headers, body) {
            sentMethod = method;
          },
        );
      final tool = UrlTool(urlService: UrlService(dio: dio));

      final _ = await tool
          .runner('{"url": "https://1.1.1.1", "method": "PUT"}')
          .value;

      expect(sentMethod, 'PUT');
    });

    test('handles DELETE method correctly', () async {
      String? sentMethod;
      final dio = Dio()
        ..httpClientAdapter = _InspectAdapter(
          body: 'ok',
          statusCode: 200,
          onInspect: (method, headers, body) {
            sentMethod = method;
          },
        );
      final tool = UrlTool(urlService: UrlService(dio: dio));

      final _ = await tool
          .runner('{"url": "https://1.1.1.1", "method": "DELETE"}')
          .value;

      expect(sentMethod, 'DELETE');
    });

    test('rejects .localhost subdomain', () {
      final tool = UrlTool();

      expect(
        tool.runner('http://app.localhost:3000').value,
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects headers with uppercase Host', () {
      final tool = UrlTool();

      expect(
        tool
            .runner(
              '{"url": "https://example.com", "headers": {"HOST": "evil.com"}}',
            )
            .value,
        throwsA(isA<FormatException>()),
      );
    });

    test('accepts valid headers', () async {
      final dio = Dio()
        ..httpClientAdapter = _SuccessAdapter(body: 'ok', statusCode: 200);
      final tool = UrlTool(urlService: UrlService(dio: dio));

      final result = await tool
          .runner(
            '{"url": "https://1.1.1.1", "headers": {"X-Custom": "value"}}',
          )
          .value;

      expect(result, contains('Status: 200'));
    });

    test('transforms HTML response to markdown with format header', () async {
      final dio = Dio()
        ..httpClientAdapter = _SuccessAdapter(
          body: '<html><body><h1>Hello</h1><p>World</p></body></html>',
          statusCode: 200,
          extraHeaders: {
            'content-type': ['text/html'],
          },
        );
      final tool = UrlTool(urlService: UrlService(dio: dio));

      final result = await tool.runner('https://1.1.1.1').value;

      expect(result, contains('Format: markdown'));
      expect(result, contains('Content-Type: text/html'));
      expect(result, contains('# Hello'));
      expect(result, contains('World'));
    });

    test('transforms JSON response with json format header', () async {
      final dio = Dio()
        ..httpClientAdapter = _SuccessAdapter(
          body: '{"key": "value"}',
          statusCode: 200,
          extraHeaders: {
            'content-type': ['application/json'],
          },
        );
      final tool = UrlTool(urlService: UrlService(dio: dio));

      final result = await tool.runner('https://1.1.1.1').value;

      expect(result, contains('Format: json'));
      expect(result, contains('Content-Type: application/json'));
      expect(result, contains('{"key": "value"}'));
    });

    test('transforms plain text with text format header', () async {
      final dio = Dio()
        ..httpClientAdapter = _SuccessAdapter(
          body: 'Hello world',
          statusCode: 200,
          extraHeaders: {
            'content-type': ['text/plain'],
          },
        );
      final tool = UrlTool(urlService: UrlService(dio: dio));

      final result = await tool.runner('https://1.1.1.1').value;

      expect(result, contains('Format: text'));
      expect(result, contains('Content-Type: text/plain'));
      expect(result, contains('Hello world'));
    });

    test('handles unknown content type with unsupported format', () async {
      final dio = Dio()
        ..httpClientAdapter = _SuccessAdapter(
          body: 'data',
          statusCode: 200,
        );
      final tool = UrlTool(urlService: UrlService(dio: dio));

      final result = await tool.runner('https://1.1.1.1').value;

      expect(result, contains('Format: unsupported'));
      expect(result, contains('Content-Type: unknown'));
    });

    group('format parameter', () {
      test('accepts format: markdown', () async {
        String? sentAccept;
        final dio = Dio()
          ..httpClientAdapter = _InspectAdapter(
            body: '<html><body><h1>Hi</h1></body></html>',
            statusCode: 200,
            onInspect: (method, headers, body) {
              sentAccept = headers?['accept'] as String?;
            },
            extraHeaders: {
              'content-type': ['text/html'],
            },
          );
        final tool = UrlTool(urlService: UrlService(dio: dio));

        final result = await tool
            .runner(
              '{"url": "https://1.1.1.1", "format": "markdown"}',
            )
            .value;

        expect(result, contains('Format: markdown'));
        expect(result, contains('# Hi'));
        expect(sentAccept, isNotNull);
        expect(sentAccept, contains('text/html'));
        expect(sentAccept, contains('text/markdown'));
      });

      test('accepts format: text', () async {
        final dio = Dio()
          ..httpClientAdapter = _SuccessAdapter(
            body: '<html><body><h1>Title</h1><p>Content</p></body></html>',
            statusCode: 200,
            extraHeaders: {
              'content-type': ['text/html'],
            },
          );
        final tool = UrlTool(urlService: UrlService(dio: dio));

        final result = await tool
            .runner(
              '{"url": "https://1.1.1.1", "format": "text"}',
            )
            .value;

        expect(result, contains('Format: text'));
        expect(result, contains('Title'));
        expect(result, contains('Content'));
        expect(result, isNot(contains('#')));
      });

      test('accepts format: html', () async {
        final dio = Dio()
          ..httpClientAdapter = _SuccessAdapter(
            body: '<html><body><h1>Raw</h1></body></html>',
            statusCode: 200,
            extraHeaders: {
              'content-type': ['text/html'],
            },
          );
        final tool = UrlTool(urlService: UrlService(dio: dio));

        final result = await tool
            .runner(
              '{"url": "https://1.1.1.1", "format": "html"}',
            )
            .value;

        expect(result, contains('Format: html'));
        expect(result, contains('<h1>Raw</h1>'));
      });

      test('omitted format defaults to markdown', () async {
        final dio = Dio()
          ..httpClientAdapter = _SuccessAdapter(
            body: '<html><body><h1>Hello</h1></body></html>',
            statusCode: 200,
            extraHeaders: {
              'content-type': ['text/html'],
            },
          );
        final tool = UrlTool(urlService: UrlService(dio: dio));

        final result = await tool.runner('https://1.1.1.1').value;

        expect(result, contains('Format: markdown'));
        expect(result, contains('# Hello'));
      });

      test('rejects invalid format string', () {
        final tool = UrlTool();

        expect(
          tool
              .runner(
                '{"url": "https://example.com", "format": "unknown"}',
              )
              .value,
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects non-string format value', () {
        final tool = UrlTool();

        expect(
          tool
              .runner(
                '{"url": "https://example.com", "format": 123}',
              )
              .value,
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('output truncation', () {
      test('truncates large response body and preserves metadata', () async {
        final largeContent = List.generate(
          3000,
          (i) => 'Line $i: ${'x' * 60}',
        ).join('\n');
        final dio = Dio()
          ..httpClientAdapter = _SuccessAdapter(
            body: largeContent,
            statusCode: 200,
          );
        final tool = UrlTool(urlService: UrlService(dio: dio));

        final result = await tool.runner('{"url": "https://1.1.1.1"}').value;

        expect(result, contains('Status: 200'));
        expect(result, contains('Content-Type:'));
        expect(result, contains('Format:'));
        expect(result, contains('Headers:'));
        expect(result, contains('[truncated:'));
        expect(result, contains('bytes omitted'));
        expect(result, contains('Line 0:'));
        expect(result, isNot(contains('Line 2999:')));

        final resultBytes = utf8.encode(result).length;
        expect(resultBytes, lessThanOrEqualTo(50 * 1024));
      });

      test('marks format as truncated', () async {
        final largeContent = List.generate(
          3000,
          (i) => 'Line $i: ${'x' * 60}',
        ).join('\n');
        final dio = Dio()
          ..httpClientAdapter = _SuccessAdapter(
            body: largeContent,
            statusCode: 200,
          );
        final tool = UrlTool(urlService: UrlService(dio: dio));

        final result = await tool.runner('{"url": "https://1.1.1.1"}').value;

        expect(result, contains('Format:'));
        expect(result, contains('(truncated)'));
      });

      test('does not truncate small response body', () async {
        final dio = Dio()
          ..httpClientAdapter = _SuccessAdapter(
            body: 'Hello world',
            statusCode: 200,
          );
        final tool = UrlTool(urlService: UrlService(dio: dio));

        final result = await tool.runner('{"url": "https://1.1.1.1"}').value;

        expect(result, contains('Hello world'));
        expect(result, isNot(contains('[truncated:')));
        expect(result, isNot(contains('(truncated)')));
      });

      test('truncates response exceeding line limit', () async {
        final manyLines = List.generate(2500, (i) => 'Line $i').join('\n');
        final dio = Dio()
          ..httpClientAdapter = _SuccessAdapter(
            body: manyLines,
            statusCode: 200,
          );
        final tool = UrlTool(urlService: UrlService(dio: dio));

        final result = await tool.runner('{"url": "https://1.1.1.1"}').value;

        expect(result, contains('[truncated:'));
        expect(result, contains('Line 0'));
        expect(result, isNot(contains('Line 2499')));
      });

      test('truncates total output when metadata exceeds cap', () async {
        final largeHeaders = <String, List<String>>{
          for (var i = 0; i < 2500; i++) 'x-header-$i': [('y' * 60)],
        };
        final dio = Dio()
          ..httpClientAdapter = _SuccessAdapter(
            body: 'small body',
            statusCode: 200,
            extraHeaders: largeHeaders,
          );
        final tool = UrlTool(urlService: UrlService(dio: dio));

        final result = await tool.runner('{"url": "https://1.1.1.1"}').value;

        expect(result, contains('[truncated:'));
        expect(result, contains('(truncated)'));

        final resultBytes = utf8.encode(result).length;
        expect(resultBytes, lessThanOrEqualTo(50 * 1024));

        final lineCount = const LineSplitter().convert(result).length;
        expect(lineCount, lessThanOrEqualTo(2000));
      });
    });
  });
}

final class _SuccessAdapter implements HttpClientAdapter {
  _SuccessAdapter({
    required this.body,
    required this.statusCode,
    this.extraHeaders,
  });

  final String body;
  final int statusCode;
  final Map<String, List<String>>? extraHeaders;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: extraHeaders ?? const {},
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _InspectAdapter implements HttpClientAdapter {
  _InspectAdapter({
    required this.body,
    required this.statusCode,
    required this.onInspect,
    this.extraHeaders,
  });

  final String body;
  final int statusCode;
  final void Function(String?, Map<String, dynamic>?, String?) onInspect;
  final Map<String, List<String>>? extraHeaders;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    String? requestBody;
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>(
        [],
        (acc, chunk) => acc..addAll(chunk),
      );
      requestBody = String.fromCharCodes(bytes);
    }
    onInspect(options.method, options.headers, requestBody);

    return ResponseBody.fromString(
      body,
      statusCode,
      headers: extraHeaders ?? const {},
    );
  }

  @override
  void close({bool force = false}) {}
}
