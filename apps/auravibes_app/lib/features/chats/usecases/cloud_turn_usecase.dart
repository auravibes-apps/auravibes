import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

typedef _DecisionRequest = ({
  String turnId,
  String toolCallId,
  String argumentsDigest,
  int revision,
  bool approved,
  bool stopAll,
  String? editedArgumentsJson,
});

typedef _DecisionRetryRequest = ({
  String turnId,
  String toolCallId,
  String argumentsDigest,
  int revision,
  Future<ConversationMutationResult> Function(int revision) action,
});

class const CloudTurnUsecase(final CloudChatGateway _gateway) {
  Future<TurnSnapshot> get(String turnId) => _gateway.getTurn(turnId: turnId);

  Future<ConversationMutationResult> decide(_DecisionRequest request) =>
      _retryStaleDecision(_decisionRetryRequest(request));

  Future<ConversationMutationResult> cancel({
    required String turnId,
    required int revision,
  }) => _retryStale(
    turnId,
    revision,
    (expectedRevision) => _gateway.cancelTurn(
      requestId: DateTime.now().microsecondsSinceEpoch.toString(),
      turnId: turnId,
      expectedTurnRevision: expectedRevision,
    ),
  );

  Future<ConversationMutationResult> continueConversation(
    String conversationId,
  ) => _continueConversation(conversationId);

  Future<ConversationSnapshot> continueSharedConversation({
    required String conversationId,
    required int projectionRevision,
  }) => _gateway.continueConversation(
    requestId: DateTime.now().microsecondsSinceEpoch.toString(),
    conversationId: conversationId,
    expectedProjectionRevision: projectionRevision,
  );

  Future<ConversationSnapshot> stopSharedConversation({
    required String conversationId,
    required int projectionRevision,
  }) => _gateway.stopConversation(
    requestId: DateTime.now().microsecondsSinceEpoch.toString(),
    conversationId: conversationId,
    expectedProjectionRevision: projectionRevision,
  );
}

extension on CloudTurnUsecase {
  _DecisionRetryRequest _decisionRetryRequest(_DecisionRequest request) {
    final requestId = DateTime.now().microsecondsSinceEpoch.toString();

    return (
      turnId: request.turnId,
      toolCallId: request.toolCallId,
      argumentsDigest: request.argumentsDigest,
      revision: request.revision,
      action: (expectedRevision) =>
          _submitDecision(request, requestId, expectedRevision),
    );
  }

  Future<ConversationMutationResult> _continueConversation(
    String conversationId,
  ) async {
    final conversation = await _gateway.getConversation(conversationId);
    try {
      return await _continueTurn(conversationId, conversation.revision);
    } on CloudAppException catch (error) {
      if (error.code != ConversationErrorCode.staleRevision.name) rethrow;
      final latest = await _gateway.getConversation(conversationId);

      return await _continueTurn(conversationId, latest.revision);
    }
  }

  Future<ConversationMutationResult> _continueTurn(
    String conversationId,
    int revision,
  ) => _gateway.continueTurn(
    requestId: DateTime.now().microsecondsSinceEpoch.toString(),
    conversationId: conversationId,
    expectedConversationRevision: revision,
  );

  Future<ConversationMutationResult> _retryStaleDecision(
    _DecisionRetryRequest request,
  ) async {
    try {
      return await request.action(request.revision);
    } on CloudAppException catch (error) {
      if (error.code != ConversationErrorCode.staleRevision.name) rethrow;
      final revision = await _staleDecisionRevision(request);
      if (revision == null) rethrow;

      return await request.action(revision);
    }
  }

  Future<int?> _staleDecisionRevision(_DecisionRetryRequest request) async {
    final snapshot = await get(request.turnId);
    final call = snapshot.toolCalls
        .where((candidate) => candidate.id == request.toolCallId)
        .firstOrNull;
    if (!_matchesPendingCall(call, request.argumentsDigest)) {
      return null;
    }

    return snapshot.turn.revision;
  }

  Future<ConversationMutationResult> _submitDecision(
    _DecisionRequest request,
    String requestId,
    int expectedRevision,
  ) => _gateway.submitToolDecision((
    requestId: requestId,
    turnId: request.turnId,
    toolCallId: request.toolCallId,
    argumentsDigest: request.argumentsDigest,
    expectedTurnRevision: expectedRevision,
    decision: request.approved ? 'approve' : 'deny',
    stopAll: request.stopAll,
    editedArgumentsJson: request.editedArgumentsJson,
  ));

  bool _matchesPendingCall(
    ConversationToolCallView? call,
    String argumentsDigest,
  ) =>
      call != null &&
      call.status == 'pending' &&
      call.argumentsDigest == argumentsDigest;

  Future<ConversationMutationResult> _retryStale(
    String turnId,
    int revision,
    Future<ConversationMutationResult> Function(int revision) action,
  ) async {
    try {
      return await action(revision);
    } on CloudAppException catch (error) {
      if (error.code != ConversationErrorCode.staleRevision.name) rethrow;
      final snapshot = await get(turnId);

      return await action(snapshot.turn.revision);
    }
  }
}
