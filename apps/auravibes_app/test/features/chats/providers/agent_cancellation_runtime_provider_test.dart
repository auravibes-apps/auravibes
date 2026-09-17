import 'dart:async';

// ignore_for_file: cascade_invocations

import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentCancellationRuntime', () {
    test(
      'does not create a cancellation entry when stopping inactive runs',
      () {
        final runtime = AgentCancellationRuntime();

        runtime.requestStop('conversation-1');

        expect(runtime.current('conversation-1'), isNull);
      },
    );

    test('keeps existing cleanups when start is called twice', () {
      final runtime = AgentCancellationRuntime();
      var cleanupCount = 0;

      runtime.start('conversation-1').registerCleanup(() {
        cleanupCount += 1;
      });
      final replacement = runtime.start('conversation-1');
      replacement.registerCleanup(() => cleanupCount += 10);
      runtime.requestStop('conversation-1');

      expect(cleanupCount, 11);
      expect(replacement.isCancellationRequested, isTrue);
    });

    test('pending stop is consumed by one start only', () {
      final runtime = AgentCancellationRuntime()..requestStopOnStart('c1');

      final first = runtime.start('c1');
      expect(first.isCancellationRequested, isTrue);
      runtime.clear('c1', first);

      expect(runtime.start('c1').isCancellationRequested, isFalse);
    });

    test('stale clear cannot clear replacement', () {
      final runtime = AgentCancellationRuntime();
      final stale = runtime.start('c1');
      final replacement = runtime.start('c1');

      runtime.clear('c1', stale);

      expect(runtime.current('c1'), same(replacement));
    });

    test('force clear cancels and removes active scope', () {
      final runtime = AgentCancellationRuntime();
      final scope = runtime.start('c1');

      runtime.forceClear('c1');

      expect(scope.isCancellationRequested, isTrue);
      expect(runtime.current('c1'), isNull);
    });

    test('waits for asynchronous cleanup before completion', () async {
      final runtime = AgentCancellationRuntime();
      final cleanupRelease = Completer<void>();
      final scope = runtime.start('c1');
      scope.registerCleanup(() => cleanupRelease.future);

      runtime.forceClear('c1');
      var completed = false;
      final wait = runtime.waitForCompletion('c1');
      await Future<void>.delayed(.zero);
      expect(completed, isFalse);

      cleanupRelease.complete();
      runtime.clear('c1', scope);
      await wait;
      completed = true;
      expect(completed, isTrue);
    });
  });
}
