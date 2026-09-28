import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_skill_context_runtime.g.dart';

@Riverpod(keepAlive: true)
class ConversationSkillContextRuntime
    extends _$ConversationSkillContextRuntime {
  final Map<String, int> _generations = {};

  @override
  Map<String, ConversationSkillContextSnapshot> build() => {};

  int begin(String conversationId) {
    final generation = _nextGeneration(conversationId);
    _set(
      conversationId,
      const ConversationSkillContextSnapshot(phase: .preparing),
    );

    return generation;
  }

  void ready(
    String conversationId,
    int generation, {
    required Map<String, String> selectedRevisions,
    required bool canActivate,
  }) {
    if (_generations[conversationId] != generation) return;

    _set(
      conversationId,
      .new(
        phase: .ready,
        selectedRevisions: .unmodifiable(selectedRevisions),
        canActivate: canActivate,
      ),
    );
  }

  void error(String conversationId, int generation) {
    if (_generations[conversationId] != generation) return;

    _set(conversationId, const ConversationSkillContextSnapshot(phase: .error));
  }

  void markNeedsContext(String conversationId) {
    final _ = _nextGeneration(conversationId);
    _set(
      conversationId,
      const ConversationSkillContextSnapshot(phase: .needsContext),
    );
  }

  int _nextGeneration(String conversationId) {
    final generation = (_generations[conversationId] ?? 0) + 1;
    _generations[conversationId] = generation;

    return generation;
  }

  void _set(String conversationId, ConversationSkillContextSnapshot snapshot) {
    state = {...state, conversationId: snapshot};
  }
}

enum ConversationSkillContextPhase { preparing, ready, needsContext, error }

class const ConversationSkillContextSnapshot({
  required final ConversationSkillContextPhase phase,
  final Map<String, String> selectedRevisions = const {},
  final bool canActivate = false,
});
