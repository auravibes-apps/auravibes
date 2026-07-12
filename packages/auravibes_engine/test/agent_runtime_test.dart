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
    'cancellation scope runs cleanup once and immediate late cleanup',
    () async {
      final scope = AgentCancellationScope();
      final calls = <String>[];

      scope
        ..registerCleanup(() => calls.add('first'))
        ..registerCleanup(() async => calls.add('async'))
        ..registerCleanup(() => throw StateError('ignored'))
        ..requestStop()
        ..requestStop()
        ..registerCleanup(() => calls.add('late'));
      await Future<void>.delayed(Duration.zero);

      expect(scope.isCancellationRequested, isTrue);
      expect(calls, ['first', 'async', 'late']);
    },
  );
}
