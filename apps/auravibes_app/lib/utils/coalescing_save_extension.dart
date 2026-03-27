import 'dart:async';

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

  T? _pending;

  void push(T state) {
    if (_closed) return;
    _pending = state;
    if (!_saving) _run();
  }

  void complete([T? finalState]) {
    if (_closed) return;
    if (finalState != null) {
      _pending = finalState;
    }
    _doneRequested = true;
    if (!_saving) _run();
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

    listen(
      saver.push,
      onError: controller.addError,
      onDone: () {
        saver.complete();
        controller.close();
      },
      cancelOnError: false,
    );

    return controller.stream;
  }
}
