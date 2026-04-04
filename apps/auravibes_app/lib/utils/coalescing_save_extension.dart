import 'dart:async';

import 'package:rxdart/rxdart.dart';

class _CoalescingSaver<T> {
  _CoalescingSaver({
    required Future<void> Function(T state) store,
    required void Function(T state) onSaved,
  }) : _store = store,
       _onSaved = onSaved;

  final Future<void> Function(T state) _store;
  final void Function(T state) _onSaved;

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
      while (true) {
        if (_pending != null) {
          final toSave = _pending as T;
          _pending = null;
          try {
            await _store(toSave);
            _onSaved(toSave);
          } on Exception catch (_) {
            // Swallow exceptions to allow loop to continue
          }
          if (_pending != null) continue;
        }

        if (_doneRequested) {
          _closed = true;
          if (!_doneCompleter.isCompleted) {
            _doneCompleter.complete();
          }
          break;
        }

        break;
      }
    } finally {
      _saving = false;
    }
  }
}

extension CoalescingSaveExtension<T> on Stream<T> {
  Stream<T> coalescingSave({
    required Future<void> Function(T state) store,
  }) {
    final controller = StreamController<T>();

    final saver = _CoalescingSaver<T>(
      store: store,
      onSaved: controller.add,
    );

    late final StreamSubscription<T> subscription;

    subscription = shareReplay().listen(
      saver.push,
      onError: controller.addError,
      onDone: () async {
        await saver.complete();
        await controller.close();
      },
      cancelOnError: false,
    );

    controller.onCancel = subscription.cancel;

    return controller.stream;
  }
}
