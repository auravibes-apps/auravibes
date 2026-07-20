import 'dart:async';

import 'package:auravibes_server/src/features/workers/recurring_worker_timer_set.dart';
import 'package:test/test.dart';

void main() {
  test('keeps one timer per worker and stops all timers', () async {
    final timers = RecurringWorkerTimerSet();
    var ticks = 0;

    expect(
      timers.schedule('conversation', const Duration(milliseconds: 1), () {
        ticks++;
      }),
      isTrue,
    );
    expect(
      timers.schedule('conversation', const Duration(milliseconds: 1), () {
        ticks++;
      }),
      isFalse,
    );
    expect(timers.activeCount, 1);

    await Future<void>.delayed(const Duration(milliseconds: 5));
    timers.cancelAll();
    final stoppedAt = ticks;
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(timers.activeCount, 0);
    expect(ticks, stoppedAt);
  });
}
