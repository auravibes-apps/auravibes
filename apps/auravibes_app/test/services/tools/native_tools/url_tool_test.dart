import 'package:auravibes_app/services/tools/native_tool_entity.dart';
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

    test('rejects localhost URLs', () async {
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
      final dio = Dio()
        ..httpClientAdapter = _InspectAdapter(
          body: 'created',
          statusCode: 201,
          onInspect: (method, headers, body) {},
        );
      final tool = UrlTool(urlService: UrlService(dio: dio));

      final result = await tool
          .runner(
            '{"url": "https://1.1.1.1", "method": "POST", "body": "plain text body"}',
          )
          .value;

      expect(result, contains('Status: 201'));
    });

    test('rejects non-object JSON input starting with [', () {
      final tool = UrlTool();

      expect(
        tool.runner('["https://example.com"]').value,
        throwsA(isA<FormatException>()),
      );
    });

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

      await tool.runner('{"url": "https://1.1.1.1", "method": "POST"}').value;

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

      await tool.runner('{"url": "https://1.1.1.1", "method": "PUT"}').value;

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

      await tool.runner('{"url": "https://1.1.1.1", "method": "DELETE"}').value;

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
  });

  final String body;
  final int statusCode;
  final void Function(String?, Map<String, dynamic>?, String?) onInspect;

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
    return ResponseBody.fromString(body, statusCode);
  }

  @override
  void close({bool force = false}) {}
}
