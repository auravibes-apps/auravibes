import 'package:auravibes_app/features/chats/notifiers/agent_run_activity_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_streaming_notifier.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:riverpod/riverpod.dart';

final agentWorkingConversationsProvider = Provider<Set<String>>((ref) {
  final workingConversations = {...ref.watch(agentRunActivityProvider)};
  final activeSubAgents = ref.watch(activeSubAgentRuntimeProvider);
  final activeSubAgentRuntime = ref.read(
    activeSubAgentRuntimeProvider.notifier,
  );

  for (final parentId in activeSubAgents.keys) {
    if (_hasRunningSubAgent(parentId, activeSubAgents, activeSubAgentRuntime)) {
      final _ = workingConversations.add(parentId);
    }
  }

  return workingConversations;
});

final conversationActivityProvider = Provider<Set<String>>(
  (ref) => {
    ...ref.watch(conversationStreamingProvider),
    ...ref.watch(agentWorkingConversationsProvider),
  },
);

bool _hasRunningSubAgent(
  String parentId,
  Map<String, Set<String>> childrenByParent,
  ActiveSubAgentRuntime activeSubAgents,
) => _hasRunningSubAgentFrom((
  parentId: parentId,
  childrenByParent: childrenByParent,
  activeSubAgents: activeSubAgents,
  visited: <String>{},
));

typedef _RunningSubAgentRequest = ({
  String parentId,
  Map<String, Set<String>> childrenByParent,
  ActiveSubAgentRuntime activeSubAgents,
  Set<String> visited,
});

bool _hasRunningSubAgentFrom(_RunningSubAgentRequest request) {
  if (!request.visited.add(request.parentId)) return false;

  for (final childId
      in request.childrenByParent[request.parentId] ?? const <String>{}) {
    if (request.activeSubAgents.statusOf(childId) == .running ||
        _hasRunningSubAgentFrom((
          parentId: childId,
          childrenByParent: request.childrenByParent,
          activeSubAgents: request.activeSubAgents,
          visited: request.visited,
        ))) {
      return true;
    }
  }

  return false;
}
