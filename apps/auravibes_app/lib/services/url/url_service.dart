// Required: Existing argument values intentionally repeat.

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:auravibes_app/services/url/pinned_http_client_adapter.dart';
import 'package:auravibes_app/services/url/public_url_guard.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:dio/dio.dart';

typedef _RequestSetup = ({
  Dio? dio,
  Object? requestBody,
  Map<String, String> effectiveHeaders,
  CancelToken cancelToken,
  CancelableCompleter<UrlResponse> completer,
  Stopwatch stopwatch,
});

typedef _RequestExecution = ({
  Dio dio,
  UrlRequest request,
  Object? requestBody,
  Map<String, String> effectiveHeaders,
  CancelToken cancelToken,
  CancelableCompleter<UrlResponse> completer,
  Stopwatch stopwatch,
});

typedef _RequestError = ({
  Object error,
  StackTrace stackTrace,
  CancelableCompleter<UrlResponse> completer,
  Stopwatch stopwatch,
});

typedef _RequestFailure = ({Object error, StackTrace stackTrace});

class UrlService({Dio? dio}) {
  final Dio _dio = dio ?? Dio();
  final _UrlResponseBodyReader _bodyReader = _UrlResponseBodyReader();

  // Null means use the existing Dio adapter.
  // ignore: unnecessary-nullable
  CancelableOperation<UrlResponse> execute(
    UrlRequest request, {
    List<String>? resolvedAddresses,
  }) {
    final setup = _createRequestSetup(request, resolvedAddresses);
    final execution = _createExecution(request, setup);
    if (execution == null) {
      _completeUnsupportedRequest(setup.completer);

      return setup.completer.operation;
    }

    unawaited(_executeRequest(execution));

    return setup.completer.operation;
  }

  _RequestSetup _createRequestSetup(
    UrlRequest request,
    List<String>? resolvedAddresses,
  ) {
    final cancelToken = CancelToken();
    final completer = _createCompleter(cancelToken);

    return (
      dio: _dioForAddresses(resolvedAddresses),
      requestBody: _requestBody(request),
      effectiveHeaders: _buildEffectiveHeaders(request),
      cancelToken: cancelToken,
      completer: completer,
      stopwatch: Stopwatch()..start(),
    );
  }

  Dio? _dioForAddresses(List<String>? addresses) {
    if (addresses == null) return _dio;

    final adapter = PinnedHttpClientAdapter.create(
      _dio.httpClientAdapter,
      addresses,
    );
    if (adapter == null) return null;

    return _dio.clone(httpClientAdapter: adapter);
  }

  Future<void> _executeRequest(_RequestExecution execution) async {
    try {
      await _runRequest(execution, _bodyReader);
    } on Object catch (error, stackTrace) {
      await _handleRequestFailure(_bodyReader, execution, (
        error: error,
        stackTrace: stackTrace,
      ));
    } finally {
      _closeRequestClient(execution.dio, _dio);
    }
  }
}

Future<void> _handleRequestFailure(
  _UrlResponseBodyReader bodyReader,
  _RequestExecution execution,
  _RequestFailure failure,
) => _handleRequestError(bodyReader, (
  error: failure.error,
  stackTrace: failure.stackTrace,
  completer: execution.completer,
  stopwatch: execution.stopwatch,
));

void _closeRequestClient(Dio requestDio, Dio defaultDio) {
  if (!identical(requestDio, defaultDio)) requestDio.close(force: true);
}

_RequestExecution? _createExecution(UrlRequest request, _RequestSetup setup) {
  final dio = setup.dio;
  if (dio == null) return null;

  return (
    dio: dio,
    request: request,
    requestBody: setup.requestBody,
    effectiveHeaders: setup.effectiveHeaders,
    cancelToken: setup.cancelToken,
    completer: setup.completer,
    stopwatch: setup.stopwatch,
  );
}

void _completeUnsupportedRequest(CancelableCompleter<UrlResponse> completer) {
  completer.completeError(
    UnsupportedError('HTTP adapter does not support address pinning'),
    StackTrace.current,
  );
}

Future<void> _runRequest(
  _RequestExecution execution,
  _UrlResponseBodyReader bodyReader,
) async {
  final response = await _sendRequest(execution);
  if (execution.completer.isCanceled) return;

  await _completeResponse(execution, bodyReader, response);
}

Future<Response<ResponseBody>> _sendRequest(_RequestExecution execution) {
  return execution.dio.request<ResponseBody>(
    execution.request.url,
    data: execution.requestBody,
    cancelToken: execution.cancelToken,
    options: _requestOptions(execution.request, execution.effectiveHeaders),
  );
}

Options _requestOptions(
  UrlRequest request,
  Map<String, String> effectiveHeaders,
) => .new(
  method: request.method.value,
  sendTimeout: request.timeout,
  receiveTimeout: request.timeout,
  headers: effectiveHeaders,
  responseType: ResponseType.stream,
  validateStatus: (_) => true,
  followRedirects: false,
);

Future<void> _completeResponse(
  _RequestExecution execution,
  _UrlResponseBodyReader bodyReader,
  Response<ResponseBody> response,
) async {
  final body = await bodyReader.read(response.data);
  await _validateRedirect(execution.request, response);
  final stopwatch = execution.stopwatch..stop();
  execution.completer.complete(_urlResponse(response, body, stopwatch));
}

UrlResponse _urlResponse(
  Response<ResponseBody> response,
  String body,
  Stopwatch stopwatch,
) => UrlResponse(
  statusCode: response.statusCode ?? 0,
  body: body,
  headers: response.headers.map,
  elapsed: stopwatch.elapsed,
);

Future<void> _validateRedirect(
  UrlRequest request,
  Response<ResponseBody> response,
) async {
  final location = _redirectLocation(response);
  if (location == null) return;

  final destination = Uri.parse(request.url).resolve(location);
  await _validateRedirectDestination(request, destination);
}

String? _redirectLocation(Response<ResponseBody> response) {
  final statusCode = response.statusCode ?? 0;
  if (statusCode < 300 || statusCode >= 400) return null;

  return response.headers.value('location');
}

Future<void> _validateRedirectDestination(
  UrlRequest request,
  Uri destination,
) => request.headers.isNotEmpty
    ? _validateHttpsRedirect(destination)
    : _validatePublicRedirect(destination);

Future<void> _validateHttpsRedirect(Uri destination) async {
  final _ = await PublicUrlGuard.requireHttpsUri(destination.toString());
}

Future<void> _validatePublicRedirect(Uri destination) async {
  final uri = requirePublicUriSyntax(
    destination.toString(),
    requireHttps: false,
  );

  await PublicUrlGuard.ensureHost(uri.host);
}

Future<void> _handleRequestError(
  _UrlResponseBodyReader bodyReader,
  _RequestError requestError,
) async {
  final (:error, :stackTrace, :completer, :stopwatch) = requestError;
  if (completer.isCanceled) return;

  stopwatch.stop();
  if (error is! DioException) {
    completer.completeError(error, stackTrace);
    return;
  }
  await _handleDioError(bodyReader, error, requestError);
}

Future<void> _handleDioError(
  _UrlResponseBodyReader bodyReader,
  DioException error,
  _RequestError requestError,
) async {
  if (error.type == DioExceptionType.cancel) {
    final _ = requestError.completer.operation.cancel();
    return;
  }

  await _completeErrorResponse(bodyReader, error, requestError);
}

Future<void> _completeErrorResponse(
  _UrlResponseBodyReader bodyReader,
  DioException error,
  _RequestError requestError,
) async {
  final body = await bodyReader.readError(error.response?.data, error.message);
  if (requestError.completer.isCanceled) return;

  requestError.completer.complete(_dioErrorResponse(error, body, requestError));
}

UrlResponse _dioErrorResponse(
  DioException error,
  String body,
  _RequestError requestError,
) => UrlResponse(
  statusCode: error.response?.statusCode ?? 0,
  body: body,
  headers: error.response?.headers.map ?? const {},
  elapsed: requestError.stopwatch.elapsed,
);

CancelableCompleter<UrlResponse> _createCompleter(CancelToken cancelToken) {
  return CancelableCompleter<UrlResponse>(
    onCancel: () => _cancelToken(cancelToken),
  );
}

void _cancelToken(CancelToken cancelToken) {
  if (!cancelToken.isCancelled) {
    cancelToken.cancel('Request cancelled by user');
  }
}

Object? _requestBody(UrlRequest request) {
  final rawBody = request.body;
  if (rawBody == null ||
      _hasHeader(request.headers, Headers.contentTypeHeader)) {
    return rawBody;
  }

  return Stream<List<int>>.value(utf8.encode(rawBody));
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

const int _maxResponseSize = 1024 * 1024;
const String _truncatedSuffix = '\n... [truncated]';

class _UrlResponseBodyReader {
  Future<String> read(ResponseBody? responseBody) {
    if (responseBody == null) return Future.value('');

    return _BodyStreamReader(responseBody).read();
  }

  Future<String> readError(Object? data, String? message) async {
    try {
      return await _readError(data, message);
    } on Object {
      return _truncateText(message ?? '');
    }
  }

  Future<String> _readError(Object? data, String? message) async =>
      switch (data) {
        ResponseBody() => await read(data),
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
}

class _BodyStreamReader {
  _BodyStreamReader(this._responseBody);

  final ResponseBody _responseBody;
  final _bytes = <int>[];
  final _completer = Completer<String>();
  StreamSubscription<List<int>>? _subscription;

  Future<String> read() {
    _subscription = _responseBody.stream.listen(
      _onChunk,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: true,
    );

    return _completer.future;
  }

  void _onChunk(List<int> chunk) {
    if (_completer.isCompleted) return;

    final remainingBytes = _maxResponseSize - _bytes.length;
    if (chunk.length <= remainingBytes) {
      _bytes.addAll(chunk);
      return;
    }

    _completeTruncated(chunk, remainingBytes);
  }

  void _completeTruncated(List<int> chunk, int remainingBytes) {
    _bytes.addAll(chunk.sublist(0, remainingBytes));
    _completer.complete(
      '${_decodeResponseBytes(_bytes, trimIncompleteSequence: true)}'
      '$_truncatedSuffix',
    );
    unawaited(_cancelSubscription());
  }

  Future<void> _cancelSubscription() async {
    final subscription = _subscription;
    if (subscription == null) return;
    await subscription.cancel();
  }

  void _onError(Object error, StackTrace stackTrace) {
    if (!_completer.isCompleted) {
      _completer.completeError(error, stackTrace);
    }
  }

  void _onDone() {
    if (!_completer.isCompleted) {
      _completer.complete(_decodeResponseBytes(_bytes));
    }
  }
}

String _decodeResponseBytes(
  List<int> bytes, {
  bool trimIncompleteSequence = false,
}) => const Utf8Decoder(
  allowMalformed: true,
).convert(bytes, 0, trimIncompleteSequence ? _utf8PrefixLength(bytes) : null);

int _utf8PrefixLength(List<int> bytes) {
  if (bytes.isEmpty) return 0;

  final continuationBytes = _trailingContinuationBytes(bytes);
  if (continuationBytes == 0) return _prefixWithoutContinuation(bytes);

  return _prefixWithContinuation(bytes, continuationBytes);
}

int _prefixWithContinuation(List<int> bytes, int continuationBytes) {
  final leadIndex = bytes.length - continuationBytes - 1;
  if (leadIndex < 0) return bytes.length;

  final sequenceLength = _utf8SequenceLength(bytes[leadIndex]);

  return sequenceLength == 0 || continuationBytes >= sequenceLength - 1
      ? bytes.length
      : leadIndex;
}

int _trailingContinuationBytes(List<int> bytes) {
  var count = 0;
  for (
    var index = bytes.length - 1;
    index >= 0 && _isUtf8ContinuationByte(bytes[index]);
    index--
  ) {
    count++;
  }

  return count;
}

int _prefixWithoutContinuation(List<int> bytes) {
  final sequenceLength = _utf8SequenceLength(bytes.last);

  return sequenceLength > 1 ? bytes.length - 1 : bytes.length;
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
  if (body.length <= _maxResponseSize) return body;

  return '${body.firstCharacters(_maxResponseSize)}$_truncatedSuffix';
}
