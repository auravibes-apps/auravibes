// ignore_for_file: cascade_invocations
// Required: Test readability
import 'package:auravibes_app/domain/entities/compaction.dart';
import 'package:auravibes_app/features/chats/providers/compaction_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('CompactionExecution notifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty', () {
      final state = container.read(compactionExecutionProvider);
      expect(state, isEmpty);
    });

    test('markRunning adds running state for conversation', () {
      final notifier = container.read(compactionExecutionProvider.notifier);

      notifier.markRunning(
        CompactionExecutionState(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.auto,
          startedAt: DateTime.now(),
          status: CompactionExecutionStatus.running,
        ),
      );

      final state = container.read(compactionExecutionProvider);
      expect(state['conv-1']?.status, CompactionExecutionStatus.running);
      expect(state['conv-1']?.trigger, CompactionTrigger.auto);
    });

    test('isCompacting returns true when running', () {
      final notifier = container.read(compactionExecutionProvider.notifier);

      expect(notifier.isCompacting('conv-1'), isFalse);

      notifier.markRunning(
        CompactionExecutionState(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.auto,
          startedAt: DateTime.now(),
          status: CompactionExecutionStatus.running,
        ),
      );

      expect(notifier.isCompacting('conv-1'), isTrue);
    });

    test('markSuccess transitions from running to removed after delay', () {
      final notifier = container.read(compactionExecutionProvider.notifier);

      notifier.markRunning(
        CompactionExecutionState(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.auto,
          startedAt: DateTime.now(),
          status: CompactionExecutionStatus.running,
        ),
      );

      notifier.markSuccess('conv-1');

      final state = container.read(compactionExecutionProvider);
      expect(state['conv-1']?.status, CompactionExecutionStatus.success);
    });

    test('markFailure transitions from running to failure', () {
      final notifier = container.read(compactionExecutionProvider.notifier);

      notifier.markRunning(
        CompactionExecutionState(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.manual,
          startedAt: DateTime.now(),
          status: CompactionExecutionStatus.running,
        ),
      );

      notifier.markFailure('conv-1');

      final state = container.read(compactionExecutionProvider);
      expect(state['conv-1']?.status, CompactionExecutionStatus.failure);
    });

    test('markSuccess on unknown conversationId is no-op', () {
      final notifier = container.read(compactionExecutionProvider.notifier);

      notifier.markSuccess('unknown');

      final state = container.read(compactionExecutionProvider);
      expect(state, isEmpty);
    });

    test('markFailure on unknown conversationId is no-op', () {
      final notifier = container.read(compactionExecutionProvider.notifier);

      notifier.markFailure('unknown');

      final state = container.read(compactionExecutionProvider);
      expect(state, isEmpty);
    });

    test('multiple conversations can compact simultaneously', () {
      final notifier = container.read(compactionExecutionProvider.notifier);

      notifier
        ..markRunning(
          CompactionExecutionState(
            conversationId: 'conv-1',
            trigger: CompactionTrigger.auto,
            startedAt: DateTime.now(),
            status: CompactionExecutionStatus.running,
          ),
        )
        ..markRunning(
          CompactionExecutionState(
            conversationId: 'conv-2',
            trigger: CompactionTrigger.manual,
            startedAt: DateTime.now(),
            status: CompactionExecutionStatus.running,
          ),
        );

      expect(notifier.isCompacting('conv-1'), isTrue);
      expect(notifier.isCompacting('conv-2'), isTrue);

      notifier.markSuccess('conv-1');
      expect(notifier.isCompacting('conv-1'), isFalse);
      expect(notifier.isCompacting('conv-2'), isTrue);
    });

    test('compactionExecutionState provider reads from notifier', () {
      final notifier = container.read(compactionExecutionProvider.notifier);

      expect(
        container.read(compactionExecutionStateProvider('conv-1')),
        isNull,
      );

      notifier.markRunning(
        CompactionExecutionState(
          conversationId: 'conv-1',
          trigger: CompactionTrigger.auto,
          startedAt: DateTime.now(),
          status: CompactionExecutionStatus.running,
        ),
      );

      final state = container.read(compactionExecutionStateProvider('conv-1'));
      expect(state?.status, CompactionExecutionStatus.running);
      expect(state?.trigger, CompactionTrigger.auto);
    });
  });
}
