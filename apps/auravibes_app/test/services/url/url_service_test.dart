// ignore_for_file: avoid-non-null-assertion
// Required: Tests inspect nullable values after arranging expected state.

import 'dart:async';
import 'dart:typed_data';

import 'package:auravibes_app/services/url/models/url_request_method.dart';
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
      final _ = await operation.cancel();

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
              data: 'Server Error',
              requestOptions: RequestOptions(),
              statusCode: 500,
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

    test('reads streamed DioException response data', () async {
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          throw DioException(
            requestOptions: RequestOptions(path: options.path),
            response: Response(
              data: ResponseBody.fromString('Not Found', 404),
              requestOptions: RequestOptions(),
              statusCode: 404,
            ),
            type: DioExceptionType.badResponse,
          );
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final response = await service
          .execute(const UrlRequest(url: 'https://example.com/missing'))
          .value;

      expect(response.statusCode, 404);
      expect(response.body, 'Not Found');
      expect(response.body, isNot(contains('ResponseBody')));
    });

    test('decodes byte list DioException response data', () async {
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          throw DioException(
            requestOptions: RequestOptions(path: options.path),
            response: Response(
              data: 'Bad Request'.codeUnits,
              requestOptions: RequestOptions(),
              statusCode: 400,
            ),
            type: DioExceptionType.badResponse,
          );
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final response = await service
          .execute(const UrlRequest(url: 'https://example.com/bad'))
          .value;

      expect(response.statusCode, 400);
      expect(response.body, 'Bad Request');
    });

    test('truncates byte list DioException response data', () async {
      final data = Uint8List(1024 * 1024 + 100)
        ..fillRange(0, 1024 * 1024 + 100, 120);
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          throw DioException(
            requestOptions: RequestOptions(path: options.path),
            response: Response(
              data: data,
              requestOptions: RequestOptions(),
              statusCode: 500,
            ),
            type: DioExceptionType.badResponse,
          );
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final response = await service
          .execute(const UrlRequest(url: 'https://example.com/large'))
          .value;

      expect(response.body, contains('[truncated]'));
      expect(response.body.length, lessThan(data.length));
    });

    test(
      'falls back to DioException message when error stream fails',
      () async {
        final adapter = _FakeHttpClientAdapter(
          onFetch: (options, _, _) async {
            throw DioException(
              requestOptions: RequestOptions(path: options.path),
              response: Response(
                data: ResponseBody(
                  Stream<Uint8List>.error(StateError('stream failed')),
                  502,
                ),
                requestOptions: RequestOptions(),
                statusCode: 502,
              ),
              type: DioExceptionType.badResponse,
              message: 'Bad gateway',
            );
          },
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final service = UrlService(dio: dio);

        final response = await service
            .execute(const UrlRequest(url: 'https://example.com/bad-gateway'))
            .value;

        expect(response.statusCode, 502);
        expect(response.body, 'Bad gateway');
      },
    );

    test('truncates large DioException response data', () async {
      final largeBody = 'x' * (1024 * 1024 + 100);
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          throw DioException(
            requestOptions: RequestOptions(path: options.path),
            response: Response(
              data: largeBody,
              requestOptions: RequestOptions(),
              statusCode: 500,
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

    test(
      'handles DioException without response and with request path',
      () async {
        final adapter = _FakeHttpClientAdapter(
          onFetch: (options, _, _) async {
            throw DioException(
              requestOptions: RequestOptions(path: options.path),
              type: DioExceptionType.connectionError,
              message: 'Connection refused',
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
      },
    );

    test('handles DioException without response or request path', () async {
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          throw DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionError,
            message: 'Connection refused',
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

    test('handles adapter errors wrapped by Dio', () async {
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          throw StateError('unexpected');
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
        onFetch: (options, requestStream, _) async {
          expect(
            options.headers.keys.map((key) => key.toLowerCase()),
            isNot(contains(Headers.contentTypeHeader)),
          );

          final chunks = await requestStream!.toList();
          streamedBody = String.fromCharCodes(
            chunks.expand((chunk) => chunk),
          );

          return ResponseBody.fromString('ok', 200);
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final _ = await service
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

    test('truncates response body after exact limit chunk', () async {
      final adapter = _FakeHttpClientAdapter(
        onFetch: (options, _, _) async {
          return ResponseBody(
            Stream<Uint8List>.fromIterable([
              Uint8List(1024 * 1024)..fillRange(0, 1024 * 1024, 120),
              Uint8List.fromList('overflow'.codeUnits),
            ]),
            200,
          );
        },
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UrlService(dio: dio);

      final response = await service
          .execute(const UrlRequest(url: 'https://example.com'))
          .value;

      expect(response.body, contains('[truncated]'));
      expect(response.body, isNot(contains('overflow')));
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

    group('Accept header', () {
      test('adds Accept header based on format', () async {
        String? acceptHeader;
        final adapter = _FakeHttpClientAdapter(
          onFetch: (options, _, _) async {
            acceptHeader = options.headers['accept'] as String?;
            return ResponseBody.fromString('ok', 200);
          },
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final service = UrlService(dio: dio);

        final _ = await service
            .execute(
              const UrlRequest(
                url: 'https://example.com',
                format: UrlResponseFormat.markdown,
              ),
            )
            .value;

        expect(acceptHeader, isNotNull);
        expect(acceptHeader, contains('text/html'));
        expect(acceptHeader, contains('text/markdown'));
      });

      test('uses html Accept header for html format', () async {
        String? acceptHeader;
        final adapter = _FakeHttpClientAdapter(
          onFetch: (options, _, _) async {
            acceptHeader = options.headers['accept'] as String?;
            return ResponseBody.fromString('ok', 200);
          },
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final service = UrlService(dio: dio);

        final _ = await service
            .execute(
              const UrlRequest(
                url: 'https://example.com',
                format: UrlResponseFormat.html,
              ),
            )
            .value;

        expect(acceptHeader, isNotNull);
        expect(acceptHeader, contains('text/html'));
        expect(acceptHeader, contains('application/xhtml+xml'));
      });

      test('preserves user-provided Accept header', () async {
        String? acceptHeader;
        final adapter = _FakeHttpClientAdapter(
          onFetch: (options, _, _) async {
            acceptHeader = options.headers['accept'] as String?;
            return ResponseBody.fromString('ok', 200);
          },
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final service = UrlService(dio: dio);

        final _ = await service
            .execute(
              const UrlRequest(
                url: 'https://example.com',
                headers: {'Accept': 'application/json'},
              ),
            )
            .value;

        expect(acceptHeader, 'application/json');
      });

      test('adds default User-Agent header', () async {
        String? userAgent;
        final adapter = _FakeHttpClientAdapter(
          onFetch: (options, _, _) async {
            userAgent = options.headers['user-agent'] as String?;
            return ResponseBody.fromString('ok', 200);
          },
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final service = UrlService(dio: dio);

        final _ = await service
            .execute(
              const UrlRequest(url: 'https://example.com'),
            )
            .value;

        expect(userAgent, contains('Mozilla/5.0'));
        expect(userAgent, contains('Chrome/'));
      });

      test('preserves user-provided User-Agent header', () async {
        String? userAgent;
        final adapter = _FakeHttpClientAdapter(
          onFetch: (options, _, _) async {
            userAgent = options.headers['user-agent'] as String?;
            return ResponseBody.fromString('ok', 200);
          },
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final service = UrlService(dio: dio);

        final _ = await service
            .execute(
              const UrlRequest(
                url: 'https://example.com',
                headers: {'User-Agent': 'MyBot/1.0'},
              ),
            )
            .value;

        expect(userAgent, 'MyBot/1.0');
      });

      test('adds default Accept-Language header', () async {
        String? acceptLanguage;
        final adapter = _FakeHttpClientAdapter(
          onFetch: (options, _, _) async {
            acceptLanguage = options.headers['accept-language'] as String?;
            return ResponseBody.fromString('ok', 200);
          },
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final service = UrlService(dio: dio);

        final _ = await service
            .execute(
              const UrlRequest(url: 'https://example.com'),
            )
            .value;

        expect(acceptLanguage, 'en-US,en;q=0.9');
      });

      test('preserves user-provided Accept-Language header', () async {
        String? acceptLanguage;
        final adapter = _FakeHttpClientAdapter(
          onFetch: (options, _, _) async {
            acceptLanguage = options.headers['accept-language'] as String?;
            return ResponseBody.fromString('ok', 200);
          },
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final service = UrlService(dio: dio);

        final _ = await service
            .execute(
              const UrlRequest(
                url: 'https://example.com',
                headers: {'Accept-Language': 'es-ES'},
              ),
            )
            .value;

        expect(acceptLanguage, 'es-ES');
      });
    });
  });
}

final class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter({required this._onFetch});

  final Future<ResponseBody> Function(
    RequestOptions,
    Stream<Uint8List>?,
    Future<void>?,
  )
  _onFetch;

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
