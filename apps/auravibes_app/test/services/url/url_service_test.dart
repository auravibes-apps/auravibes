import 'dart:async';
import 'dart:typed_data';

import 'package:auravibes_app/services/url/models/url_request.dart';
import 'package:auravibes_app/services/url/url_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrlService', () {
    test('returns a successful response', () async {
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          return ResponseBody.fromString(
            'ok',
            200,
            headers: {
              Headers.contentTypeHeader: ['text/plain'],
            },
          );
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final response = await service
          .execute(
            const UrlRequest(url: 'https://example.com'),
          )
          .value;

      expect(response.statusCode, 200);
      expect(response.body, 'ok');
      expect(response.headers[Headers.contentTypeHeader], ['text/plain']);
    });

    test('cancels the underlying dio request', () async {
      final requestStarted = Completer<void>();
      CancelToken? observedCancelToken;
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          observedCancelToken = options.cancelToken;
          if (!requestStarted.isCompleted) {
            requestStarted.complete();
          }

          return Completer<ResponseBody>().future;
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final operation = service.execute(
        const UrlRequest(url: 'https://example.com/slow'),
      );

      await requestStarted.future.timeout(const Duration(seconds: 1));
      await operation.cancel();

      expect(operation.isCanceled, isTrue);
      expect(observedCancelToken, isNotNull);
      expect(observedCancelToken!.isCancelled, isTrue);
    });
  });
}

typedef _FetchCallback =
    Future<ResponseBody> Function(
      RequestOptions options,
      Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture,
    );

final class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter({required _FetchCallback onFetch})
    : _onFetch = onFetch;

  final _FetchCallback _onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _onFetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}
