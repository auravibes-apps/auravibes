// Required: Existing argument values intentionally repeat.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_app/services/url/models/url_request_method.dart';
import 'package:auravibes_app/services/url/models/url_response.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:dio/dio.dart';

class UrlService {
  UrlService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const int _maxResponseSize = 1024 * 1024;
  static const String _truncatedSuffix = '\n... [truncated]';

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
    final effectiveHeaders = _buildEffectiveHeaders(request);
    final rawBody = request.body;
    final requestBody =
        rawBody == null ||
            _hasHeader(request.headers, Headers.contentTypeHeader)
        ? rawBody
        : Stream<List<int>>.value(utf8.encode(rawBody));

    unawaited(
      _executeRequest(
        request,
        requestBody,
        effectiveHeaders,
        cancelToken,
        completer,
        stopwatch,
      ),
    );

    return completer.operation;
  }

  Future<void> _executeRequest(
    UrlRequest request,
    Object? requestBody,
    Map<String, String> effectiveHeaders,
    CancelToken cancelToken,
    CancelableCompleter<UrlResponse> completer,
    Stopwatch stopwatch,
  ) async {
    try {
      final response = await _dio.request<ResponseBody>(
        request.url,
        data: requestBody,
        cancelToken: cancelToken,
        options: Options(
          method: request.method.value,
          sendTimeout: request.timeout,
          receiveTimeout: request.timeout,
          headers: effectiveHeaders,
          responseType: ResponseType.stream,
        ),
      );
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
    } on Object catch (error, stackTrace) {
      await _handleRequestError(
        error,
        stackTrace,
        completer,
        stopwatch,
      );
    }
  }

  Future<void> _handleRequestError(
    Object error,
    StackTrace stackTrace,
    CancelableCompleter<UrlResponse> completer,
    Stopwatch stopwatch,
  ) async {
    if (completer.isCanceled) {
      return;
    }

    stopwatch.stop();

    if (error is! DioException) {
      completer.completeError(error, stackTrace);

      return;
    }

    if (error.type == DioExceptionType.cancel) {
      final _ = completer.operation.cancel();

      return;
    }

    final body = await _safeReadErrorResponseBody(
      error.response?.data,
      error.message,
    );
    if (completer.isCanceled) {
      return;
    }

    completer.complete(
      UrlResponse(
        statusCode: error.response?.statusCode ?? 0,
        body: body,
        headers: error.response?.headers.map ?? const {},
        elapsed: stopwatch.elapsed,
      ),
    );
  }

  Future<String> _safeReadErrorResponseBody(
    Object? data,
    String? message,
  ) async {
    try {
      return await _readErrorResponseBody(data, message);
    } on Object {
      return _truncateText(message ?? '');
    }
  }

  Future<String> _readErrorResponseBody(Object? data, String? message) async =>
      switch (data) {
        ResponseBody() => _readResponseBody(data),
        List<int>() => _decodeErrorBytes(data),
        _ => _truncateText(data?.toString() ?? message ?? ''),
      };

  String _decodeErrorBytes(List<int> data) {
    final bytes = data.length <= _maxResponseSize
        ? data
        : data.take(_maxResponseSize).toList(growable: false);
    final body = utf8.decode(bytes, allowMalformed: true);

    return data.length <= _maxResponseSize ? body : '$body$_truncatedSuffix';
  }

  Future<String> _readResponseBody(ResponseBody? responseBody) async {
    if (responseBody == null) {
      return '';
    }

    final buffer = StringBuffer();
    var receivedChars = 0;
    StreamSubscription<List<int>>? subscription;
    final completer = Completer<String>();

    Future<void> cancelSubscription() async {
      final currentSubscription = subscription;
      if (currentSubscription == null) return;
      await currentSubscription.cancel();
    }

    subscription = responseBody.stream.listen(
      (chunk) {
        if (completer.isCompleted) {
          return;
        }

        final remainingChars = _maxResponseSize - receivedChars;
        if (remainingChars <= 0) {
          buffer.write(_truncatedSuffix);
          completer.complete(buffer.toString());
          unawaited(cancelSubscription());

          return;
        }

        final decodedChunk = utf8.decode(chunk, allowMalformed: true);
        if (decodedChunk.length <= remainingChars) {
          buffer.write(decodedChunk);
          receivedChars += decodedChunk.length;

          return;
        }

        buffer
          ..write(decodedChunk.firstCharacters(remainingChars))
          ..write(_truncatedSuffix);
        receivedChars += remainingChars;
        completer.complete(buffer.toString());
        unawaited(cancelSubscription());
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

    return '${body.firstCharacters(_maxResponseSize)}$_truncatedSuffix';
  }

  Map<String, String> _buildEffectiveHeaders(UrlRequest request) {
    final headers = request.headers;

    return <String, String>{
      ...headers,
      if (!_hasHeader(headers, Headers.acceptHeader))
        Headers.acceptHeader: request.format.acceptHeader,
      if (!_hasHeader(headers, 'user-agent'))
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/143.0.0.0 Safari/537.36',
      if (!_hasHeader(headers, 'accept-language'))
        'Accept-Language': 'en-US,en;q=0.9',
    };
  }

  bool _hasHeader(Map<String, String> headers, String name) {
    return headers.keys.any((k) => k.toLowerCase() == name);
  }
}
