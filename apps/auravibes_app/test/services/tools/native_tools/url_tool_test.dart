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

      final result = await tool.runner('  {"url":"https://example.com"}').value;

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
  });
}

final class _SuccessAdapter implements HttpClientAdapter {
  _SuccessAdapter({required this.body, required this.statusCode});

  final String body;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(body, statusCode);
  }

  @override
  void close({bool force = false}) {}
}
