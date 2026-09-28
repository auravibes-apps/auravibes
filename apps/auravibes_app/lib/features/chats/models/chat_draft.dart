import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';

import 'package:auravibes_app/features/chats/models/chat_draft_intent.dart';

export 'package:auravibes_app/features/chats/models/chat_draft_intent.dart';

class const ChatDraft({
  required final String text,
  final List<MessageAttachmentToCreate> attachments = const [],
  final String? metadataJson,
  final ChatDraftIntent intent = .message,
  final String? targetMessageId,
}) {
  String? get metadataJsonForPersistence {
    if (intent == .message) return metadataJson;

    final metadata =
        MessageMetadataEntity.fromJsonString(metadataJson) ??
        const MessageMetadataEntity();

    return jsonEncode(
      metadata
          .copyWith(
            modelMetadata: {
              ...metadata.modelMetadata,
              MessageMetadataEntity.chatMessageIntentMetadataKey: intent.name,
              MessageMetadataEntity.chatMessageTargetIdMetadataKey:
                  ?targetMessageId,
            },
          )
          .toJson(),
    );
  }

  bool get isEmpty => text.trim().isEmpty && attachments.isEmpty;

  bool hasAttachments() => attachments.isNotEmpty;
}
