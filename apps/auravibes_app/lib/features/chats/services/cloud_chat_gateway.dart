import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class CloudChatGateway {
  CloudChatGateway(this._stateGateway)
    : _subscribeConversation = null,
      _getConversationSnapshot = null;

  factory CloudChatGateway.forConversationTesting({
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

  CloudChatGateway._forConversationTesting(
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

  Future<BeginUploadResult> beginUpload({
    required String requestId,
    required String purpose,
    required String displayName,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
  }) => guardCloudCall(
    .object,
    () => _client.object.beginUpload(
      BeginUploadRequest(
        workspaceId: _workspaceId,
        requestId: requestId,
        purpose: purpose,
        displayName: displayName,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        checksumSha256: checksumSha256,
      ),
    ),
  );
  Future<ObjectResult> completeUpload({required int objectId}) =>
      guardCloudCall(
        .object,
        () => _client.object.completeUpload(
          CompleteUploadRequest(workspaceId: _workspaceId, objectId: objectId),
        ),
      );
  Future<GetDownloadResult> getDownload({required int objectId}) =>
      guardCloudCall(
        .object,
        () => _client.object.getDownload(
          GetDownloadRequest(workspaceId: _workspaceId, objectId: objectId),
        ),
      );
  Future<void> deleteObject({
    required int objectId,
    required String requestId,
    required int expectedRevision,
  }) => guardCloudCall(
    .object,
    () => _client.object.delete(
      DeleteObjectRequest(
        workspaceId: _workspaceId,
        objectId: objectId,
        requestId: requestId,
        expectedRevision: expectedRevision,
      ),
    ),
  );

  Future<StartTurnResult> startTurn({
    required String requestId,
    required String conversationId,
    required int expectedConversationRevision,
    required String clientMessageId,
    required String content,
    required List<String> attachmentIds,
    String? modelSelectionId,
    String? agentId,
  }) => guardCloudCall(
    .conversation,
    () => _client.conversation.startTurn(
      StartTurnRequest(
        workspaceId: _workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedConversationRevision: expectedConversationRevision,
        clientMessageId: clientMessageId,
        content: content,
        attachmentIds: attachmentIds,
        modelSelectionId: modelSelectionId,
        agentId: agentId,
      ),
    ),
  );
  Future<ConversationMutationResult> continueTurn({
    required String requestId,
    required String conversationId,
    required int expectedConversationRevision,
  }) => guardCloudCall(
    .conversation,
    () => _client.conversation.continueTurn(
      ContinueTurnRequest(
        workspaceId: _workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedConversationRevision: expectedConversationRevision,
      ),
    ),
  );
  Future<TurnSnapshot> getTurn({required String turnId}) => guardCloudCall(
    .conversation,
    () => _client.conversation.getTurn(
      GetTurnRequest(workspaceId: _workspaceId, turnId: turnId),
    ),
  );

  Future<ConversationSnapshot> getConversationSnapshot(
    String conversationId,
  ) =>
      _getConversationSnapshot?.call(conversationId) ??
      guardCloudCall(
        .conversation,
        () => _client.conversation.getConversationSnapshot(
          GetConversationRequest(
            workspaceId: _workspaceId,
            conversationId: conversationId,
          ),
        ),
      );

  Stream<ConversationStreamEvent> subscribeConversation(
    String conversationId, {
    required int afterSequence,
  }) {
    if (_stateGateway.isDisposed) return const Stream.empty();
    final request = ConversationSubscribeRequest(
      workspaceId: _workspaceId,
      conversationId: conversationId,
      afterSequence: afterSequence,
    );

    return _subscribeConversation?.call(request) ??
        _client.conversation.subscribeConversation(request);
  }

  Future<ConversationSnapshot> continueConversation({
    required String requestId,
    required String conversationId,
    required int expectedProjectionRevision,
  }) => guardCloudCall(
    .conversation,
    () => _client.conversation.continueConversation(
      ContinueConversationRequest(
        workspaceId: _workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedProjectionRevision: expectedProjectionRevision,
      ),
    ),
  );

  Future<ConversationSnapshot> queueConversationMessage({
    required String requestId,
    required String conversationId,
    required int expectedProjectionRevision,
    required String clientMessageId,
    required String content,
    required List<String> attachmentIds,
  }) => guardCloudCall(
    .conversation,
    () => _client.conversation.queueConversationMessage(
      QueueConversationMessageRequest(
        workspaceId: _workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedProjectionRevision: expectedProjectionRevision,
        clientMessageId: clientMessageId,
        content: content,
        attachmentIds: attachmentIds,
      ),
    ),
  );

  Future<ConversationSnapshot> stopConversation({
    required String requestId,
    required String conversationId,
    required int expectedProjectionRevision,
  }) => guardCloudCall(
    .conversation,
    () => _client.conversation.stopConversation(
      StopConversationRequest(
        workspaceId: _workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedProjectionRevision: expectedProjectionRevision,
      ),
    ),
  );

  Future<ConversationMutationResult> submitToolDecision({
    required String requestId,
    required String turnId,
    required String toolCallId,
    required String argumentsDigest,
    required int expectedTurnRevision,
    required String decision,
    bool stopAll = false,
    String? editedArgumentsJson,
  }) => guardCloudCall(
    .conversation,
    () => _client.conversation.submitToolDecision(
      SubmitToolDecisionRequest(
        workspaceId: _workspaceId,
        requestId: requestId,
        turnId: turnId,
        toolCallId: toolCallId,
        argumentsDigest: argumentsDigest,
        expectedTurnRevision: expectedTurnRevision,
        decision: decision,
        stopAll: stopAll,
        editedArgumentsJson: editedArgumentsJson,
      ),
    ),
  );
  Future<ConversationMutationResult> cancelTurn({
    required String requestId,
    required String turnId,
    required int expectedTurnRevision,
  }) => guardCloudCall(
    .conversation,
    () => _client.conversation.cancelTurn(
      CancelTurnRequest(
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
  }) => guardCloudCall(
    .conversation,
    () => _client.conversation.compact(
      CompactConversationRequest(
        workspaceId: _workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedConversationRevision: expectedConversationRevision,
      ),
    ),
  );
  Future<ConversationSummary> createConversation(
    CreateConversationRequest request,
  ) => guardCloudCall(
    .conversation,
    () => _client.conversation.create(
      request.copyWith(workspaceId: _workspaceId),
    ),
  );
  Future<List<ConversationSummary>> listConversations({int limit = 100}) =>
      guardCloudCall(
        .conversation,
        () => _client.conversation.list(
          ListConversationsRequest(workspaceId: _workspaceId, limit: limit),
        ),
      );
  Future<ConversationSummary> getConversation(String conversationId) =>
      guardCloudCall(
        .conversation,
        () => _client.conversation.get(
          GetConversationRequest(
            workspaceId: _workspaceId,
            conversationId: conversationId,
          ),
        ),
      );
  Future<List<ConversationMessageView>> listConversationMessages(
    String conversationId,
  ) => guardCloudCall(
    .conversation,
    () => _client.conversation.listMessages(
      ListConversationMessagesRequest(
        workspaceId: _workspaceId,
        conversationId: conversationId,
        limit: 500,
      ),
    ),
  );
  Future<ConversationSummary> updateConversation(
    UpdateConversationRequest request,
  ) => guardCloudCall(
    .conversation,
    () => _client.conversation.update(
      request.copyWith(workspaceId: _workspaceId),
    ),
  );
  Future<void> deleteConversation(DeleteConversationRequest request) =>
      guardCloudCall(
        .conversation,
        () => _client.conversation.delete(
          request.copyWith(workspaceId: _workspaceId),
        ),
      );
}
