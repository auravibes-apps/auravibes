import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

typedef ProviderFaultAttempt = Future<http.StreamedResponse> Function(
  ProviderFaultRequest request,
);

/// Captures bytes before a request is finalized by the transport.
final class ProviderFaultRequest {
  new(http.BaseRequest request, this.body)
    : method = request.method,
      url = request.url,
      headers = Map.unmodifiable(request.headers),
      supportsAbort = request is http.Abortable;

  final String method;
  final Uri url;
  final Map<String, String> headers;
  final String body;
  final bool supportsAbort;

  Map<String, dynamic> get json => jsonDecode(body) as Map<String, dynamic>;
}

/// One script drives every production adapter. Unscripted sends cannot escape
/// to the network. Abort is emulated only for requests that supply a trigger.
final class ProviderFaultClient extends http.BaseClient {
  new(this.attempts);

  final List<ProviderFaultAttempt> attempts;
  final List<ProviderFaultRequest> requests = [];
  int closeCount = 0;
  int abortCount = 0;
  final Map<int, Completer<ProviderFaultRequest>> _sent = {};

  Future<ProviderFaultRequest> requestAt(int index) {
    if (requests.length > index) return Future.value(requests[index]);

    return _sent.putIfAbsent(index, Completer.new).future;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final index = requests.length;
    final snapshot = ProviderFaultRequest(
      request,
      await request.finalize().bytesToString(),
    );
    requests.add(snapshot);
    _sent[index]?.complete(snapshot);
    if (index >= attempts.length) {
      throw StateError('Unscripted provider attempt ${index + 1}');
    }
    final response = attempts[index](snapshot);
    final abort = switch (request) {
      http.Abortable(:final abortTrigger) => abortTrigger,
      _ => null,
    };
    if (abort == null) return await response;

    final aborted = () async {
      await abort;
      abortCount++;
      throw http.RequestAbortedException(request.url);
    }();
    final result = await Future.any([response, aborted]);

    return http.StreamedResponse(
      _withAbort(result.stream, abort, request.url),
      result.statusCode,
      contentLength: result.contentLength,
      headers: result.headers,
    );
  }

  @override
  void close() => closeCount++;
}

Stream<List<int>> _withAbort(
  Stream<List<int>> source,
  Future<void> abort,
  Uri url,
) {
  final controller = StreamController<List<int>>();
  StreamSubscription<List<int>>? subscription;
  var finished = false;
  controller
    ..onListen = () {
      subscription = source.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          finished = true;
          unawaited(controller.close());
        },
      );
      unawaited(() async {
        await abort;
        if (finished) return;
        finished = true;
        controller.addError(http.RequestAbortedException(url));
        await subscription?.cancel();
        unawaited(controller.close());
      }());
    }
    ..onPause = () {
      subscription?.pause();
    }
    ..onResume = () {
      subscription?.resume();
    }
    ..onCancel = () async {
      finished = true;
      await subscription?.cancel();
    };

  return controller.stream;
}

final class ProviderFaultBody {
  new() {
    _controller.onListen = _listened.complete;
    _controller.onCancel = () {
      cancellationCount++;
      _cancelled.complete();
    };
  }

  int cancellationCount = 0;
  final StreamController<List<int>> _controller = .new();
  final Completer<void> _listened = .new();
  final Completer<void> _cancelled = .new();

  Stream<List<int>> get stream => _controller.stream;
  Future<void> get listened => _listened.future;
  Future<void> get cancelled => _cancelled.future;

  void add(List<int> bytes) => _controller.add(bytes);
  void fail(Object error) => _controller.addError(error);
  Future<void> close() => _controller.close();

  void dispose() {
    if (!_controller.isClosed) unawaited(_controller.close());
  }
}
