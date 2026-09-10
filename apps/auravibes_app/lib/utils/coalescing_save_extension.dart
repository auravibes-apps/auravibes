// Required: Existing test and UI helpers keep compact return flow.
import 'dart:async';

import 'package:rxdart/rxdart.dart';

class _CoalescingSaver<T>({
  required final Future<void> Function(T state) _store,
  required final void Function(T state) _onSaved,
}) {
  bool _saving = false;
  bool _closed = false;
  bool _doneRequested = false;
  final Completer<void> _doneCompleter = Completer<void>();

  T? _pending;

  void push(T state) {
    if (_closed) return;
    _pending = state;
    if (!_saving) _run();
  }

  Future<void> complete([T? finalState]) {
    if (_closed) return _doneCompleter.future;
    if (finalState != null) {
      _pending = finalState;
    }
    _doneRequested = true;
    if (!_saving) {
      unawaited(_run());
    }

    return _doneCompleter.future;
  }

  Future<void> _run() async {
    _saving = true;
    try {
      await _savePendingStates();
    } finally {
      _saving = false;
    }
  }

  Future<void> _savePendingStates() async {
    while (true) {
      final didSave = await _savePending();
      if (didSave && _pending != null) continue;
      if (_completeIfRequested()) return;

      return;
    }
  }

  Future<bool> _savePending() async {
    final toSave = _pending;
    if (toSave == null) return false;

    _pending = null;
    try {
      await _store(toSave);
      _onSaved(toSave);
    } on Exception catch (_) {
      // Swallow exceptions to allow loop to continue.
    }

    return true;
  }

  bool _completeIfRequested() {
    if (!_doneRequested) return false;

    _closed = true;
    if (!_doneCompleter.isCompleted) _doneCompleter.complete();

    return true;
  }
}

extension CoalescingSaveExtension<T> on Stream<T> {
  Stream<T> coalescingSave({required Future<void> Function(T state) store}) {
    final controller = StreamController<T>();
    final saver = _CoalescingSaver<T>(store: store, onSaved: controller.add);
    final subscription = _listenToSharedStream(this, saver, controller);
    controller.onCancel = subscription.cancel;

    return controller.stream;
  }
}

StreamSubscription<T> _listenToSharedStream<T>(
  Stream<T> source,
  _CoalescingSaver<T> saver,
  StreamController<T> controller,
) => source.shareReplay().listen(
  saver.push,
  onError: controller.addError,
  onDone: () => unawaited(_closeCoalescedStream(saver, controller)),
  cancelOnError: false,
);

Future<void> _closeCoalescedStream<T>(
  _CoalescingSaver<T> saver,
  StreamController<T> controller,
) async {
  await saver.complete();
  final _ = await controller.close();
}
