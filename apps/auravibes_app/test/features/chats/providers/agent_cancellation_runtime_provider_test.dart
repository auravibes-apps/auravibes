import 'dart:async';

// ignore_for_file: cascade_invocations

import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:riverpod/riverpod.dart';
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

    test('force clear closes scope after cleanup completes', () async {
      final runtime = AgentCancellationRuntime();
      final cleanupRelease = Completer<void>();
      final scope = runtime.start('c1');
      scope.registerCleanup(() => cleanupRelease.future);

      runtime.forceClear('c1');
      final wait = runtime.waitForCompletion('c1');
      cleanupRelease.complete();

      await wait.timeout(const Duration(milliseconds: 200));
      expect(runtime.current('c1'), isNull);
    });

    test('force clear completes after cleanup timeout', () async {
      final runtime = AgentCancellationRuntime();
      final cleanupRelease = Completer<void>();
      final scope = runtime.start('c1');
      scope.registerCleanup(() => cleanupRelease.future);

      runtime.forceClear('c1');

      try {
        await runtime
            .waitForCompletion('c1')
            .timeout(const Duration(seconds: 6));
      } finally {
        if (!cleanupRelease.isCompleted) cleanupRelease.complete();
      }

      expect(runtime.current('c1'), isNull);
    });

    test('duplicate child finish preserves failure and sibling', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final runtime = container.read(activeSubAgentRuntimeProvider.notifier);
      final error = StateError('provider-token=secret');
      final stackTrace = StackTrace.current;

      runtime.start(parentId: 'parent', childId: 'child-1');
      runtime.start(parentId: 'parent', childId: 'child-2');
      runtime.finish((
        parentId: 'parent',
        childId: 'child-1',
        status: .error,
        error: error,
        stackTrace: stackTrace,
      ));
      final failure = runtime.failure('child-1');

      runtime.finish((
        parentId: 'parent',
        childId: 'child-1',
        status: .done,
        error: null,
        stackTrace: null,
      ));

      expect(runtime.failure('child-1'), same(failure));
      expect(runtime.childrenOf('parent'), {'child-2'});

      expect(runtime.statusOf('child-1'), ActiveSubAgentStatus.failed);
      expect(runtime.statusOf('child-2'), ActiveSubAgentStatus.running);
      runtime.markAwaitingApproval('child-2');
      expect(
        runtime.statusOf('child-2'),
        ActiveSubAgentStatus.awaitingApproval,
      );
      runtime.markRunning('child-2');
      expect(runtime.statusOf('child-2'), ActiveSubAgentStatus.running);

      runtime.finish((
        parentId: 'parent',
        childId: 'child-2',
        status: .stopped,
        error: null,
        stackTrace: null,
      ));
      expect(runtime.statusOf('child-2'), ActiveSubAgentStatus.stopped);
      expect(runtime.childrenOf('parent'), isEmpty);
    });

    test('replacement keeps completion tied to its scope', () async {
      final runtime = AgentCancellationRuntime();
      final cleanupRelease = Completer<void>();
      final oldScope = runtime.start('c1');
      oldScope.registerCleanup(() => cleanupRelease.future);
      final oldCompletion = runtime.waitForCompletion('c1');

      final replacement = runtime.start('c1');
      var replacementCompleted = false;
      final replacementCompletion = runtime.waitForCompletion('c1').then((_) {
        replacementCompleted = true;
      });
      cleanupRelease.complete();
      await oldCompletion.timeout(const Duration(milliseconds: 200));
      expect(replacementCompleted, isFalse);

      runtime.clear('c1', replacement);
      await replacementCompletion.timeout(const Duration(milliseconds: 200));
      expect(replacementCompleted, isTrue);
    });
  });
}
