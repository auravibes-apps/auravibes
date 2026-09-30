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
    _set(conversationId, const .new(phase: .preparing));

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
    errorWithCause(conversationId, generation, .preparationFailed);
  }

  void errorWithCause(
    String conversationId,
    int generation,
    ConversationSkillContextFailure failure,
  ) {
    if (_generations[conversationId] != generation) return;

    _set(conversationId, .new(phase: .error, failure: failure));
  }

  void markNeedsContext(String conversationId) {
    final _ = _nextGeneration(conversationId);
    _set(conversationId, const .new(phase: .needsContext));
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

enum ConversationSkillContextFailure {
  missingCredentials,
  unavailableMetadata,
  preparationFailed,
}

class const ConversationSkillContextSnapshot({
  required final ConversationSkillContextPhase phase,
  final Map<String, String> selectedRevisions = const {},
  final bool canActivate = false,
  final ConversationSkillContextFailure? failure,
});
