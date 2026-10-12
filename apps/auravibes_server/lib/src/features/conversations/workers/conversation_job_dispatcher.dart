import 'dart:async';

import '../domain/conversation_values.dart';

typedef ConversationJobDrain = Future<void> Function(bool Function() isActive);

final class ConversationJobDispatcher({
  required final ConversationJobDrain _drain,
  required final void Function(Object error, StackTrace stackTrace) _onError,
  final Duration recoveryInterval = const Duration(seconds: 30),
}) {
  StreamSubscription<void>? _subscription;
  Timer? _recoveryTimer;
  Future<void>? _drainTask;
  Future<void>? _stopTask;
  bool _pending = false;
  bool _stopped = true;
  bool Function()? _isActive;
  int _activeDrains = 0;

  void start({
    required Stream<void> wakeups,
    required bool Function() isActive,
  }) {
    if (!_stopped || _stopTask != null) return;
    _stopped = false;
    _isActive = isActive;
    _subscription = wakeups.listen(
      (_) => requestDrain(),
      onError: (Object error, StackTrace stackTrace) =>
          _onError(error, stackTrace),
    );
    _recoveryTimer = Timer.periodic(recoveryInterval, (_) => requestDrain());
    requestDrain();
  }

  void requestDrain() {
    if (_stopped || !(_isActive?.call() ?? false)) return;
    _pending = true;
    if (_activeDrains >=
        ConversationLimits.maxConcurrentBackgroundContinuations) {
      return;
    }
    _activeDrains++;
    final task = Future<void>.microtask(_run);
    _drainTask = task;
    unawaited(
      task.whenComplete(() {
        _activeDrains--;
        if (identical(_drainTask, task)) {
          _drainTask = null;
          if (_pending && !_stopped && (_isActive?.call() ?? false)) {
            requestDrain();
          }
        }
      }),
    );
  }

  Future<void> _run() async {
    while (_pending && !_stopped && (_isActive?.call() ?? false)) {
      _pending = false;
      try {
        await _drain(() => !_stopped && (_isActive?.call() ?? false));
      } on Object catch (error, stackTrace) {
        _onError(error, stackTrace);
      }
    }
  }

  Future<void> stop() {
    final existingStopTask = _stopTask;
    if (existingStopTask != null) return existingStopTask;

    _stopped = true;
    _pending = false;
    _recoveryTimer?.cancel();
    _recoveryTimer = null;

    late final Future<void> task;
    task = _finishStop().whenComplete(() {
      if (identical(_stopTask, task)) _stopTask = null;
    });
    _stopTask = task;
    return task;
  }

  Future<void> _finishStop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _drainTask;
    _isActive = null;
  }
}
