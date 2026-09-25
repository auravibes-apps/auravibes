import 'dart:convert';

import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:uuid/v7.dart';

class const ConversationArchiveUsecase({
  required final ConversationRepository conversationRepository,
  required final MessageRepository messageRepository,
  required final LocalChatAttachmentService attachmentService,
}) {
  Future<String> exportConversation({
    required String conversationId,
    String? modelLabel,
  }) async {
    final conversation = await conversationRepository.getConversationById(
      conversationId,
    );
    if (conversation == null) throw StateError('Conversation not found');

    return await ConversationArchiveCodec.exportConversation(
      conversation: conversation,
      messages: await messageRepository.getMessagesByConversation(
        conversationId,
      ),
      modelLabel: modelLabel,
      readAttachmentBytes: attachmentService.readAttachmentBytes,
    );
  }

  Future<ConversationEntity> importConversation({
    required String workspaceId,
    required String archiveJson,
  }) async {
    final archive = ConversationArchiveCodec.decode(archiveJson);
    if (workspaceId.isEmpty) throw ArgumentError.value(workspaceId);

    return await _importArchive(archive, workspaceId);
  }

  Future<ConversationEntity> _importArchive(
    ConversationArchive archive,
    String workspaceId,
  ) async {
    final stagedAttachments = <MessageAttachmentToCreate>[];
    try {
      final attachments = await _stageAttachments(
        archive.messages,
        stagedAttachments,
      );
      final conversation = await _createImportedConversation(
        archive,
        workspaceId,
      );
      await _importMessages(archive.messages, conversation.id, attachments);

      return conversation;
    } finally {
      await _deleteStagedAttachments(stagedAttachments);
    }
  }

  Future<List<List<MessageAttachmentToCreate>>> _stageAttachments(
    List<ConversationArchiveMessage> messages,
    List<MessageAttachmentToCreate> staged,
  ) async {
    final byMessage = <List<MessageAttachmentToCreate>>[];
    for (final message in messages) {
      byMessage.add(
        await _stageMessageAttachments(message.attachments, staged),
      );
    }

    return byMessage;
  }

  Future<List<MessageAttachmentToCreate>> _stageMessageAttachments(
    List<ConversationArchiveAttachment> attachments,
    List<MessageAttachmentToCreate> staged,
  ) async {
    final result = <MessageAttachmentToCreate>[];
    for (final attachment in attachments) {
      final created = await attachmentService.createArchiveAttachment(
        attachment,
      );
      staged.add(created);
      result.add(created);
    }

    return result;
  }

  Future<ConversationEntity> _createImportedConversation(
    ConversationArchive archive,
    String workspaceId,
  ) => conversationRepository.createConversation(
    .new(
      title: archive.title,
      workspaceId: workspaceId,
      createdAt: archive.createdAt,
      updatedAt: archive.updatedAt,
    ),
  );

  Future<void> _importMessages(
    List<ConversationArchiveMessage> messages,
    String conversationId,
    List<List<MessageAttachmentToCreate>> attachments,
  ) async {
    final importedMessageIds = <String>[];
    for (var index = 0; index < messages.length; index++) {
      final importedId = await _importMessage(
        messages[index],
        conversationId,
        attachments[index],
        importedMessageIds,
      );
      importedMessageIds.add(importedId);
    }
  }

  Future<String> _importMessage(
    ConversationArchiveMessage message,
    String conversationId,
    List<MessageAttachmentToCreate> attachments,
    List<String> importedMessageIds,
  ) async {
    final created = await messageRepository.createMessage(
      _toImportedMessage(
        message,
        conversationId,
        attachments,
        importedMessageIds,
      ),
    );

    return created.id;
  }

  Future<void> _deleteStagedAttachments(
    List<MessageAttachmentToCreate> attachments,
  ) async {
    for (final attachment in attachments) {
      await attachmentService.deleteAttachment(attachment.localPath);
    }
  }
}

MessageToCreate _toImportedMessage(
  ConversationArchiveMessage message,
  String conversationId,
  List<MessageAttachmentToCreate> attachments,
  List<String> importedMessageIds,
) => MessageToCreate(
  conversationId: conversationId,
  content: message.content,
  messageType: message.messageType,
  isUser: message.isUser,
  status: _restoredMessageStatus(message.status),
  createdAt: message.createdAt,
  updatedAt: message.createdAt,
  metadata: _encodedRestoredMetadata(message.metadata, importedMessageIds),
  attachments: attachments,
);

String _encodedRestoredMetadata(
  ConversationArchiveMetadata metadata,
  List<String> importedMessageIds,
) => jsonEncode(_restoreMetadata(metadata, importedMessageIds).toJson());

MessageStatus _restoredMessageStatus(MessageStatus status) => switch (status) {
  .sending || .unfinished => .error,
  _ => status,
};

MessageMetadataEntity _restoreMetadata(
  ConversationArchiveMetadata metadata,
  List<String> importedMessageIds,
) => _restoreMetadataCompaction(
  _restoreMetadataContent(metadata),
  metadata,
  importedMessageIds,
);

MessageMetadataEntity _restoreMetadataContent(
  ConversationArchiveMetadata metadata,
) => const MessageMetadataEntity().copyWith(
  toolCalls: _restoreToolCalls(metadata.toolCalls),
  promptTokens: metadata.promptTokens,
  completionTokens: metadata.completionTokens,
  totalTokens: metadata.totalTokens,
  modelMetadata: _restoreModelMetadata(metadata),
  a2uiMessages: metadata.a2uiMessages,
  isCompactionSummary: metadata.isCompactionSummary,
);

List<MessageToolCallEntity> _restoreToolCalls(
  List<ConversationArchiveToolCall> toolCalls,
) => [
  for (final toolCall in toolCalls)
    MessageToolCallEntity(
      id: const UuidV7().generate(),
      name: toolCall.displayName ?? 'archived_tool',
      argumentsRaw: '',
      userFacingDescription: toolCall.displayName,
      resultStatus: _restoredToolCallStatus(toolCall.resultStatus),
    ),
];

Map<String, Object?> _restoreModelMetadata(
  ConversationArchiveMetadata metadata,
) => {
  'providerError': ?metadata.providerError,
  'a2uiRequiresUserAction': ?metadata.a2uiRequiresUserAction,
};

MessageMetadataEntity _restoreMetadataCompaction(
  MessageMetadataEntity restored,
  ConversationArchiveMetadata metadata,
  List<String> importedMessageIds,
) => restored.copyWith(
  compactionKind: metadata.compactionKind,
  compactedFromMessageId: _messageIdAt(
    metadata.compactedFromMessageIndex,
    importedMessageIds,
  ),
  compactedThroughMessageId: _messageIdAt(
    metadata.compactedThroughMessageIndex,
    importedMessageIds,
  ),
  compactedMessageIds: [
    for (final index in metadata.compactedMessageIndexes)
      importedMessageIds[index],
  ],
  compactionCreatedAt: metadata.compactionCreatedAt,
);

String? _messageIdAt(int? index, List<String> messageIds) =>
    index == null ? null : messageIds[index];

ToolCallResultStatus _restoredToolCallStatus(ToolCallResultStatus? status) =>
    switch (status) {
      null || .running => .skippedByUser,
      _ => status,
    };
