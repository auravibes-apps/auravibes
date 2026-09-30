import 'dart:convert';

import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/entities/tools_group_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_transcript_context_codec.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_transcript_context_decode_exception.dart';
import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AgentTranscriptContextUpdate, foldAgentTranscriptContext;
import 'package:uuid/v7.dart';

class const ConversationArchiveUsecase({
  required final ConversationRepository conversationRepository,
  required final MessageRepository messageRepository,
  required final LocalChatAttachmentService attachmentService,
  required final ConversationToolsRepository conversationToolsRepository,
  required final WorkspaceToolsRepository workspaceToolsRepository,
  required final ToolsGroupsRepository toolsGroupsRepository,
  final AttachmentFileStore attachmentFileStore = const AttachmentFileStore(),
}) {
  Future<String> exportConversation({
    required String conversationId,
    String? modelLabel,
  }) async {
    final conversation = await conversationRepository.getConversationById(
      conversationId,
    );
    if (conversation == null) throw StateError('Conversation not found');

    return await _exportConversation(
      conversation: conversation,
      modelLabel: modelLabel,
    );
  }

  Future<String> exportConversations({
    required String workspaceId,
    required List<String> conversationIds,
  }) async {
    if (conversationIds.isEmpty ||
        conversationIds.length > ConversationArchiveCodec.maxConversations) {
      throw const MalformedConversationArchiveException();
    }
    final archives = <ConversationArchive>[];
    for (final id in conversationIds) {
      final conversation = await conversationRepository.getConversationById(id);
      if (conversation == null || conversation.workspaceId != workspaceId) {
        throw const MalformedConversationArchiveException();
      }
      archives.add(await _createArchive(conversation));
    }

    return ConversationArchiveCodec.encodeMany(archives);
  }

  Future<ConversationEntity> importConversation({
    required String workspaceId,
    required String archiveJson,
  }) async {
    final archives = ConversationArchiveCodec.decodeMany(archiveJson);
    if (archives.length != 1) {
      throw const MalformedConversationArchiveException();
    }

    return (await _importArchives(workspaceId, archives)).single;
  }

  Future<List<ConversationEntity>> importArchive({
    required String workspaceId,
    required String archiveJson,
  }) {
    try {
      return _importArchives(
        workspaceId,
        ConversationArchiveCodec.decodeMany(archiveJson),
      );
    } on Object catch (error, stackTrace) {
      return Future<List<ConversationEntity>>.error(error, stackTrace);
    }
  }

  Future<String> _exportConversation({
    required ConversationEntity conversation,
    String? modelLabel,
  }) async => ConversationArchiveCodec.encode(
    await _createArchive(conversation, modelLabel: modelLabel),
  );

  Future<ConversationArchive> _createArchive(
    ConversationEntity conversation, {
    String? modelLabel,
  }) async {
    final transcript = await messageRepository
        .getTranscriptMessagesByConversation(conversation.id);
    final agentContext = await _archiveAgentContext(conversation, transcript);

    return await ConversationArchiveCodec.createConversationArchive(
      conversation: conversation,
      messages: transcript
          .where((message) => !message.isAgentTranscriptContextUpdate)
          .toList(growable: false),
      modelLabel: modelLabel,
      agentContext: agentContext,
      readAttachmentBytes: attachmentService.readAttachmentBytes,
    );
  }

  Future<ConversationArchiveAgentContext> _archiveAgentContext(
    ConversationEntity conversation,
    List<MessageEntity> transcript,
  ) async {
    final selections = await _archiveToolSelections(conversation);
    final entries = <ConversationArchiveAgentContextEntry>[];
    final updates = <AgentTranscriptContextUpdate>[];
    var visibleIndex = -1;
    var contextComplete = true;
    for (final message in transcript) {
      if (!message.isAgentTranscriptContextUpdate) {
        visibleIndex++;
        continue;
      }
      try {
        final update = AgentTranscriptContextCodec.decodeUpdate(
          message.content,
        );
        updates.add(update);
        entries.add(
          ConversationArchiveAgentContextEntry(
            afterMessageIndex: visibleIndex < 0 ? null : visibleIndex,
            createdAt: message.createdAt,
            updateJson: AgentTranscriptContextCodec.encodeUpdate(update),
          ),
        );
      } on Object {
        contextComplete = false;
        break;
      }
    }
    if (contextComplete) {
      try {
        final _ = foldAgentTranscriptContext(updates);
      } on Object {
        contextComplete = false;
      }
    }
    contextComplete = contextComplete && selections.isComplete;

    return ConversationArchiveAgentContext(
      isComplete: contextComplete,
      entriesInput: contextComplete ? entries : const [],
      toolSelectionsInput: selections.selections,
    );
  }

  Future<({List<ConversationArchiveToolSelection> selections, bool isComplete})>
  _archiveToolSelections(ConversationEntity conversation) async {
    final settings = await conversationToolsRepository.getConversationTools(
      conversation.id,
    );
    if (settings.isEmpty) {
      return (
        selections: const <ConversationArchiveToolSelection>[],
        isComplete: true,
      );
    }

    final tools = await workspaceToolsRepository.getWorkspaceTools(
      conversation.workspaceId,
    );
    final groups = await toolsGroupsRepository.getToolsGroupsForWorkspace(
      conversation.workspaceId,
    );
    final groupNames = {for (final group in groups) group.id: group.name};
    final selections = <ConversationArchiveToolSelection>[];
    var isComplete = true;
    for (final setting in settings) {
      final toolIndex = tools.indexWhere((item) => item.id == setting.toolId);
      if (toolIndex < 0) {
        isComplete = false;
        continue;
      }
      final tool = tools[toolIndex];
      final groupId = tool.workspaceToolsGroupId;
      final groupName = groupId == null ? null : groupNames[groupId];
      if (groupId != null && (groupName == null || groupName.isEmpty)) {
        isComplete = false;
        continue;
      }
      selections.add(
        ConversationArchiveToolSelection(
          groupName: groupName,
          toolName: tool.toolId,
          isEnabled: setting.isEnabled,
          permissionMode: setting.permissionMode,
        ),
      );
    }

    return (selections: selections, isComplete: isComplete);
  }

  Future<List<ConversationEntity>> _importArchives(
    String workspaceId,
    List<ConversationArchive> archives,
  ) async {
    if (workspaceId.isEmpty) throw ArgumentError.value(workspaceId);
    final updatesByArchive = [
      for (final archive in archives) _decodeContextUpdates(archive),
    ];
    final needsWorkspaceTools = archives.any(
      (archive) => archive.agentContext?.toolSelections.isNotEmpty ?? false,
    );
    final workspaceTools = needsWorkspaceTools
        ? await workspaceToolsRepository.getWorkspaceTools(workspaceId)
        : const <WorkspaceToolEntity>[];
    final groups = needsWorkspaceTools
        ? await toolsGroupsRepository.getToolsGroupsForWorkspace(workspaceId)
        : const <ToolsGroupEntity>[];
    final groupNames = {for (final group in groups) group.id: group.name};
    final selectionsByArchive = [
      for (final archive in archives)
        _resolveToolSelections(
          archive.agentContext?.toolSelections ?? const [],
          workspaceTools,
          groupNames,
        ),
    ];

    final stagedAttachments = <MessageAttachmentToCreate>[];
    final persistedAttachmentPaths = <String>[];
    try {
      final attachmentsByArchive = [
        for (final archive in archives)
          await _stageAttachments(archive.messages, stagedAttachments),
      ];
      final imported = <ConversationEntity>[];
      await conversationRepository.inTransaction(() async {
        for (var index = 0; index < archives.length; index++) {
          final archive = archives[index];
          final conversation = await _createImportedConversation(
            archive,
            workspaceId,
          );
          imported.add(conversation);
          await _importMessagesAndContext(
            archive: archive,
            conversationId: conversation.id,
            attachments: attachmentsByArchive[index],
            updates: updatesByArchive[index],
            persistedAttachmentPaths: persistedAttachmentPaths,
          );
          for (final selection in selectionsByArchive[index]) {
            final _ = await conversationToolsRepository
                .setConversationToolEnabled(
                  conversation.id,
                  selection.workspaceToolId,
                  isEnabled: selection.selection.isEnabled,
                );
            final _ = await conversationToolsRepository
                .setConversationToolPermission(
                  conversation.id,
                  selection.workspaceToolId,
                  permissionMode: selection.selection.permissionMode,
                );
          }
        }
      });

      return imported;
    } on Object catch (error, stackTrace) {
      await _deleteAttachmentPaths(persistedAttachmentPaths);
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      await _deleteStagedAttachments(stagedAttachments);
    }
  }

  List<AgentTranscriptContextUpdate> _decodeContextUpdates(
    ConversationArchive archive,
  ) {
    final context = archive.agentContext;
    if (context == null || !context.isComplete) return const [];
    try {
      final updates = [
        for (final entry in context.entries)
          AgentTranscriptContextCodec.decodeUpdate(entry.updateJson),
      ];
      final _ = foldAgentTranscriptContext(updates);

      return updates;
    } on UnsupportedTranscriptVersionException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        UnsupportedArchiveVersionException(error.version),
        stackTrace,
      );
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        const MalformedConversationArchiveException(),
        stackTrace,
      );
    }
  }

  List<_SelectionRestore> _resolveToolSelections(
    List<ConversationArchiveToolSelection> selections,
    List<WorkspaceToolEntity> workspaceTools,
    Map<String, String> groupNames,
  ) {
    final resolved = <_SelectionRestore>[];
    for (final selection in selections) {
      final restore = _resolveToolSelection(
        selection,
        workspaceTools,
        groupNames,
      );
      if (restore != null) resolved.add(restore);
    }

    return resolved;
  }

  _SelectionRestore? _resolveToolSelection(
    ConversationArchiveToolSelection selection,
    List<WorkspaceToolEntity> workspaceTools,
    Map<String, String> groupNames,
  ) {
    final matches = workspaceTools.where((tool) {
      if (tool.toolId != selection.toolName) return false;
      final groupId = tool.workspaceToolsGroupId;
      if (selection.groupName == null) return groupId == null;

      return groupId != null && groupNames[groupId] == selection.groupName;
    }).toList();
    if (matches.length > 1) {
      throw const MalformedConversationArchiveException();
    }
    if (matches.isEmpty) return null;

    return (selection: selection, workspaceToolId: matches.single.id);
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

  Future<void> _importMessagesAndContext({
    required ConversationArchive archive,
    required String conversationId,
    required List<List<MessageAttachmentToCreate>> attachments,
    required List<AgentTranscriptContextUpdate> updates,
    required List<String> persistedAttachmentPaths,
  }) async {
    final messages = archive.messages;
    final entries = switch (archive.agentContext) {
      final context? when context.isComplete => context.entries,
      _ => const <ConversationArchiveAgentContextEntry>[],
    };
    final importedMessageIds = <String>[];
    var contextIndex = 0;
    while (contextIndex < entries.length &&
        entries[contextIndex].afterMessageIndex == null) {
      await _importContextEntry(
        entries[contextIndex],
        updates[contextIndex],
        conversationId,
      );
      contextIndex++;
    }
    for (var index = 0; index < messages.length; index++) {
      final imported = await _importMessage(
        messages[index],
        conversationId,
        attachments[index],
        importedMessageIds,
      );
      importedMessageIds.add(imported.id);
      persistedAttachmentPaths.addAll(
        imported.attachments.map((attachment) => attachment.localPath),
      );
      while (contextIndex < entries.length &&
          entries[contextIndex].afterMessageIndex == index) {
        await _importContextEntry(
          entries[contextIndex],
          updates[contextIndex],
          conversationId,
        );
        contextIndex++;
      }
    }
    if (archive.agentContext case final context? when !context.isComplete) {
      await _importIncompleteContextSentinel(archive, conversationId);
    }
  }

  Future<MessageEntity> _importMessage(
    ConversationArchiveMessage message,
    String conversationId,
    List<MessageAttachmentToCreate> attachments,
    List<String> importedMessageIds,
  ) => messageRepository.createMessage(
    _toImportedMessage(
      message,
      conversationId,
      attachments,
      importedMessageIds,
    ),
  );

  Future<void> _importContextEntry(
    ConversationArchiveAgentContextEntry entry,
    AgentTranscriptContextUpdate update,
    String conversationId,
  ) async {
    final _ = await messageRepository.createMessage(
      _contextMessage(
        conversationId: conversationId,
        content: AgentTranscriptContextCodec.encodeUpdate(update),
        createdAt: entry.createdAt,
      ),
    );
  }

  Future<void> _importIncompleteContextSentinel(
    ConversationArchive archive,
    String conversationId,
  ) async {
    final createdAt = archive.messages.isEmpty
        ? archive.updatedAt
        : archive.messages.last.createdAt;
    final _ = await messageRepository.createMessage(
      _contextMessage(
        conversationId: conversationId,
        content: '{"version":1}',
        createdAt: createdAt,
      ),
    );
  }

  MessageToCreate _contextMessage({
    required String conversationId,
    required String content,
    required DateTime createdAt,
  }) => MessageToCreate(
    conversationId: conversationId,
    content: content,
    messageType: .system,
    isUser: false,
    status: .sent,
    createdAt: createdAt,
    updatedAt: createdAt,
    metadata: jsonEncode(
      const MessageMetadataEntity(
        modelMetadata: {
          MessageMetadataEntity.agentTranscriptContextMetadataKey: true,
        },
      ).toJson(),
    ),
  );

  Future<void> _deleteStagedAttachments(
    List<MessageAttachmentToCreate> attachments,
  ) async {
    for (final attachment in attachments) {
      try {
        await attachmentService.deleteAttachment(attachment.localPath);
      } on Object {
        // Keep the import result while attempting cleanup for every file.
      }
    }
  }

  Future<void> _deleteAttachmentPaths(List<String> paths) async {
    for (final path in paths) {
      try {
        await attachmentFileStore.deleteFile(path);
      } on Object {
        // Keep original import failure while attempting cleanup for each file.
      }
    }
  }
}

typedef _SelectionRestore = ({
  ConversationArchiveToolSelection selection,
  String workspaceToolId,
});

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
