import 'dart:async';

import 'package:auravibes_server/src/features/conversations/domain/conversation_values.dart';
import 'package:auravibes_server/src/features/conversations/workers/conversation_job_dispatcher.dart';
import 'package:test/test.dart';

void main() {
  test('starts a drain without waiting for a wakeup timer', () async {
    var calls = 0;
    final dispatcher = ConversationJobDispatcher(
      drain: (_) async => calls++,
      onError: (_, _) {},
    );
    dispatcher.start(wakeups: const Stream<void>.empty(), isActive: () => true);

    await Future<void>.delayed(Duration.zero);

    expect(calls, 1);
    await dispatcher.stop();
  });

  test('coalesces wakes received while a drain is active', () async {
    final wakes = StreamController<void>(sync: true);
    final firstDrain = Completer<void>();
    var calls = 0;
    final dispatcher = ConversationJobDispatcher(
      drain: (_) async {
        calls++;
        if (calls == 1) await firstDrain.future;
      },
      onError: (_, _) {},
    );
    dispatcher.start(wakeups: wakes.stream, isActive: () => true);
    await Future<void>.delayed(Duration.zero);

    wakes
      ..add(null)
      ..add(null);
    firstDrain.complete();
    await Future<void>.delayed(Duration.zero);

    expect(calls, 2);
    await dispatcher.stop();
    await wakes.close();
  });

  test('records the active drain before synchronous wakeups', () async {
    final wakes = StreamController<void>(sync: true);
    final firstDrain = Completer<void>();
    var activeDrains = 0;
    var calls = 0;
    var maxActiveDrains = 0;
    final dispatcher = ConversationJobDispatcher(
      drain: (_) async {
        calls++;
        activeDrains++;
        maxActiveDrains = maxActiveDrains < activeDrains
            ? activeDrains
            : maxActiveDrains;
        if (calls == 1) {
          wakes.add(null);
          await firstDrain.future;
        }
        activeDrains--;
      },
      onError: (_, _) {},
    );
    dispatcher.start(wakeups: wakes.stream, isActive: () => true);
    await Future<void>.delayed(Duration.zero);

    expect(calls, 1);
    expect(maxActiveDrains, 1);
    firstDrain.complete();
    await Future<void>.delayed(Duration.zero);

    expect(calls, 2);
    expect(maxActiveDrains, 1);
    await dispatcher.stop();
    await wakes.close();
  });

  test('bounds a cross-conversation continuation backlog', () async {
    final wakes = StreamController<void>(sync: true);
    final firstTurn = Completer<void>();
    final releaseFirstTurn = Completer<void>();
    final drainedAll = Completer<void>();
    final workItems = [
      for (var index = 0; index < 32; index++)
        for (var ordinal = 0; ordinal < 4; ordinal++)
          (conversationId: 'conversation-$index', ordinal: ordinal),
    ];
    final drained = <({String conversationId, int ordinal})>[];
    var activeTurns = 0;
    var maxActiveTurns = 0;
    var nextWorkItem = 0;
    final dispatcher = ConversationJobDispatcher(
      drain: (isActive) async {
        while (nextWorkItem < workItems.length && isActive()) {
          activeTurns++;
          if (activeTurns > maxActiveTurns) maxActiveTurns = activeTurns;
          if (nextWorkItem == 0) {
            firstTurn.complete();
            await releaseFirstTurn.future;
          }
          drained.add(workItems[nextWorkItem++]);
          activeTurns--;
        }
        if (nextWorkItem == workItems.length && !drainedAll.isCompleted) {
          drainedAll.complete();
        }
      },
      onError: (_, _) {},
    );
    dispatcher.start(wakeups: wakes.stream, isActive: () => true);
    await firstTurn.future;

    for (var wakeup = 0; wakeup < workItems.length; wakeup++) {
      wakes.add(null);
    }
    expect(activeTurns, 1);
    releaseFirstTurn.complete();
    await drainedAll.future;
    await dispatcher.stop();

    expect(
      ConversationLimits.maxConcurrentBackgroundContinuations,
      1,
    );
    expect(
      maxActiveTurns,
      ConversationLimits.maxConcurrentBackgroundContinuations,
    );
    expect(drained, workItems);
    expect(drained.toSet(), hasLength(workItems.length));
    for (var conversation = 0; conversation < 32; conversation++) {
      final items = drained
          .where((item) => item.conversationId == 'conversation-$conversation')
          .toList();
      expect(items.map((item) => item.ordinal), [0, 1, 2, 3]);
    }
    await wakes.close();
  });

  test('rejects start until an in-progress stop completes', () async {
    final firstDrain = Completer<void>();
    var calls = 0;
    final dispatcher = ConversationJobDispatcher(
      drain: (_) async {
        calls++;
        if (calls == 1) await firstDrain.future;
      },
      onError: (_, _) {},
    );
    dispatcher.start(wakeups: const Stream<void>.empty(), isActive: () => true);
    await Future<void>.delayed(Duration.zero);

    final stopping = dispatcher.stop();
    dispatcher.start(wakeups: const Stream<void>.empty(), isActive: () => true);
    firstDrain.complete();
    await stopping;
    await Future<void>.delayed(Duration.zero);

    expect(calls, 1);
    dispatcher.start(wakeups: const Stream<void>.empty(), isActive: () => true);
    await Future<void>.delayed(Duration.zero);

    expect(calls, 2);
    await dispatcher.stop();
  });

  test('does not drain after ownership becomes inactive', () async {
    var active = true;
    var calls = 0;
    final wakes = StreamController<void>();
    final dispatcher = ConversationJobDispatcher(
      drain: (_) async => calls++,
      onError: (_, _) {},
    );
    dispatcher.start(wakeups: wakes.stream, isActive: () => active);
    await Future<void>.delayed(Duration.zero);
    active = false;
    wakes.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(calls, 1);
    await dispatcher.stop();
    await wakes.close();
  });

  test('uses the durable fallback when no wakeup arrives', () async {
    var calls = 0;
    final dispatcher = ConversationJobDispatcher(
      drain: (_) async => calls++,
      onError: (_, _) {},
      recoveryInterval: const Duration(milliseconds: 1),
    );
    dispatcher.start(wakeups: const Stream<void>.empty(), isActive: () => true);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(calls, greaterThanOrEqualTo(2));
    await dispatcher.stop();
  });
}
