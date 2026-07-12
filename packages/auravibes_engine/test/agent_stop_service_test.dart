import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_engine/src/agent_stop_service.dart';
import 'package:test/test.dart';
import 'support/fake_cancellation_effects.dart';

void main() {
  test(
    'requests cancellation, clears queue, and stops pending tools',
    () async {
      final cancellationRuntime = FakeCancellationEffects()
        ..start('conversation-1');
      final sendQueueRuntime = _FakeAgentSendQueueRuntime();
      final dataProvider = _FakeStopConversationDataProvider();
      final usecase = AgentStopService(
        cancellationEffects: cancellationRuntime,
        sendQueueRuntime: sendQueueRuntime,
        provider: dataProvider,
      );

      await usecase(conversationId: 'conversation-1');

      expect(
        cancellationRuntime.isCancellationRequested('conversation-1'),
        true,
      );
      expect(sendQueueRuntime.clearedConversationIds, ['conversation-1']);
      expect(dataProvider.stoppedConversationIds, ['conversation-1']);
    },
  );
}

class _FakeAgentSendQueueRuntime implements AgentSendQueueRuntime {
  final clearedConversationIds = <String>[];

  @override
  void clear(String conversationId) {
    clearedConversationIds.add(conversationId);
  }

  @override
  List<AgentQueuedDraft> dequeueAll(String conversationId) {
    return const [];
  }
}

class _FakeStopConversationDataProvider implements AgentStopProvider {
  final stoppedConversationIds = <String>[];

  @override
  Future<void> stopLatestPendingTools(String conversationId) async {
    stoppedConversationIds.add(conversationId);
  }
}
