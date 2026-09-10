import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

typedef _SubmitToolDecisionRequest = ({
  String requestId,
  String turnId,
  String toolCallId,
  String argumentsDigest,
  int expectedTurnRevision,
  String decision,
  bool stopAll,
  String? editedArgumentsJson,
});

typedef _QueueConversationMessageRequest = ({
  String requestId,
  String conversationId,
  int expectedProjectionRevision,
  String clientMessageId,
  String content,
  List<String> attachmentIds,
  String? metadataJson,
});

typedef _StartTurnRequest = ({
  String requestId,
  String conversationId,
  int expectedConversationRevision,
  String clientMessageId,
  String content,
  List<String> attachmentIds,
  String? modelSelectionId,
  String? agentId,
});

typedef _BeginUploadRequest = ({
  String requestId,
  String purpose,
  String displayName,
  String mimeType,
  int sizeBytes,
  String checksumSha256,
});

class CloudChatGateway {
  new(this._stateGateway)
    : _subscribeConversation = null,
      _getConversationSnapshot = null;

  factory forConversationTesting({
    required CloudWorkspaceStateGateway stateGateway,
    required Stream<ConversationStreamEvent> Function(
      ConversationSubscribeRequest request,
    )
    subscribeConversation,
    required Future<ConversationSnapshot> Function(String conversationId)
    getConversationSnapshot,
  }) => CloudChatGateway._forConversationTesting(
    stateGateway,
    subscribeConversation,
    getConversationSnapshot,
  );

  new _forConversationTesting(
    this._stateGateway,
    this._subscribeConversation,
    this._getConversationSnapshot,
  );

  final CloudWorkspaceStateGateway _stateGateway;

  final Stream<ConversationStreamEvent> Function(
    ConversationSubscribeRequest request,
  )?
  _subscribeConversation;
  final Future<ConversationSnapshot> Function(String conversationId)?
  _getConversationSnapshot;

  int get _workspaceId => _stateGateway.workspace.cloudWorkspaceId;
  Client get _client => _stateGateway.client;

  Stream<ConversationStreamEvent> subscribeConversation(
    String conversationId, {
    required int afterSequence,
  }) {
    if (_stateGateway.isDisposed()) return const Stream.empty();
    final request = ConversationSubscribeRequest(
      workspaceId: _workspaceId,
      conversationId: conversationId,
      afterSequence: afterSequence,
      a2uiSupportedComponents: supportedA2uiChatComponents.toList(),
    );

    return _subscribeConversation?.call(request) ??
        _client.conversation.subscribeConversation(request);
  }
}

Future<T> _guardConversation<T>(Future<T> Function() call) =>
    CloudAppErrors.guardCall(.conversation, call);

Future<T> _guardObject<T>(Future<T> Function() call) =>
    CloudAppErrors.guardCall(.object, call);

SubmitToolDecisionRequest _submitToolDecisionRequest(
  int workspaceId,
  _SubmitToolDecisionRequest request,
) => .new(
  workspaceId: workspaceId,
  requestId: request.requestId,
  turnId: request.turnId,
  toolCallId: request.toolCallId,
  argumentsDigest: request.argumentsDigest,
  expectedTurnRevision: request.expectedTurnRevision,
  decision: request.decision,
  stopAll: request.stopAll,
  editedArgumentsJson: request.editedArgumentsJson,
  a2uiSupportedComponents: supportedA2uiChatComponents.toList(),
);

QueueConversationMessageRequest _queueConversationMessageRequest(
  int workspaceId,
  _QueueConversationMessageRequest request,
) => .new(
  workspaceId: workspaceId,
  requestId: request.requestId,
  conversationId: request.conversationId,
  expectedProjectionRevision: request.expectedProjectionRevision,
  clientMessageId: request.clientMessageId,
  content: request.content,
  attachmentIds: request.attachmentIds,
  metadataJson: request.metadataJson,
  a2uiSupportedComponents: supportedA2uiChatComponents.toList(),
);

StartTurnRequest _startTurnRequest(
  int workspaceId,
  _StartTurnRequest request,
) => .new(
  workspaceId: workspaceId,
  requestId: request.requestId,
  conversationId: request.conversationId,
  expectedConversationRevision: request.expectedConversationRevision,
  clientMessageId: request.clientMessageId,
  content: request.content,
  attachmentIds: request.attachmentIds,
  modelSelectionId: request.modelSelectionId,
  agentId: request.agentId,
  a2uiSupportedComponents: supportedA2uiChatComponents.toList(),
);

BeginUploadRequest _beginUploadRequest(
  int workspaceId,
  _BeginUploadRequest request,
) => .new(
  workspaceId: workspaceId,
  requestId: request.requestId,
  purpose: request.purpose,
  displayName: request.displayName,
  mimeType: request.mimeType,
  sizeBytes: request.sizeBytes,
  checksumSha256: request.checksumSha256,
);

extension CloudChatGatewayConversationBaseOps on CloudChatGateway {
  Future<ConversationSnapshot> stopConversation({
    required String requestId,
    required String conversationId,
    required int expectedProjectionRevision,
  }) => CloudAppErrors.guardCall(
    .conversation,
    () => _client.conversation.stopConversation(
      .new(
        workspaceId: _workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedProjectionRevision: expectedProjectionRevision,
        a2uiSupportedComponents: supportedA2uiChatComponents.toList(),
      ),
    ),
  );

  Future<ConversationMutationResult> submitToolDecision(
    _SubmitToolDecisionRequest request,
  ) => _guardConversation(
    () => _client.conversation.submitToolDecision(
      _submitToolDecisionRequest(_workspaceId, request),
    ),
  );
  Future<ConversationMutationResult> cancelTurn({
    required String requestId,
    required String turnId,
    required int expectedTurnRevision,
  }) => CloudAppErrors.guardCall(
    .conversation,
    () => _client.conversation.cancelTurn(
      .new(
        workspaceId: _workspaceId,
        requestId: requestId,
        turnId: turnId,
        expectedTurnRevision: expectedTurnRevision,
      ),
    ),
  );
  Future<ConversationMutationResult> compactConversation({
    required String requestId,
    required String conversationId,
    required int expectedConversationRevision,
  }) => CloudAppErrors.guardCall(
    .conversation,
    () => _client.conversation.compact(
      .new(
        workspaceId: _workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedConversationRevision: expectedConversationRevision,
      ),
    ),
  );
  Future<ConversationSummary> createConversation(
    CreateConversationRequest request,
  ) => CloudAppErrors.guardCall(
    .conversation,
    () => _client.conversation.create(
      request.copyWith(workspaceId: _workspaceId),
    ),
  );
  Future<List<ConversationSummary>> listConversations({int limit = 100}) =>
      CloudAppErrors.guardCall(
        .conversation,
        () => _client.conversation.list(
          .new(workspaceId: _workspaceId, limit: limit),
        ),
      );
  Future<ConversationSummary> getConversation(String conversationId) =>
      CloudAppErrors.guardCall(
        .conversation,
        () => _client.conversation.get(
          .new(workspaceId: _workspaceId, conversationId: conversationId),
        ),
      );
  Future<List<ConversationMessageView>> listConversationMessages(
    String conversationId,
  ) => CloudAppErrors.guardCall(
    .conversation,
    () => _client.conversation.listMessages(
      .new(
        workspaceId: _workspaceId,
        conversationId: conversationId,
        limit: 500,
        a2uiSupportedComponents: supportedA2uiChatComponents.toList(),
      ),
    ),
  );
  Future<ConversationSummary> updateConversation(
    UpdateConversationRequest request,
  ) => CloudAppErrors.guardCall(
    .conversation,
    () => _client.conversation.update(
      request.copyWith(workspaceId: _workspaceId),
    ),
  );
}

extension CloudChatGatewayConversationOperations on CloudChatGateway {
  Future<ConversationSnapshot> continueConversation({
    required String requestId,
    required String conversationId,
    required int expectedProjectionRevision,
  }) => CloudAppErrors.guardCall(
    .conversation,
    () => _client.conversation.continueConversation(
      .new(
        workspaceId: _workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedProjectionRevision: expectedProjectionRevision,
        a2uiSupportedComponents: supportedA2uiChatComponents.toList(),
      ),
    ),
  );

  Future<ConversationSnapshot> queueConversationMessage(
    _QueueConversationMessageRequest request,
  ) => _guardConversation(
    () => _client.conversation.queueConversationMessage(
      _queueConversationMessageRequest(_workspaceId, request),
    ),
  );

  Future<void> deleteConversation(DeleteConversationRequest request) =>
      CloudAppErrors.guardCall(
        .conversation,
        () => _client.conversation.delete(
          request.copyWith(workspaceId: _workspaceId),
        ),
      );
}

extension CloudChatGatewayTurnOperations on CloudChatGateway {
  Future<StartTurnResult> startTurn(_StartTurnRequest request) =>
      _guardConversation(
        () => _client.conversation.startTurn(
          _startTurnRequest(_workspaceId, request),
        ),
      );

  Future<ConversationMutationResult> continueTurn({
    required String requestId,
    required String conversationId,
    required int expectedConversationRevision,
  }) => CloudAppErrors.guardCall(
    .conversation,
    () => _client.conversation.continueTurn(
      .new(
        workspaceId: _workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedConversationRevision: expectedConversationRevision,
        a2uiSupportedComponents: supportedA2uiChatComponents.toList(),
      ),
    ),
  );

  Future<TurnSnapshot> getTurn({required String turnId}) =>
      CloudAppErrors.guardCall(
        .conversation,
        () => _client.conversation.getTurn(
          .new(
            workspaceId: _workspaceId,
            turnId: turnId,
            a2uiSupportedComponents: supportedA2uiChatComponents.toList(),
          ),
        ),
      );

  Future<ConversationSnapshot> getConversationSnapshot(String conversationId) =>
      _getConversationSnapshot?.call(conversationId) ??
      CloudAppErrors.guardCall(
        .conversation,
        () => _client.conversation.getConversationSnapshot(
          .new(
            workspaceId: _workspaceId,
            conversationId: conversationId,
            a2uiSupportedComponents: supportedA2uiChatComponents.toList(),
          ),
        ),
      );

  Future<BeginUploadResult> beginUpload(_BeginUploadRequest request) =>
      _guardObject(
        () => _client.object.beginUpload(
          _beginUploadRequest(_workspaceId, request),
        ),
      );

  Future<ObjectResult> completeUpload({required int objectId}) =>
      CloudAppErrors.guardCall(
        .object,
        () => _client.object.completeUpload(
          .new(workspaceId: _workspaceId, objectId: objectId),
        ),
      );

  Future<GetDownloadResult> getDownload({required int objectId}) =>
      CloudAppErrors.guardCall(
        .object,
        () => _client.object.getDownload(
          .new(workspaceId: _workspaceId, objectId: objectId),
        ),
      );

  Future<void> deleteObject({
    required int objectId,
    required String requestId,
    required int expectedRevision,
  }) => CloudAppErrors.guardCall(
    .object,
    () => _client.object.delete(
      .new(
        workspaceId: _workspaceId,
        objectId: objectId,
        requestId: requestId,
        expectedRevision: expectedRevision,
      ),
    ),
  );
}
