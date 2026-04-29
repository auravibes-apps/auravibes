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

    test('handles DioException with response data', () async {
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          throw DioException(
            requestOptions: RequestOptions(path: options.path),
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 500,
              data: 'Server Error',
            ),
            type: DioExceptionType.badResponse,
          );
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final response = await service
          .execute(const UrlRequest(url: 'https://example.com'))
          .value;

      expect(response.statusCode, 500);
      expect(response.body, 'Server Error');
    });

    test('truncates large DioException response data', () async {
      final largeBody = 'x' * (1024 * 1024 + 100);
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          throw DioException(
            requestOptions: RequestOptions(path: options.path),
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 500,
              data: largeBody,
            ),
            type: DioExceptionType.badResponse,
          );
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final response = await service
          .execute(const UrlRequest(url: 'https://example.com'))
          .value;

      expect(response.body, contains('[truncated]'));
      expect(response.body.length, lessThan(largeBody.length));
    });

    test('handles DioException without response', () async {
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          throw DioException(
            requestOptions: RequestOptions(path: options.path),
            message: 'Connection refused',
            type: DioExceptionType.connectionError,
          );
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final response = await service
          .execute(const UrlRequest(url: 'https://example.com'))
          .value;

      expect(response.statusCode, 0);
      expect(response.body, contains('Connection refused'));
    });

    test('handles DioException without response', () async {
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          throw DioException(
            requestOptions: RequestOptions(),
            message: 'Connection refused',
            type: DioExceptionType.connectionError,
          );
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final response = await service
          .execute(const UrlRequest(url: 'https://example.com'))
          .value;

      expect(response.statusCode, 0);
      expect(response.body, contains('Connection refused'));
    });

    test('rethrows non-Dio exceptions as DioException', () async {
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          throw DioException(
            requestOptions: RequestOptions(path: options.path),
            error: StateError('unexpected'),
          );
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final response = await service
          .execute(const UrlRequest(url: 'https://example.com'))
          .value;

      expect(response.statusCode, 0);
    });

    test('cancels operation when Dio reports cancellation', () async {
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          throw DioException(
            requestOptions: RequestOptions(path: options.path),
            type: DioExceptionType.cancel,
          );
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final operation = service.execute(
        const UrlRequest(url: 'https://example.com'),
      );

      expect(await operation.valueOrCancellation(), isNull);
      expect(operation.isCanceled, isTrue);
    });

    test('streams string body when content-type is absent', () async {
      var streamedBody = '';
      final adapter = _FakeHttpClientAdapter(
        onFetch: (_, requestStream, _) async {
          final chunks = await requestStream!.toList();
          streamedBody = String.fromCharCodes(
            chunks.expand((chunk) => chunk),
          );

          return ResponseBody.fromString('ok', 200);
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      await service
          .execute(
            const UrlRequest(
              url: 'https://example.com',
              method: UrlRequestMethod.post,
              body: 'plain body',
            ),
          )
          .value;

      expect(streamedBody, 'plain body');
    });

    test('handles null response body', () async {
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          return ResponseBody(
            Stream<Uint8List>.value(Uint8List(0)),
            204,
            headers: {},
          );
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final response = await service
          .execute(const UrlRequest(url: 'https://example.com'))
          .value;

      expect(response.statusCode, 204);
      expect(response.body, '');
    });

    test('truncates large response body', () async {
      final largeBody = 'x' * (1024 * 1024 + 100);
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          return ResponseBody.fromString(largeBody, 200);
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final response = await service
          .execute(const UrlRequest(url: 'https://example.com'))
          .value;

      expect(response.body, contains('[truncated]'));
      expect(response.body.length, lessThanOrEqualTo(1024 * 1024 + 50));
    });

    test('includes elapsed duration in response', () async {
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          return ResponseBody.fromString('ok', 200);
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final response = await service
          .execute(const UrlRequest(url: 'https://example.com'))
          .value;

      expect(response.elapsed, greaterThanOrEqualTo(Duration.zero));
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
