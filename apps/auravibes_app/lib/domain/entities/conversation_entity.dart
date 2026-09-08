// Required: Existing test and UI helpers keep compact return flow.

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

    /// Parent conversation id for hidden child/sub-agent conversations.
    String? parentConversationId,
  }) = _ConversationEntity;

  /// Returns true if the conversation has a valid title.
  bool get hasValidTitle => title.isNotEmpty;

  /// Returns true if the conversation is in a valid state.
  bool get isValid {
    return hasValidTitle && workspaceId.isNotEmpty;
  }
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

    /// Clears [agentId]. Nullable Freezed fields cannot express null set.
    @Default(false) bool clearAgent,

    /// Whether this conversation is pinned.
    bool? isPinned,
  }) = _ConversationPatch;
  bool get isValid {
    final title = this.title;
    if (title != null && title.isEmpty) return false;

    final modelId = this.modelId;
    if (modelId != null && modelId.isEmpty) return false;

    final agentId = this.agentId;
    if (agentId != null && agentId.isEmpty) return false;

    if (clearAgent && agentId != null) return false;

    return title != null ||
        modelId != null ||
        agentId != null ||
        clearAgent ||
        isPinned != null;
  }
}
