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

    final stagedAttachments = <MessageAttachmentToCreate>[];
    final attachmentsByMessage = <List<MessageAttachmentToCreate>>[];
    try {
      for (final message in archive.messages) {
        final attachments = <MessageAttachmentToCreate>[];
        for (final attachment in message.attachments) {
          final staged = await attachmentService.createArchiveAttachment(
            attachment,
          );
          attachments.add(staged);
          stagedAttachments.add(staged);
        }
        attachmentsByMessage.add(attachments);
      }

      final conversation = await conversationRepository.createConversation(
        .new(
          title: archive.title,
          workspaceId: workspaceId,
          createdAt: archive.createdAt,
          updatedAt: archive.updatedAt,
        ),
      );
      final importedMessageIds = <String>[];
      for (var index = 0; index < archive.messages.length; index++) {
        final message = archive.messages[index];
        final metadata = _restoreMetadata(message.metadata, importedMessageIds);
        final created = await messageRepository.createMessage(
          .new(
            conversationId: conversation.id,
            content: message.content,
            messageType: message.messageType,
            isUser: message.isUser,
            status: _restoredMessageStatus(message.status),
            createdAt: message.createdAt,
            updatedAt: message.createdAt,
            metadata: jsonEncode(metadata.toJson()),
            attachments: attachmentsByMessage[index],
          ),
        );
        importedMessageIds.add(created.id);
      }

      return conversation;
    } finally {
      for (final attachment in stagedAttachments) {
        await attachmentService.deleteAttachment(attachment.localPath);
      }
    }
  }
}

MessageStatus _restoredMessageStatus(MessageStatus status) => switch (status) {
  .sending || .unfinished => .error,
  _ => status,
};

MessageMetadataEntity _restoreMetadata(
  ConversationArchiveMetadata metadata,
  List<String> importedMessageIds,
) => MessageMetadataEntity(
  toolCalls: [
    for (final toolCall in metadata.toolCalls)
      .new(
        id: const UuidV7().generate(),
        name: toolCall.displayName ?? 'archived_tool',
        argumentsRaw: '',
        userFacingDescription: toolCall.displayName,
        resultStatus: _restoredToolCallStatus(toolCall.resultStatus),
      ),
  ],
  promptTokens: metadata.promptTokens,
  completionTokens: metadata.completionTokens,
  totalTokens: metadata.totalTokens,
  modelMetadata: {
    'providerError': ?metadata.providerError,
    'a2uiRequiresUserAction': ?metadata.a2uiRequiresUserAction,
  },
  a2uiMessages: metadata.a2uiMessages,
  isCompactionSummary: metadata.isCompactionSummary,
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
