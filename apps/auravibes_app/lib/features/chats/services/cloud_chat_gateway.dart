import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

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

  Future<StartTurnResult> startTurn({
    required String requestId,
    required String conversationId,
    required int expectedConversationRevision,
    required String clientMessageId,
    required String content,
    required List<String> attachmentIds,
    String? modelSelectionId,
    String? agentId,
  }) => CloudAppErrors.guardCall(
    .conversation,
    () => _client.conversation.startTurn(
      .new(
        workspaceId: _workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedConversationRevision: expectedConversationRevision,
        clientMessageId: clientMessageId,
        content: content,
        attachmentIds: attachmentIds,
        modelSelectionId: modelSelectionId,
        agentId: agentId,
        a2uiSupportedComponents: supportedA2uiChatComponents.toList(),
      ),
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

  Stream<ConversationStreamEvent> subscribeConversation(
    String conversationId, {
    required int afterSequence,
  }) {
    if (_stateGateway.isDisposed) return const Stream.empty();
    final request = ConversationSubscribeRequest(
      workspaceId: _workspaceId,
      conversationId: conversationId,
      afterSequence: afterSequence,
      a2uiSupportedComponents: supportedA2uiChatComponents.toList(),
    );

    return _subscribeConversation?.call(request) ??
        _client.conversation.subscribeConversation(request);
  }

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

  Future<ConversationSnapshot> queueConversationMessage({
    required String requestId,
    required String conversationId,
    required int expectedProjectionRevision,
    required String clientMessageId,
    required String content,
    required List<String> attachmentIds,
    String? metadataJson,
  }) => CloudAppErrors.guardCall(
    .conversation,
    () => _client.conversation.queueConversationMessage(
      .new(
        workspaceId: _workspaceId,
        requestId: requestId,
        conversationId: conversationId,
        expectedProjectionRevision: expectedProjectionRevision,
        clientMessageId: clientMessageId,
        content: content,
        attachmentIds: attachmentIds,
        metadataJson: metadataJson,
        a2uiSupportedComponents: supportedA2uiChatComponents.toList(),
      ),
    ),
  );

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

  Future<ConversationMutationResult> submitToolDecision({
    required String requestId,
    required String turnId,
    required String toolCallId,
    required String argumentsDigest,
    required int expectedTurnRevision,
    required String decision,
    bool stopAll = false,
    String? editedArgumentsJson,
  }) => CloudAppErrors.guardCall(
    .conversation,
    () => _client.conversation.submitToolDecision(
      .new(
        workspaceId: _workspaceId,
        requestId: requestId,
        turnId: turnId,
        toolCallId: toolCallId,
        argumentsDigest: argumentsDigest,
        expectedTurnRevision: expectedTurnRevision,
        decision: decision,
        stopAll: stopAll,
        editedArgumentsJson: editedArgumentsJson,
        a2uiSupportedComponents: supportedA2uiChatComponents.toList(),
      ),
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
  Future<void> deleteConversation(DeleteConversationRequest request) =>
      CloudAppErrors.guardCall(
        .conversation,
        () => _client.conversation.delete(
          request.copyWith(workspaceId: _workspaceId),
        ),
      );
}

extension on CloudChatGateway {
  Future<BeginUploadResult> beginUpload({
    required String requestId,
    required String purpose,
    required String displayName,
    required String mimeType,
    required int sizeBytes,
    required String checksumSha256,
  }) => CloudAppErrors.guardCall(
    .object,
    () => _client.object.beginUpload(
      .new(
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
        purpose: 'unused',
        displayName: 'unused',
        mimeType: 'unused',
        sizeBytes: 0,
        checksumSha256: 'unused',
      ),
    ),
  );
}
