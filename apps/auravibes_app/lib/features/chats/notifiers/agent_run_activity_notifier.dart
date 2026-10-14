import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'agent_run_activity_notifier.g.dart';

@riverpod
class AgentRunActivityNotifier extends _$AgentRunActivityNotifier {
  @override
  Set<String> build() => {};

  void startAgentRun(String conversationId) {
    state = {...state, conversationId};
  }

  void endAgentRun(String conversationId) {
    if (!state.contains(conversationId)) return;

    state = {
      for (final id in state)
        if (id != conversationId) id,
    };
  }
}
