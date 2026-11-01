import 'dart:async';

import 'package:genkit/plugin.dart' show CancellationToken;
import 'package:http/http.dart' as http;

/// Adds generation cancellation to SDKs that do not forward their abort token.
/// The caller still owns an injected client; a generation owns only clients
/// it creates. Encoding and retry decisions remain with the upstream SDK.
class CancellableProviderClient extends http.BaseClient {
  CancellableProviderClient({
    required http.Client client,
    required CancellationToken? cancellation,
    bool ownsClient = false,
  }) : _client = client,
       _cancellation = cancellation,
       _ownsClient = ownsClient;

  final http.Client _client;
  final CancellationToken? _cancellation;
  final bool _ownsClient;
  bool _closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_closed) throw StateError('Provider client is closed');
    final cancellation = _cancellation;
    cancellation?.throwIfCancelled();
    if (cancellation == null) return _client.send(request);

    final response = await _client.send(
      _AbortableProviderRequest(request, cancellation.whenCancelled),
    );
    return http.StreamedResponse(
      _CancellableProviderBody(
        response.stream,
        cancellation,
        request.url,
      ).stream,
      response.statusCode,
      headers: response.headers,
      contentLength: response.contentLength,
      request: response.request,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    if (_ownsClient) _client.close();
  }
}

/// Retains the original body stream, including multipart boundaries and
/// content type. Reading and re-encoding the body would change SDK requests.
class _AbortableProviderRequest extends http.BaseRequest
    implements http.Abortable {
  _AbortableProviderRequest(this._request, Future<void> cancellation)
    : abortTrigger = switch (_request) {
        http.Abortable(:final abortTrigger?) => Future.any([
          cancellation,
          abortTrigger,
        ]),
        _ => cancellation,
      },
      super(_request.method, _request.url) {
    headers.addAll(_request.headers);
    followRedirects = _request.followRedirects;
    maxRedirects = _request.maxRedirects;
    persistentConnection = _request.persistentConnection;
    contentLength = _request.contentLength;
  }

  final http.BaseRequest _request;
  @override
  final Future<void> abortTrigger;

  @override
  http.ByteStream finalize() {
    final body = _request.finalize();
    // MultipartRequest adds its boundary header during finalization. Copy
    // those final headers before the HTTP client reads this wrapper's headers.
    headers.addAll(_request.headers);
    contentLength = _request.contentLength;
    super.finalize();
    return body;
  }
}

class _CancellableProviderBody {
  _CancellableProviderBody(this._source, this._cancellation, this._url) {
    _controller.onListen = _listen;
    _controller.onPause = () {
      _subscription?.pause();
    };
    _controller.onResume = () {
      _subscription?.resume();
    };
    _controller.onCancel = _finish;
  }

  final Stream<List<int>> _source;
  final CancellationToken _cancellation;
  final Uri _url;
  final StreamController<List<int>> _controller = .new();
  StreamSubscription<List<int>>? _subscription;
  void Function()? _removeCancellation;
  Future<void>? _cleanup;
  bool _finished = false;

  Stream<List<int>> get stream => _controller.stream;

  void _listen() {
    _subscription = _source.listen(
      _controller.add,
      onError: _error,
      onDone: () => unawaited(_finish()),
    );
    _removeCancellation = _cancellation.onCancel(
      () => _error(http.RequestAbortedException(_url), StackTrace.current),
    );
  }

  void _error(Object error, StackTrace stackTrace) {
    if (_finished) return;
    _controller.addError(error, stackTrace);
    unawaited(_finish());
  }

  Future<void> _finish() {
    final cleanup = _cleanup;
    if (cleanup != null) return cleanup;
    _finished = true;
    _removeCancellation?.call();
    return _cleanup = _cancelSource();
  }

  Future<void> _cancelSource() async {
    await _subscription?.cancel();
    if (!_controller.isClosed) unawaited(_controller.close());
  }
}
