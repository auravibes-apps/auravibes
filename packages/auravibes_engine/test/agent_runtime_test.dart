import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('conversation DTOs expose constructor values', () {
    const created = AgentCreatedMessage(id: 'm1');
    const draft = AgentQueuedDraft(content: 'hello');
    final message = AgentConversationMessage(
      id: 'm1',
      conversationId: 'c1',
      content: 'hello',
      type: 'text',
      status: 'sent',
      isUser: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    expect(created.id, 'm1');
    expect(draft.content, 'hello');
    expect(message.conversationId, 'c1');
    expect(message.isUser, isTrue);
  });

  test(
    'cancellation runtime runs cleanup once and immediate late cleanup',
    () async {
      final runtime = AgentCancellationRuntime();
      final calls = <String>[];

      runtime
        ..requestStop('missing')
        ..start('c1')
        ..registerCleanup('c1', () => calls.add('first'))
        ..registerCleanup('c1', () async => calls.add('async'))
        ..registerCleanup('c1', () => throw StateError('ignored'))
        ..requestStop('c1')
        ..requestStop('c1')
        ..registerCleanup('c1', () => calls.add('late'));
      await Future<void>.delayed(Duration.zero);

      expect(runtime.isCancellationRequested('c1'), isTrue);
      expect(calls, ['first', 'async', 'late']);

      runtime.forceClear('c1');
      expect(runtime.isCancellationRequested('c1'), isFalse);
    },
  );

  test('cancellation runtime ignores normal stop requested before start', () {
    final runtime = AgentCancellationRuntime()..requestStop('c1');

    final _ = runtime.start('c1');

    expect(runtime.isCancellationRequested('c1'), isFalse);
  });

  test('cancellation runtime preserves explicit stop-on-start request', () {
    final runtime = AgentCancellationRuntime()..requestStopOnStart('c1');

    final _ = runtime.start('c1');

    expect(runtime.isCancellationRequested('c1'), isTrue);
  });
}
