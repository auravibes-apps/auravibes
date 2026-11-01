import 'dart:async';
import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';

/// An ordered, offline transport. Extra sends always fail rather than reaching
/// a provider or accidentally replaying the last successful response.
final class ProviderFaultFixture {
  new(this.attempts);

  final List<Future<ProviderTransportResponse> Function()> attempts;
  final List<String> _requests = [];

  List<Map<String, dynamic>> get requests => [
    for (final request in _requests)
      jsonDecode(request) as Map<String, dynamic>,
  ];

  Future<ProviderTransportResponse> send(Map<String, dynamic> body) {
    final index = _requests.length;
    _requests.add(jsonEncode(body));
    if (index >= attempts.length) {
      throw StateError('Unscripted provider attempt ${index + 1}');
    }
    return attempts[index]();
  }
}

/// A manually released response stream, with observable subscription cleanup.
final class ProviderFaultBody {
  new() {
    _controller.onListen = _listened.complete;
    _controller.onCancel = () {
      cancellationCount++;
      _cancelled.complete();
    };
  }

  final StreamController<List<int>> _controller = .new();
  final Completer<void> _listened = .new();
  final Completer<void> _cancelled = .new();
  int cancellationCount = 0;

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
