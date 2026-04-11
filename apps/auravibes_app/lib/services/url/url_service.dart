import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_app/services/url/models/url_request.dart';
import 'package:auravibes_app/services/url/models/url_response.dart';
import 'package:dio/dio.dart';

class UrlService {
  UrlService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const int _maxResponseSize = 1024 * 1024;

  CancelableOperation<UrlResponse> execute(UrlRequest request) {
    final cancelToken = CancelToken();
    final completer = CancelableCompleter<UrlResponse>(
      onCancel: () {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('Request cancelled by user');
        }
      },
    );
    final stopwatch = Stopwatch()..start();

    _dio
        .request<ResponseBody>(
          request.url,
          data: request.body,
          cancelToken: cancelToken,
          options: Options(
            method: request.method.value,
            headers: request.headers,
            sendTimeout: request.timeout,
            receiveTimeout: request.timeout,
            responseType: ResponseType.stream,
          ),
        )
        .then((response) async {
          if (completer.isCanceled) {
            return;
          }

          final body = await _readResponseBody(response.data);
          stopwatch.stop();
          completer.complete(
            UrlResponse(
              statusCode: response.statusCode ?? 0,
              body: body,
              headers: response.headers.map,
              elapsed: stopwatch.elapsed,
            ),
          );
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (completer.isCanceled) {
            return;
          }

          stopwatch.stop();

          if (error is DioException && error.type == DioExceptionType.cancel) {
            completer.operation.cancel();
            return;
          }

          if (error is DioException) {
            completer.complete(
              UrlResponse(
                statusCode: error.response?.statusCode ?? 0,
                body: _truncateText(
                  error.response?.data?.toString() ?? error.message ?? '',
                ),
                headers: error.response?.headers.map ?? const {},
                elapsed: stopwatch.elapsed,
              ),
            );
            return;
          }

          completer.completeError(error, stackTrace);
        });

    return completer.operation;
  }

  Future<String> _readResponseBody(ResponseBody? responseBody) async {
    if (responseBody == null) {
      return '';
    }

    final buffer = StringBuffer();
    var receivedChars = 0;
    late final StreamSubscription<List<int>> subscription;
    final completer = Completer<String>();

    subscription = responseBody.stream.listen(
      (chunk) {
        if (completer.isCompleted) {
          return;
        }

        final remainingChars = _maxResponseSize - receivedChars;
        if (remainingChars <= 0) {
          buffer.write('\n... [truncated]');
          completer.complete(buffer.toString());
          unawaited(subscription.cancel());
          return;
        }

        final decodedChunk = utf8.decode(chunk, allowMalformed: true);
        if (decodedChunk.length <= remainingChars) {
          buffer.write(decodedChunk);
          receivedChars += decodedChunk.length;
          return;
        }

        buffer
          ..write(decodedChunk.substring(0, remainingChars))
          ..write('\n... [truncated]');
        receivedChars += remainingChars;
        completer.complete(buffer.toString());
        unawaited(subscription.cancel());
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(buffer.toString());
        }
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  String _truncateText(String body) {
    if (body.length <= _maxResponseSize) {
      return body;
    }

    return '${body.substring(0, _maxResponseSize)}\n... [truncated]';
  }
}
