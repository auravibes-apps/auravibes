import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_chat_attachment_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:logging/logging.dart';
import 'package:uuid/v7.dart';

typedef LoadCloudChatGateway = Future<CloudChatGateway?> Function();
typedef LoadCloudChatAttachments =
    Future<CloudChatAttachmentUsecase?> Function();

final _logger = Logger('cloud_conversation_send');

class const _QueueMessageTarget({
  required final CloudChatGateway chat,
  required final String conversationId,
  required final ConversationSnapshot projection,
});

class const _QueueMessageInput({
  required final _QueueMessageTarget target,
  required final _QueueMessagePayload payload,
}) {
  CloudChatGateway get _chat => target.chat;

  String get _conversationId => target.conversationId;

  int get _projectionRevision =>
      target.projection.conversation.projectionRevision;

  String get _content => payload.draft.text;

  List<String> get _attachmentIds => payload.uploadedObjects
      .map((object) => '${object.objectId}')
      .toList(growable: false);

  String? get _metadataJson => payload.draft.metadataJson;
}

class const _QueueMessagePayload({
  required final CloudChatAttachmentUsecase? attachments,
  required final ChatDraft draft,
  required final List<ObjectResult> uploadedObjects,
});

class const CloudChatMessageSender({
  required final LoadCloudChatGateway _gateway,
  required final LoadCloudChatAttachments _attachments,
  required final WorkspaceCapabilities _capabilities,
  required final void Function(String conversationId) _invalidateMessages,
}) {
  Future<void> call(String conversationId, ChatDraft draft) async {
    _capabilities.require(
      supported: draft.attachments.isEmpty || _capabilities.attachments,
    );
    final chat = await _loadGateway();
    await _sendDraft(chat, conversationId, draft);
    _invalidateMessages(conversationId);
  }
}

extension on CloudChatMessageSender {
  Future<void> _sendDraft(
    CloudChatGateway chat,
    String conversationId,
    ChatDraft draft,
  ) async {
    final input = await _prepareQueueInput(chat, conversationId, draft);
    final snapshot = await _queueMessage(input);
    await _continueIfReady(chat, conversationId, snapshot);
  }

  Future<_QueueMessageInput> _prepareQueueInput(
    CloudChatGateway chat,
    String conversationId,
    ChatDraft draft,
  ) async {
    final projection = await _loadProjection(chat, conversationId);
    final payload = await _loadQueuePayload(draft);

    return .new(
      target: .new(
        chat: chat,
        conversationId: conversationId,
        projection: projection,
      ),
      payload: payload,
    );
  }

  Future<_QueueMessagePayload> _loadQueuePayload(ChatDraft draft) async {
    final attachments = await _attachments();
    final uploadedObjects = await _uploadAttachments(attachments, draft);

    return .new(
      attachments: attachments,
      draft: draft,
      uploadedObjects: uploadedObjects,
    );
  }

  Future<CloudChatGateway> _loadGateway() async {
    final gateway = await _gateway();
    if (gateway == null) {
      throw const UnsupportedWorkspaceCapabilityException();
    }

    return gateway;
  }

  Future<ConversationSnapshot> _loadProjection(
    CloudChatGateway chat,
    String conversationId,
  ) async {
    final projection = await chat.getConversationSnapshot(conversationId);
    _logProjection(conversationId, projection);

    return projection;
  }

  void _logProjection(String conversationId, ConversationSnapshot projection) {
    _logger.info(
      'Cloud send snapshot: conversationId=$conversationId, '
      'sequence=${projection.sequence}, '
      'projectionRevision=${projection.conversation.projectionRevision}, '
      'executionState=${projection.conversation.executionState}.',
    );
  }

  Future<List<ObjectResult>> _uploadAttachments(
    CloudChatAttachmentUsecase? attachments,
    ChatDraft draft,
  ) =>
      attachments?.uploadDraftResults(attachments: draft.attachments) ??
      Future.value(const []);

  Future<ConversationSnapshot> _queueMessage(_QueueMessageInput input) async {
    try {
      final queued = await _queueMessageWithoutCleanup(input);
      _logQueuedMessage(
        input._conversationId,
        queued,
        input._attachmentIds.length,
      );

      return queued;
    } on Object catch (error, stackTrace) {
      await _deleteUploaded(input);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

extension on CloudChatMessageSender {
  Future<void> _deleteUploaded(_QueueMessageInput input) async {
    await input.payload.attachments?.deleteUploaded(
      input.payload.uploadedObjects,
    );
  }

  Future<ConversationSnapshot> _queueMessageWithoutCleanup(
    _QueueMessageInput input,
  ) => input._chat.queueConversationMessage((
    requestId: _newRequestId(),
    conversationId: input._conversationId,
    expectedProjectionRevision: input._projectionRevision,
    clientMessageId: _newRequestId(),
    content: input._content,
    attachmentIds: input._attachmentIds,
    metadataJson: input._metadataJson,
  ));

  String _newRequestId() => const UuidV7().generate();

  void _logQueuedMessage(
    String conversationId,
    ConversationSnapshot queued,
    int attachmentCount,
  ) {
    _logger.info(
      'Cloud message queued: conversationId=$conversationId, '
      'sequence=${queued.sequence}, '
      'projectionRevision=${queued.conversation.projectionRevision}, '
      'executionState=${queued.conversation.executionState}, '
      'attachmentCount=$attachmentCount.',
    );
  }

  Future<void> _continueIfReady(
    CloudChatGateway chat,
    String conversationId,
    ConversationSnapshot snapshot,
  ) async {
    if (!_shouldContinue(snapshot)) return;

    _logExecutionStart(conversationId, snapshot);
    final execution = await _continueConversation(
      chat,
      conversationId,
      snapshot,
    );
    _logExecutionAcknowledged(conversationId, execution);
  }

  bool _shouldContinue(ConversationSnapshot snapshot) {
    final state = snapshot.conversation.executionState;

    return state == 'idle' || state == 'awaitingUserAction';
  }

  void _logExecutionStart(
    String conversationId,
    ConversationSnapshot snapshot,
  ) {
    _logger.info(
      'Cloud execution start requested: '
      'conversationId=$conversationId, '
      'projectionRevision=${snapshot.conversation.projectionRevision}.',
    );
  }

  Future<ConversationSnapshot> _continueConversation(
    CloudChatGateway chat,
    String conversationId,
    ConversationSnapshot snapshot,
  ) => chat.continueConversation(
    requestId: const UuidV7().generate(),
    conversationId: conversationId,
    expectedProjectionRevision: snapshot.conversation.projectionRevision,
  );

  void _logExecutionAcknowledged(
    String conversationId,
    ConversationSnapshot execution,
  ) {
    _logger.info(
      'Cloud execution start acknowledged: '
      'conversationId=$conversationId, sequence=${execution.sequence}, '
      'executionState=${execution.conversation.executionState}, '
      'activeExecutionId=${execution.activeExecution?.id}.',
    );
  }
}
