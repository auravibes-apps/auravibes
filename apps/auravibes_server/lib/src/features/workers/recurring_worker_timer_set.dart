import 'dart:async';

class RecurringWorkerTimerSet {
  final _timers = <String, Timer>{};

  int get activeCount => _timers.length;

  bool schedule(String workerKey, Duration interval, void Function() onTick) {
    if (_timers.containsKey(workerKey)) return false;
    _timers[workerKey] = Timer.periodic(interval, (_) => onTick());
    return true;
  }

  void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}
