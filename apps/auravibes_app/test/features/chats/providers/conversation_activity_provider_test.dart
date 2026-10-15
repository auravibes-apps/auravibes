import 'package:auravibes_app/features/chats/notifiers/agent_run_activity_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/providers/conversation_activity_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test(
    'combines response streaming and agent work without conflating them',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conversationStreamingProvider.notifier).start('streaming');
      container
          .read(agentRunActivityProvider.notifier)
          .startAgentRun('working');

      expect(container.read(conversationActivityProvider), {
        'streaming',
        'working',
      });
      expect(container.read(agentWorkingConversationsProvider), {'working'});
    },
  );

  test('includes running descendants and excludes approval waits', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final activeSubAgents = container.read(
      activeSubAgentRuntimeProvider.notifier,
    );

    final _ = activeSubAgents.start(parentId: 'parent', childId: 'child');
    expect(container.read(conversationActivityProvider), {'parent'});

    activeSubAgents.markAwaitingApproval('child');
    expect(container.read(conversationActivityProvider), isEmpty);

    final _ = activeSubAgents.start(parentId: 'child', childId: 'grandchild');
    expect(container.read(agentWorkingConversationsProvider), {
      'parent',
      'child',
    });

    activeSubAgents.markAwaitingApproval('grandchild');
    expect(container.read(conversationActivityProvider), isEmpty);
  });
}
