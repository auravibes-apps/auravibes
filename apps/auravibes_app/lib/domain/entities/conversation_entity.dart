// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_entity.freezed.dart';

/// Entity representing a conversation in the Aura application.
///
/// A conversation is a container for organizing and managing
/// chat messages within a specific workspace.
///
@freezed
abstract class const ConversationEntity._() with _$ConversationEntity {
  const factory({
    /// Unique identifier for the conversation.
    required String id,

    /// Human-readable title of the conversation.
    required String title,

    /// ID of the workspace this conversation belongs to.
    required String workspaceId,

    /// Whether this conversation is pinned.
    required bool isPinned,

    /// Timestamp when the conversation was created.
    required DateTime createdAt,

    /// Timestamp when the conversation was last updated.
    required DateTime updatedAt,

    /// Server revision for optimistic cloud mutations.
    @Default(0) int revision,

    /// ID of the AI model used for this conversation.
    String? modelId,

    /// ID of the selected agent used for this conversation.
    String? agentId,

    /// Conversation-scoped reasoning override. Null uses provider defaults.
    ReasoningConfiguration? reasoningConfiguration,

    /// Parent conversation id for hidden child/sub-agent conversations.
    String? parentConversationId,

    /// Source conversation id for a reference-backed fork.
    String? forkSourceConversationId,

    /// Source title captured when the fork was created.
    String? forkSourceTitle,

    /// Inclusive terminal message boundary captured by the fork.
    String? forkThroughMessageId,

    /// When inherited history was materialized into owned rows.
    DateTime? forkMaterializedAt,

    /// Active compaction checkpoint; null selects latest sent summary.
    String? activeCompactionCheckpointId,
  }) = _ConversationEntity;

  /// Returns true if the conversation has a valid title.
  bool get hasValidTitle => title.isNotEmpty;

  /// Returns true if the conversation is in a valid state.
  bool get isValid {
    return hasValidTitle && workspaceId.isNotEmpty;
  }

  bool get isFork => forkSourceConversationId != null;

  bool get isMaterialized => forkMaterializedAt != null;

  bool get isForkMaterialized => forkMaterializedAt != null;

  String identity() => id;

  bool hasWorkspace() => workspaceId.isNotEmpty;

  bool isPinnedConversation() => isPinned;
}

@freezed
abstract class const ConversationToCreate._() with _$ConversationToCreate {
  const factory({
    /// Human-readable title of the conversation.
    required String title,

    /// ID of the workspace this conversation belongs to.
    required String workspaceId,

    /// ID of the AI model used for this conversation.
    String? modelId,

    /// ID of the selected agent used for this conversation.
    String? agentId,

    /// Conversation-scoped reasoning override. Null uses provider defaults.
    ReasoningConfiguration? reasoningConfiguration,

    /// Parent conversation id for hidden child/sub-agent conversations.
    String? parentConversationId,

    /// Whether this conversation is pinned.
    bool? isPinned,
  }) = _ConversationToCreate;

  /// Returns true if the conversation has a valid title.
  bool get hasValidTitle => title.isNotEmpty;

  /// Returns true if the conversation is in a valid state.
  bool get isValid {
    final modelId = this.modelId;
    final agentId = this.agentId;
    final parentConversationId = this.parentConversationId;

    return hasValidTitle &&
        workspaceId.isNotEmpty &&
        (modelId == null || modelId.isNotEmpty) &&
        (agentId == null || agentId.isNotEmpty) &&
        (parentConversationId == null || parentConversationId.isNotEmpty);
  }

  bool hasModel() => modelId != null;

  bool hasAgent() => agentId != null;

  bool hasParent() => parentConversationId != null;
}

@freezed
abstract class const ConversationPatch._() with _$ConversationPatch {
  const factory({
    /// Human-readable title of the conversation.
    String? title,

    /// ID of the AI model used for this conversation.
    String? modelId,

    /// ID of the selected agent used for this conversation.
    String? agentId,

    /// Conversation-scoped reasoning override. Null uses provider defaults.
    ReasoningConfiguration? reasoningConfiguration,

    /// Active compaction checkpoint, if one was restored.
    String? activeCompactionCheckpointId,
    @Default(false) bool clearActiveCompactionCheckpointId,

    /// Clears [agentId]. Nullable Freezed fields cannot express null set.
    @Default(false) bool clearAgent,

    /// Clears [reasoningConfiguration] and restores provider defaults.
    @Default(false) bool clearReasoningConfiguration,

    /// Whether this conversation is pinned.
    bool? isPinned,
  }) = _ConversationPatch;
  bool get isValid => _hasValidValues && _hasChanges;

  bool get _hasValidValues =>
      _isNullOrNonEmpty(title) &&
      _isNullOrNonEmpty(modelId) &&
      _isNullOrNonEmpty(agentId) &&
      (!clearAgent || agentId == null) &&
      (!clearActiveCompactionCheckpointId ||
          activeCompactionCheckpointId == null) &&
      _isNullOrNonEmpty(activeCompactionCheckpointId);

  bool get _hasChanges =>
      title != null ||
      modelId != null ||
      agentId != null ||
      clearAgent ||
      reasoningConfiguration != null ||
      clearReasoningConfiguration ||
      isPinned != null ||
      clearActiveCompactionCheckpointId ||
      activeCompactionCheckpointId != null;

  bool hasChanges() => _hasChanges;

  bool hasValidValues() => _hasValidValues;
}

bool _isNullOrNonEmpty(String? value) => value == null || value.isNotEmpty;

abstract final class ConversationLimits {
  static const maxPinnedPerWorkspace = 10;

  static bool hasPinnedCapacity(Iterable<ConversationEntity> conversations) =>
      conversations.where((conversation) => conversation.isPinned).length <
      maxPinnedPerWorkspace;
}

class const ConversationPinLimitException(final String workspaceId)
    implements Exception {
  @override
  String toString() =>
      'ConversationPinLimitException: workspace $workspaceId has reached '
      'the pinned conversation limit';
}
