// Required: Existing argument values intentionally repeat.

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:dio/dio.dart';

class UrlService {
  static const int _maxResponseSize = 1024 * 1024;
  static const String _truncatedSuffix = '\n... [truncated]';
  UrlService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

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
          validateStatus: (_) => true,
          followRedirects: false,
        ),
      );
      if (completer.isCanceled) {
        return;
      }

      final body = await _readResponseBody(response.data);
      await _validateRedirect(request, response);
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
      await _handleRequestError(error, stackTrace, completer, stopwatch);
    }
  }

  Future<void> _validateRedirect(
    UrlRequest request,
    Response<ResponseBody> response,
  ) async {
    final statusCode = response.statusCode ?? 0;
    if (statusCode < 300 || statusCode >= 400) return;

    final location = response.headers.value('location');
    if (location == null) return;

    final destination = Uri.parse(request.url).resolve(location);
    if (request.headers.isNotEmpty) {
      final _ = await PublicUrlGuard.requireHttpsUri(destination.toString());
    } else {
      final uri = requirePublicUriSyntax(
        destination.toString(),
        requireHttps: false,
      );
      await PublicUrlGuard.ensureHost(uri.host);
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
        ResponseBody() => await _readResponseBody(data),
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

    final bytes = <int>[];
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

        final remainingBytes = _maxResponseSize - bytes.length;
        if (chunk.length <= remainingBytes) {
          bytes.addAll(chunk);

          return;
        }

        bytes.addAll(chunk.sublist(0, remainingBytes));
        completer.complete(
          '${_decodeResponseBytes(bytes, trimIncompleteSequence: true)}'
          '$_truncatedSuffix',
        );
        unawaited(cancelSubscription());
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(_decodeResponseBytes(bytes));
        }
      },
      cancelOnError: true,
    );

    return await completer.future;
  }

  String _decodeResponseBytes(
    List<int> bytes, {
    bool trimIncompleteSequence = false,
  }) {
    return const Utf8Decoder(allowMalformed: true).convert(
      bytes,
      0,
      trimIncompleteSequence ? _utf8PrefixLength(bytes) : null,
    );
  }

  int _utf8PrefixLength(List<int> bytes) {
    if (bytes.isEmpty) return 0;

    var continuationBytes = 0;
    for (
      var index = bytes.length - 1;
      index >= 0 && _isUtf8ContinuationByte(bytes[index]);
      index--
    ) {
      continuationBytes++;
    }
    if (continuationBytes == 0) {
      final sequenceLength = _utf8SequenceLength(bytes.last);

      return sequenceLength > 1 ? bytes.length - 1 : bytes.length;
    }

    final leadIndex = bytes.length - continuationBytes - 1;
    if (leadIndex < 0) return bytes.length;

    final sequenceLength = _utf8SequenceLength(bytes[leadIndex]);

    return sequenceLength == 0 || continuationBytes >= sequenceLength - 1
        ? bytes.length
        : leadIndex;
  }

  bool _isUtf8ContinuationByte(int byte) => byte >= 0x80 && byte <= 0xBF;

  int _utf8SequenceLength(int byte) => switch (byte) {
    <= 0x7F => 1,
    >= 0xC2 && <= 0xDF => 2,
    >= 0xE0 && <= 0xEF => 3,
    >= 0xF0 && <= 0xF4 => 4,
    _ => 0,
  };

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
