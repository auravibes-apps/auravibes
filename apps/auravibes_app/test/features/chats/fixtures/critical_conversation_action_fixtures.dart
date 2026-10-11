import 'dart:typed_data';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:auravibes_app/features/chats/models/conversation_archive.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/chats/services/local_chat_attachment_service.dart';
import 'package:auravibes_app/features/chats/usecases/batch_tool_approval_usecase.dart';
import 'package:auravibes_app/features/models/providers/recent_model_selections_notifier.dart';
import 'package:file_picker/file_picker.dart' as fp;

enum CriticalConversationAction {
  send,
  stop,
  retry,
  approve,
  skip,
  attach,
  selectModel,
}

class const CriticalConversationActionCase({
  required final CriticalConversationAction action,
  required final String availableWhen,
  required final String unavailableWhen,
});

const criticalConversationActions = <CriticalConversationAction>{
  .send,
  .stop,
  .retry,
  .approve,
  .skip,
  .attach,
  .selectModel,
};

const criticalConversationActionCases = <CriticalConversationActionCase>[
  .new(
    action: .send,
    availableWhen: 'the composer contains a message draft',
    unavailableWhen: 'the composer is empty',
  ),
  .new(
    action: .stop,
    availableWhen: 'a generation is active and has a stop callback',
    unavailableWhen: 'the conversation is idle',
  ),
  .new(
    action: .retry,
    availableWhen: 'the latest user message has failed and has valid content',
    unavailableWhen: 'the latest user message is already sent',
  ),
  .new(
    action: .approve,
    availableWhen: 'multiple pending tool calls can be approved together',
    unavailableWhen: 'the conversation has no pending tool calls',
  ),
  .new(
    action: .skip,
    availableWhen: 'multiple pending tool calls can be skipped together',
    unavailableWhen: 'the conversation has no pending tool calls',
  ),
  .new(
    action: .attach,
    availableWhen: 'the local workspace and model accept file input',
    unavailableWhen: 'the selected model does not accept file input',
  ),
  .new(
    action: .selectModel,
    availableWhen: 'the workspace has a configured model selection',
    unavailableWhen: 'the workspace has no configured model selections',
  ),
];

const criticalConversationWorkspaceId = 'ws-corpus';
const criticalConversationId = 'conversation-corpus';
const criticalConversationModelSelectionId = 'model-corpus';

const criticalConversationAttachment = MessageAttachmentToCreate(
  localPath: '/tmp/issue-954-brief.txt',
  fileName: 'brief.txt',
  displayName: 'brief.txt',
  mimeType: 'text/plain',
  modality: .file,
  sizeBytes: 12,
);

const criticalConversationPendingCalls = <PendingToolCall>[
  .new(
    toolCall: .new(
      id: 'tool-call-1',
      name: 'built_in_1_read_file',
      argumentsRaw: '{"input":"brief.txt"}',
    ),
    messageId: 'assistant-message-1',
  ),
  .new(
    toolCall: .new(
      id: 'tool-call-2',
      name: 'built_in_1_read_file',
      argumentsRaw: '{"input":"notes.txt"}',
    ),
    messageId: 'assistant-message-2',
  ),
];

MessageEntity criticalConversationUserMessage({
  required String id,
  required MessageStatus status,
}) => .new(
  id: id,
  conversationId: criticalConversationId,
  content: 'Retry this local fixture.',
  messageType: .text,
  isUser: true,
  status: status,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

WorkspaceModelSelectionWithConnectionEntity
criticalConversationModelSelection() => .new(
  workspaceModelSelection: .new(
    id: criticalConversationModelSelectionId,
    modelId: 'fixture-model',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    modelConnectionId: 'fixture-connection',
    modelName: 'Fixture Model',
    modalitiesInput: const ['text', 'file'],
  ),
  modelConnection: .new(
    id: 'fixture-connection',
    name: 'Local Fixture',
    modelId: 'openai',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    workspaceId: criticalConversationWorkspaceId,
    hasKey: true,
  ),
  modelsProvider: const .new(id: 'openai', name: 'OpenAI', type: .openai),
);

class CriticalConversationFilePicker extends fp.FilePickerPlatform {
  int pickCount = 0;

  @override
  Future<List<fp.PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    fp.FileType type = fp.FileType.any,
    List<String>? allowedExtensions,
    void Function(fp.FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    fp.AndroidOptions androidOptions = const fp.AndroidOptions(),
    fp.DarwinOptions darwinOptions = const fp.DarwinOptions(),
    fp.WindowsOptions windowsOptions = const fp.WindowsOptions(),
    fp.LinuxOptions linuxOptions = const fp.LinuxOptions(),
    fp.WebOptions webOptions = const fp.WebOptions(),
  }) async {
    pickCount++;

    return [
      CriticalConversationPlatformFile(
        name: criticalConversationAttachment.fileName,
        size: criticalConversationAttachment.sizeBytes,
        path: criticalConversationAttachment.localPath,
      ),
    ];
  }
}

base class CriticalConversationPlatformFile({
  @override required final String name,
  required final int size,
  required String path,
}) extends fp.PlatformFile {
  @override
  final Uri uri = .file(path);

  @override
  int lengthSync() => size;

  @override
  Future<int> length() async => size;

  @override
  Never readAsBytes() => throw UnimplementedError();

  @override
  Never readAsByteStream() => throw UnimplementedError();
}

class CriticalConversationAttachmentService
    implements LocalChatAttachmentService {
  int copyCount = 0;

  String get storageNamespace => 'issue-954-fixture';

  @override
  Future<MessageAttachmentToCreate> copyIntoAppStorage(
    String sourcePath, {
    String? displayName,
  }) async {
    copyCount++;

    return criticalConversationAttachment.copyWith(
      displayName: displayName ?? criticalConversationAttachment.displayName,
    );
  }

  @override
  Future<void> deleteAttachment(String localPath) => Future<void>.value();

  @override
  Future<void> startVoiceRecording() => Future<void>.value();

  @override
  Future<MessageAttachmentToCreate?> stopVoiceRecording() async => null;

  @override
  Future<void> cancelVoiceRecording() => Future<void>.value();

  @override
  Future<MessageAttachmentToCreate> createArchiveAttachment(
    ConversationArchiveAttachment attachment,
  ) async => criticalConversationAttachment;

  @override
  Future<Uint8List> readAttachmentBytes(String localPath) async => Uint8List(0);
}

class CriticalConversationBatchApprovalActions
    implements BatchToolApprovalActions {
  static const _emptyResult = BatchToolApprovalResult(
    claimed: [],
    alreadyHandled: [],
    conflicted: [],
  );

  List<PendingToolCall> approvedCalls = const [];
  List<PendingToolCall> skippedCalls = const [];

  @override
  Future<BatchToolApprovalResult> approveOnce({
    required String rootConversationId,
    required String workspaceId,
    required List<PendingToolCall> pendingCalls,
  }) async {
    approvedCalls = pendingCalls;

    return _emptyResult;
  }

  @override
  Future<BatchToolApprovalResult> skip({
    required String rootConversationId,
    required String workspaceId,
    required List<PendingToolCall> pendingCalls,
  }) async {
    skippedCalls = pendingCalls;

    return _emptyResult;
  }
}

class CriticalConversationRecentModelsNotifier
    extends RecentModelSelectionsNotifier {
  final recordedIds = <String>[];

  @override
  Future<List<String>> build(String workspaceId) async => const [];

  @override
  Future<void> record(String selectionId) async => recordedIds.add(selectionId);
}
