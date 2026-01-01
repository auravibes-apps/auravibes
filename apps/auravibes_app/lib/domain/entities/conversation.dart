import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';

/// Entity representing a conversation in the Aura application.
///
/// A conversation is a container for organizing and managing
/// chat messages within a specific workspace.
///
@freezed
abstract class ConversationEntity with _$ConversationEntity {
  const factory ConversationEntity({
    /// Unique identifier for the conversation
    required String id,

    /// Human-readable title of the conversation
    required String title,

    /// ID of the workspace this conversation belongs to
    required String workspaceId,

    /// Whether this conversation is pinned
    required bool isPinned,

    /// Timestamp when the conversation was created
    required DateTime createdAt,

    /// Timestamp when the conversation was last updated
    required DateTime updatedAt,

    /// ID of the AI model used for this conversation
    String? modelId,
  }) = _ConversationEntity;
  const ConversationEntity._();

  /// Returns true if the conversation has a valid title
  bool get hasValidTitle => title.isNotEmpty;

  /// Returns true if the conversation is in a valid state
  bool get isValid {
    return hasValidTitle && workspaceId.isNotEmpty;
  }
}

@freezed
abstract class ConversationToCreate with _$ConversationToCreate {
  const factory ConversationToCreate({
    /// Human-readable title of the conversation
    required String title,

    /// ID of the workspace this conversation belongs to
    required String workspaceId,

    /// ID of the AI model used for this conversation
    String? modelId,

    /// Whether this conversation is pinned
    bool? isPinned,
  }) = _ConversationToCreate;
  const ConversationToCreate._();

  /// Returns true if the conversation has a valid title
  bool get hasValidTitle => title.isNotEmpty;

  /// Returns true if the conversation is in a valid state
  bool get isValid {
    return hasValidTitle && workspaceId.isNotEmpty;
  }
}

@freezed
abstract class ConversationToUpdate with _$ConversationToUpdate {
  const factory ConversationToUpdate({
    /// Human-readable title of the conversation
    String? title,

    /// ID of the AI model used for this conversation
    String? modelId,

    /// Whether this conversation is pinned
    bool? isPinned,
  }) = _ConversationToUpdate;
  const ConversationToUpdate._();

  bool get isValid {
    if (title != null && title!.isEmpty) return false;
    if (modelId != null && modelId!.isEmpty) return false;
    return title != null || modelId != null || isPinned != null;
  }
}
