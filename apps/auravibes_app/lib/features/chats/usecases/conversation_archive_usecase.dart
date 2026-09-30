import 'dart:convert';

import 'package:auravibes_app/data/repositories/attachment_file_store.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/message_repository.dart';
import 'package:auravibes_app/data/repositories/tools_groups_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/domain/entities/conversation_tool_entity.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_transcript_context_codec.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_transcript_context_decode_exception.dart';
import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AgentTranscriptContextUpdate, foldAgentTranscriptContext;
import 'package:uuid/v7.dart';

typedef _ArchivedContextUpdates = ({
  List<ConversationArchiveAgentContextEntry> entries,
  bool isComplete,
});

typedef _ArchiveToolSelectionResult = ({
  ConversationArchiveToolSelection? selection,
  bool isComplete,
});

typedef _ArchiveToolSelectionArchiveRequest = ({
  ConversationEntity conversation,
  ConversationToolsRepository conversationToolsRepository,
  WorkspaceToolsRepository workspaceToolsRepository,
  ToolsGroupsRepository toolsGroupsRepository,
});

typedef _ArchiveImportPreparation = ({
  List<List<AgentTranscriptContextUpdate>> updates,
  List<List<_SelectionRestore>> selections,
});

typedef _ArchiveWorkspaceTools = ({
  List<WorkspaceToolEntity> tools,
  Map<String, String> groupNames,
});

typedef _ArchivePersistenceRequest = ({
  ConversationArchive archive,
  String workspaceId,
  List<List<MessageAttachmentToCreate>> attachments,
  List<AgentTranscriptContextUpdate> updates,
  List<_SelectionRestore> selections,
  List<String> persistedAttachmentPaths,
});

typedef _ArchivePersistBatchRequest = ({
  List<ConversationArchive> archives,
  String workspaceId,
  _ArchiveImportPreparation preparation,
  List<List<List<MessageAttachmentToCreate>>> attachments,
  List<String> persistedAttachmentPaths,
});

typedef _ArchiveStageRequest = ({
  String workspaceId,
  List<ConversationArchive> archives,
  _ArchiveImportPreparation preparation,
  List<MessageAttachmentToCreate> stagedAttachments,
  List<String> persistedAttachmentPaths,
});

typedef _ArchiveAttachmentCleanupRequest = ({
  _ConversationArchiveAttachmentImporter attachmentImporter,
  List<MessageAttachmentToCreate> stagedAttachments,
  List<String> persistedAttachmentPaths,
  Future<List<ConversationEntity>> Function() action,
});

typedef _ArchiveMessageSequenceRequest = ({
  _ConversationArchiveTranscriptImporter importer,
  _ImportMessagesRequest request,
  List<ConversationArchiveAgentContextEntry> entries,
  List<String> importedMessageIds,
  int contextIndex,
});

typedef _ImportMessagesRequest = ({
  ConversationArchive archive,
  String conversationId,
  List<List<MessageAttachmentToCreate>> attachments,
  List<AgentTranscriptContextUpdate> updates,
  List<String> persistedAttachmentPaths,
});

typedef _ContextImportRequest = ({
  List<ConversationArchiveAgentContextEntry> entries,
  List<AgentTranscriptContextUpdate> updates,
  int startIndex,
  int? afterMessageIndex,
  String conversationId,
});

typedef _ArchiveMessageImportRequest = ({
  _ImportMessagesRequest request,
  int index,
  List<ConversationArchiveAgentContextEntry> entries,
  List<String> importedMessageIds,
  int contextIndex,
});

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
  }) => _ConversationArchiveExporter(
    this,
  ).exportConversation(conversationId: conversationId, modelLabel: modelLabel);

  Future<String> exportConversations({
    required String workspaceId,
    required List<String> conversationIds,
  }) => _ConversationArchiveExporter(this).exportConversations(
    workspaceId: workspaceId,
    conversationIds: conversationIds,
  );

  Future<ConversationEntity> importConversation({
    required String workspaceId,
    required String archiveJson,
  }) => _ConversationArchiveImporter(this)
      .importConversation(workspaceId: workspaceId, archiveJson: archiveJson);

  Future<List<ConversationEntity>> importArchive({
    required String workspaceId,
    required String archiveJson,
  }) =>
      _ConversationArchiveImporter(this)
          .importArchive(workspaceId: workspaceId, archiveJson: archiveJson);
}

class _ConversationArchiveExporter(ConversationArchiveUsecase usecase) {
  final ConversationRepository conversationRepository =
      usecase.conversationRepository;
  final MessageRepository messageRepository = usecase.messageRepository;
  final LocalChatAttachmentService attachmentService =
      usecase.attachmentService;
  final ConversationToolsRepository conversationToolsRepository =
      usecase.conversationToolsRepository;
  final WorkspaceToolsRepository workspaceToolsRepository =
      usecase.workspaceToolsRepository;
  final ToolsGroupsRepository toolsGroupsRepository =
      usecase.toolsGroupsRepository;

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
    _validateConversationIds(conversationIds);
    final archives = <ConversationArchive>[];
    for (final id in conversationIds) {
      archives.add(await _createWorkspaceArchive(id, workspaceId));
    }

    return ConversationArchiveCodec.encodeMany(archives);
  }

  Future<ConversationArchive> _createWorkspaceArchive(
    String conversationId,
    String workspaceId,
  ) async {
    final conversation = await conversationRepository.getConversationById(
      conversationId,
    );
    if (conversation == null || conversation.workspaceId != workspaceId) {
      throw const MalformedConversationArchiveException();
    }

    return await _createArchive(conversation);
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

    return await ConversationArchiveCodec.createConversationArchive((
      conversation: conversation,
      messages: _archiveVisibleMessages(transcript),
      modelLabel: modelLabel,
      agentContext: agentContext,
      readAttachmentBytes: attachmentService.readAttachmentBytes,
    ));
  }

  Future<ConversationArchiveAgentContext> _archiveAgentContext(
    ConversationEntity conversation,
    List<MessageEntity> transcript,
  ) async {
    final selections = await _archiveToolSelections((
      conversation: conversation,
      conversationToolsRepository: conversationToolsRepository,
      workspaceToolsRepository: workspaceToolsRepository,
      toolsGroupsRepository: toolsGroupsRepository,
    ));
    final context = _archiveTranscriptContext(transcript);
    final isComplete = context.isComplete && selections.isComplete;

    return ConversationArchiveAgentContext(
      isComplete: isComplete,
      entriesInput: isComplete ? context.entries : const [],
      toolSelectionsInput: selections.selections,
    );
  }
}

void _validateConversationIds(List<String> conversationIds) {
  if (conversationIds.isEmpty ||
      conversationIds.length > ConversationArchiveCodec.maxConversations) {
    throw const MalformedConversationArchiveException();
  }
}

List<MessageEntity> _archiveVisibleMessages(List<MessageEntity> transcript) =>
    transcript
        .where((message) => !message.isAgentTranscriptContextUpdate)
        .toList(growable: false);

_ArchivedContextUpdates _archiveTranscriptContext(
  List<MessageEntity> transcript,
) {
  final context = _decodeTranscriptContextEntries(transcript);
  if (!context.isComplete) return (entries: const [], isComplete: false);
  final isComplete = _hasValidTranscriptContext(context.updates);

  return (
    entries: isComplete ? context.entries : const [],
    isComplete: isComplete,
  );
}

typedef _TranscriptContextArchiveData = ({
  List<ConversationArchiveAgentContextEntry> entries,
  List<AgentTranscriptContextUpdate> updates,
  bool isComplete,
});

typedef _ArchivedTranscriptEntry = ({
  ConversationArchiveAgentContextEntry entry,
  AgentTranscriptContextUpdate update,
});

_TranscriptContextArchiveData _decodeTranscriptContextEntries(
  List<MessageEntity> transcript,
) {
  final archived = _collectTranscriptContextEntries(transcript);
  if (archived != null) return archived;

  return (entries: const [], updates: const [], isComplete: false);
}

_TranscriptContextArchiveData? _collectTranscriptContextEntries(
  List<MessageEntity> transcript,
) {
  final entries = <ConversationArchiveAgentContextEntry>[];
  final updates = <AgentTranscriptContextUpdate>[];
  var visibleIndex = -1;
  for (final message in transcript) {
    if (!message.isAgentTranscriptContextUpdate) {
      visibleIndex++;
      continue;
    }
    if (!_appendTranscriptMessage(message, visibleIndex, entries, updates)) {
      return null;
    }
  }

  return (entries: entries, updates: updates, isComplete: true);
}

bool _appendTranscriptMessage(
  MessageEntity message,
  int visibleIndex,
  List<ConversationArchiveAgentContextEntry> entries,
  List<AgentTranscriptContextUpdate> updates,
) {
  final archived = _archiveTranscriptEntry(message, visibleIndex);
  if (archived == null) return false;
  entries.add(archived.entry);
  updates.add(archived.update);

  return true;
}

_ArchivedTranscriptEntry? _archiveTranscriptEntry(
  MessageEntity message,
  int visibleIndex,
) {
  try {
    final update = AgentTranscriptContextCodec.decodeUpdate(message.content);

    return (
      entry: ConversationArchiveAgentContextEntry(
        afterMessageIndex: visibleIndex < 0 ? null : visibleIndex,
        createdAt: message.createdAt,
        updateJson: AgentTranscriptContextCodec.encodeUpdate(update),
      ),
      update: update,
    );
  } on Object {
    return null;
  }
}

bool _hasValidTranscriptContext(List<AgentTranscriptContextUpdate> updates) {
  try {
    final _ = foldAgentTranscriptContext(updates);

    return true;
  } on Object {
    return false;
  }
}

Future<({List<ConversationArchiveToolSelection> selections, bool isComplete})>
_archiveToolSelections(_ArchiveToolSelectionArchiveRequest request) =>
    _ConversationArchiveToolSelectionArchiver(request).archiveSelections();

class const _ConversationArchiveToolSelectionArchiver(
  final _ArchiveToolSelectionArchiveRequest request,
) {
  Future<({List<ConversationArchiveToolSelection> selections, bool isComplete})>
  archiveSelections() async {
    final conversation = request.conversation;
    final settings = await request.conversationToolsRepository
        .getConversationTools(conversation.id);
    if (settings.isEmpty) {
      return (
        selections: const <ConversationArchiveToolSelection>[],
        isComplete: true,
      );
    }
    final workspace = await _loadWorkspaceTools(conversation.workspaceId);

    return _archiveSettings(settings, workspace);
  }

  Future<_ArchiveWorkspaceTools> _loadWorkspaceTools(String workspaceId) async {
    final tools = await request.workspaceToolsRepository.getWorkspaceTools(
      workspaceId,
    );
    final groups = await request.toolsGroupsRepository
        .getToolsGroupsForWorkspace(workspaceId);

    return (
      tools: tools,
      groupNames: {for (final group in groups) group.id: group.name},
    );
  }
}

({List<ConversationArchiveToolSelection> selections, bool isComplete})
_archiveSettings(
  List<ConversationToolEntity> settings,
  _ArchiveWorkspaceTools workspace,
) => _archiveToolSelectionResults([
  for (final setting in settings)
    _archiveToolSelection(setting, workspace.tools, workspace.groupNames),
]);

_ArchiveToolSelectionResult _completeToolSelectionArchive(
  ConversationToolEntity setting,
  WorkspaceToolEntity tool,
  String? groupName,
) => (
  selection: ConversationArchiveToolSelection(
    groupName: groupName,
    toolName: tool.toolId,
    isEnabled: setting.isEnabled,
    permissionMode: setting.permissionMode,
  ),
  isComplete: true,
);

_ArchiveToolSelectionResult _archiveToolSelection(
  ConversationToolEntity setting,
  List<WorkspaceToolEntity> tools,
  Map<String, String> groupNames,
) {
  final tool = tools.where((item) => item.id == setting.toolId).firstOrNull;
  if (tool == null) return (selection: null, isComplete: false);

  return _archiveToolForGroup(setting, tool, groupNames);
}

_ArchiveToolSelectionResult _archiveToolForGroup(
  ConversationToolEntity setting,
  WorkspaceToolEntity tool,
  Map<String, String> groupNames,
) {
  final groupId = tool.workspaceToolsGroupId;
  final groupName = groupId == null ? null : groupNames[groupId];
  if (groupId != null && (groupName == null || groupName.isEmpty)) {
    return (selection: null, isComplete: false);
  }

  return _completeToolSelectionArchive(setting, tool, groupName);
}

({List<ConversationArchiveToolSelection> selections, bool isComplete})
_archiveToolSelectionResults(List<_ArchiveToolSelectionResult> results) => (
  selections: [for (final result in results) ?result.selection],
  isComplete: results.every((result) => result.isComplete),
);

class _ConversationArchiveImporter(ConversationArchiveUsecase usecase) {
  final ConversationRepository conversationRepository =
      usecase.conversationRepository;
  final _ConversationArchivePreparationImporter preparationImporter = .new(
    usecase,
  );
  final _ConversationArchiveAttachmentImporter attachmentImporter = .new(
    usecase,
  );
  final _ConversationArchiveMessageImporter messageImporter = .new(usecase);

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

  Future<List<ConversationEntity>> _importArchives(
    String workspaceId,
    List<ConversationArchive> archives,
  ) async {
    if (workspaceId.isEmpty) throw ArgumentError.value(workspaceId);
    final preparation = await preparationImporter.prepare(
      workspaceId,
      archives,
    );

    return await _stageAndPersistArchives(
      _archiveStageRequest(workspaceId, archives, preparation),
    );
  }

  Future<List<ConversationEntity>> _stageAndPersistArchives(
    _ArchiveStageRequest request,
  ) {
    return _runArchiveImportWithCleanup((
      attachmentImporter: attachmentImporter,
      stagedAttachments: request.stagedAttachments,
      persistedAttachmentPaths: request.persistedAttachmentPaths,
      action: () => _stageAndPersist(request),
    ));
  }

  Future<List<ConversationEntity>> _stageAndPersist(
    _ArchiveStageRequest request,
  ) async {
    final attachments = await attachmentImporter.stageArchiveAttachments(
      request.archives,
      request.stagedAttachments,
    );

    return await _persistStagedArchives((
      archives: request.archives,
      workspaceId: request.workspaceId,
      preparation: request.preparation,
      attachments: attachments,
      persistedAttachmentPaths: request.persistedAttachmentPaths,
    ));
  }

  Future<List<ConversationEntity>> _persistStagedArchives(
    _ArchivePersistBatchRequest request,
  ) => messageImporter.persistArchives(request);
}

_ArchiveStageRequest _archiveStageRequest(
  String workspaceId,
  List<ConversationArchive> archives,
  _ArchiveImportPreparation preparation,
) => (
  workspaceId: workspaceId,
  archives: archives,
  preparation: preparation,
  stagedAttachments: <MessageAttachmentToCreate>[],
  persistedAttachmentPaths: <String>[],
);

Future<List<ConversationEntity>> _runArchiveImportWithCleanup(
  _ArchiveAttachmentCleanupRequest request,
) async {
  try {
    return await _runArchiveImportWithFailureCleanup(request);
  } finally {
    await request.attachmentImporter.deleteStagedAttachments(
      request.stagedAttachments,
    );
  }
}

Future<List<ConversationEntity>> _runArchiveImportWithFailureCleanup(
  _ArchiveAttachmentCleanupRequest request,
) async {
  try {
    return await request.action();
  } on Object catch (error, stackTrace) {
    await request.attachmentImporter.deleteAttachmentPaths(
      request.persistedAttachmentPaths,
    );
    Error.throwWithStackTrace(error, stackTrace);
  }
}

typedef _ArchiveWorkspaceRequest = ({
  String workspaceId,
  List<ConversationArchive> archives,
  WorkspaceToolsRepository workspaceToolsRepository,
  ToolsGroupsRepository toolsGroupsRepository,
});

class _ConversationArchivePreparationImporter(
  ConversationArchiveUsecase usecase,
) {
  final WorkspaceToolsRepository workspaceToolsRepository =
      usecase.workspaceToolsRepository;
  final ToolsGroupsRepository toolsGroupsRepository =
      usecase.toolsGroupsRepository;

  Future<_ArchiveImportPreparation> prepare(
    String workspaceId,
    List<ConversationArchive> archives,
  ) async {
    final updates = _decodeArchiveUpdates(archives);
    final workspace = await _archiveWorkspaceTools((
      workspaceId: workspaceId,
      archives: archives,
      workspaceToolsRepository: workspaceToolsRepository,
      toolsGroupsRepository: toolsGroupsRepository,
    ));
    final selections = _resolveArchiveSelections(archives, workspace);

    return (updates: updates, selections: selections);
  }

  Future<_ArchiveWorkspaceTools> _archiveWorkspaceTools(
    _ArchiveWorkspaceRequest request,
  ) {
    final needsTools = request.archives.any(_archiveNeedsToolSelections);
    if (!needsTools) {
      return Future<_ArchiveWorkspaceTools>.value((
        tools: const <WorkspaceToolEntity>[],
        groupNames: const <String, String>{},
      ));
    }

    return _loadArchiveWorkspaceTools(request);
  }

  List<List<_SelectionRestore>> _resolveArchiveSelections(
    List<ConversationArchive> archives,
    _ArchiveWorkspaceTools workspace,
  ) => [
    for (final archive in archives)
      _resolveToolSelections(
        archive.agentContext?.toolSelections ?? const [],
        workspace.tools,
        workspace.groupNames,
      ),
  ];

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
    final matches = workspaceTools
        .where((tool) => _matchesToolSelection(tool, selection, groupNames))
        .toList();
    if (matches.length > 1) {
      throw const MalformedConversationArchiveException();
    }
    if (matches.isEmpty) return null;

    return (selection: selection, workspaceToolId: matches.single.id);
  }

  bool _matchesToolSelection(
    WorkspaceToolEntity tool,
    ConversationArchiveToolSelection selection,
    Map<String, String> groupNames,
  ) {
    if (tool.toolId != selection.toolName) return false;
    final groupId = tool.workspaceToolsGroupId;
    if (selection.groupName == null) return groupId == null;

    return groupId != null && groupNames[groupId] == selection.groupName;
  }
}

bool _archiveNeedsToolSelections(ConversationArchive archive) =>
    archive.agentContext?.toolSelections.isNotEmpty ?? false;

Future<_ArchiveWorkspaceTools> _loadArchiveWorkspaceTools(
  _ArchiveWorkspaceRequest request,
) async {
  final tools = await request.workspaceToolsRepository.getWorkspaceTools(
    request.workspaceId,
  );
  final groups = await request.toolsGroupsRepository.getToolsGroupsForWorkspace(
    request.workspaceId,
  );

  return (
    tools: tools,
    groupNames: {for (final group in groups) group.id: group.name},
  );
}

List<List<AgentTranscriptContextUpdate>> _decodeArchiveUpdates(
  List<ConversationArchive> archives,
) => [for (final archive in archives) _decodeContextUpdates(archive)];

List<AgentTranscriptContextUpdate> _decodeContextUpdates(
  ConversationArchive archive,
) {
  final context = archive.agentContext;
  if (context == null || !context.isComplete) return const [];

  return _decodeContextUpdatesWithErrorTranslation(context.entries);
}

List<AgentTranscriptContextUpdate> _decodeContextUpdatesWithErrorTranslation(
  List<ConversationArchiveAgentContextEntry> entries,
) {
  try {
    final updates = _decodeArchiveContextUpdates(entries);
    _validateArchiveContextUpdates(updates);

    return updates;
  } on UnsupportedTranscriptVersionException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      UnsupportedArchiveVersionException(error.version),
      stackTrace,
    );
  } on Object catch (_, stackTrace) {
    Error.throwWithStackTrace(
      const MalformedConversationArchiveException(),
      stackTrace,
    );
  }
}

List<AgentTranscriptContextUpdate> _decodeArchiveContextUpdates(
  List<ConversationArchiveAgentContextEntry> entries,
) => [
  for (final entry in entries)
    AgentTranscriptContextCodec.decodeUpdate(entry.updateJson),
];

void _validateArchiveContextUpdates(
  List<AgentTranscriptContextUpdate> updates,
) {
  final _ = foldAgentTranscriptContext(updates);
}

class _ConversationArchiveAttachmentImporter(
  ConversationArchiveUsecase usecase,
) {
  final LocalChatAttachmentService attachmentService =
      usecase.attachmentService;
  final AttachmentFileStore attachmentFileStore = usecase.attachmentFileStore;

  Future<List<List<List<MessageAttachmentToCreate>>>> stageArchiveAttachments(
    List<ConversationArchive> archives,
    List<MessageAttachmentToCreate> staged,
  ) async => [
    for (final archive in archives)
      await _stageAttachments(archive.messages, staged),
  ];

  Future<void> deleteStagedAttachments(
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

  Future<void> deleteAttachmentPaths(List<String> paths) async {
    for (final path in paths) {
      try {
        await attachmentFileStore.deleteFile(path);
      } on Object {
        // Keep original import failure while attempting cleanup for each file.
      }
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
}

class _ConversationArchiveMessageImporter(ConversationArchiveUsecase usecase) {
  final ConversationRepository conversationRepository =
      usecase.conversationRepository;
  final MessageRepository messageRepository = usecase.messageRepository;
  final ConversationToolsRepository conversationToolsRepository =
      usecase.conversationToolsRepository;
  final _ConversationArchiveTranscriptImporter transcriptImporter = .new(
    usecase.messageRepository,
  );

  Future<List<ConversationEntity>> persistArchives(
    _ArchivePersistBatchRequest request,
  ) =>
      conversationRepository.inTransaction(() => _persistArchiveBatch(request));

  Future<List<ConversationEntity>> _persistArchiveBatch(
    _ArchivePersistBatchRequest request,
  ) async {
    final imported = <ConversationEntity>[];
    for (var index = 0; index < request.archives.length; index++) {
      imported.add(
        await _persistArchive(_archivePersistenceRequest(request, index)),
      );
    }

    return imported;
  }

  _ArchivePersistenceRequest _archivePersistenceRequest(
    _ArchivePersistBatchRequest request,
    int index,
  ) => (
    archive: request.archives[index],
    workspaceId: request.workspaceId,
    attachments: request.attachments[index],
    updates: request.preparation.updates[index],
    selections: request.preparation.selections[index],
    persistedAttachmentPaths: request.persistedAttachmentPaths,
  );

  Future<ConversationEntity> _persistArchive(
    _ArchivePersistenceRequest request,
  ) async {
    final conversation = await _createImportedConversation(
      request.archive,
      request.workspaceId,
    );
    await _importMessagesAndContext((
      archive: request.archive,
      conversationId: conversation.id,
      attachments: request.attachments,
      updates: request.updates,
      persistedAttachmentPaths: request.persistedAttachmentPaths,
    ));
    await _restoreToolSelections(conversation.id, request.selections);

    return conversation;
  }

  Future<void> _restoreToolSelections(
    String conversationId,
    List<_SelectionRestore> selections,
  ) async {
    for (final selection in selections) {
      final _ = await conversationToolsRepository.setConversationToolEnabled(
        conversationId,
        selection.workspaceToolId,
        isEnabled: selection.selection.isEnabled,
      );
      final _ = await conversationToolsRepository.setConversationToolPermission(
        conversationId,
        selection.workspaceToolId,
        permissionMode: selection.selection.permissionMode,
      );
    }
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

  Future<void> _importMessagesAndContext(_ImportMessagesRequest request) =>
      transcriptImporter.importMessagesAndContext(request);
}

class const _ConversationArchiveTranscriptImporter(
  final MessageRepository messageRepository,
) {
  Future<void> importMessagesAndContext(_ImportMessagesRequest request) async {
    final entries = _completeContextEntries(request.archive.agentContext);
    await _importArchiveMessages(request, entries);
    await _importIncompleteContextIfNeeded(this, request);
  }

  Future<void> _importArchiveMessages(
    _ImportMessagesRequest request,
    List<ConversationArchiveAgentContextEntry> entries,
  ) async {
    final importedMessageIds = <String>[];
    final contextIndex = await _importLeadingContext(request, entries);
    await _importArchiveMessageSequence((
      importer: this,
      request: request,
      entries: entries,
      importedMessageIds: importedMessageIds,
      contextIndex: contextIndex,
    ));
  }

  Future<int> _importLeadingContext(
    _ImportMessagesRequest request,
    List<ConversationArchiveAgentContextEntry> entries,
  ) => _importContextEntriesAt((
    entries: entries,
    updates: request.updates,
    startIndex: 0,
    afterMessageIndex: null,
    conversationId: request.conversationId,
  ));

  Future<int> _importMessageAndFollowingContext(
    _ArchiveMessageImportRequest request,
  ) async {
    final messageRequest = request.request;
    final imported = await _importArchiveMessage(
      messageRequest,
      request.index,
      request.importedMessageIds,
    );
    _recordImportedArchiveMessage(request, messageRequest, imported);

    return await _importContextEntriesAt(
      _followingContextImportRequest(request, messageRequest),
    );
  }

  Future<int> _importContextEntriesAt(_ContextImportRequest request) async {
    var index = request.startIndex;
    while (index < request.entries.length &&
        request.entries[index].afterMessageIndex == request.afterMessageIndex) {
      await _importContextEntry(
        request.entries[index],
        request.updates[index],
        request.conversationId,
      );
      index++;
    }

    return index;
  }

  Future<MessageEntity> _importArchiveMessage(
    _ImportMessagesRequest request,
    int index,
    List<String> importedMessageIds,
  ) => _importMessage(
    request.archive.messages[index],
    request.conversationId,
    request.attachments[index],
    importedMessageIds,
  );

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
}

Future<void> _importArchiveMessageSequence(
  _ArchiveMessageSequenceRequest request,
) async {
  var contextIndex = request.contextIndex;
  final messageCount = request.request.archive.messages.length;
  for (var index = 0; index < messageCount; index++) {
    contextIndex = await request.importer._importMessageAndFollowingContext((
      request: request.request,
      index: index,
      entries: request.entries,
      importedMessageIds: request.importedMessageIds,
      contextIndex: contextIndex,
    ));
  }
}

Future<void> _importIncompleteContextIfNeeded(
  _ConversationArchiveTranscriptImporter importer,
  _ImportMessagesRequest request,
) async {
  final context = request.archive.agentContext;
  if (context == null || context.isComplete) return;
  await importer._importIncompleteContextSentinel(
    request.archive,
    request.conversationId,
  );
}

void _recordImportedArchiveMessage(
  _ArchiveMessageImportRequest request,
  _ImportMessagesRequest messageRequest,
  MessageEntity imported,
) {
  request.importedMessageIds.add(imported.id);
  messageRequest.persistedAttachmentPaths.addAll(
    imported.attachments.map((attachment) => attachment.localPath),
  );
}

_ContextImportRequest _followingContextImportRequest(
  _ArchiveMessageImportRequest request,
  _ImportMessagesRequest messageRequest,
) => (
  entries: request.entries,
  updates: messageRequest.updates,
  startIndex: request.contextIndex,
  afterMessageIndex: request.index,
  conversationId: messageRequest.conversationId,
);

List<ConversationArchiveAgentContextEntry> _completeContextEntries(
  ConversationArchiveAgentContext? context,
) => switch (context) {
  final value? when value.isComplete => value.entries,
  _ => const <ConversationArchiveAgentContextEntry>[],
};

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
