import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class CloudTurnUsecase {
  const CloudTurnUsecase(this._gateway);

  final CloudChatGateway _gateway;

  Future<TurnSnapshot> get(String turnId) => _gateway.getTurn(turnId: turnId);

  Future<ConversationMutationResult> decide({
    required String turnId,
    required String toolCallId,
    required String argumentsDigest,
    required int revision,
    required bool approved,
    bool stopAll = false,
    String? editedArgumentsJson,
  }) {
    final requestId = DateTime.now().microsecondsSinceEpoch.toString();

    return _retryStaleDecision(
      turnId: turnId,
      toolCallId: toolCallId,
      argumentsDigest: argumentsDigest,
      revision: revision,
      action: (expectedRevision) => _gateway.submitToolDecision(
        requestId: requestId,
        turnId: turnId,
        toolCallId: toolCallId,
        argumentsDigest: argumentsDigest,
        expectedTurnRevision: expectedRevision,
        decision: approved ? 'approve' : 'deny',
        stopAll: stopAll,
        editedArgumentsJson: editedArgumentsJson,
      ),
    );
  }

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
  ) async {
    final conversation = await _gateway.getConversation(conversationId);
    try {
      return await _gateway.continueTurn(
        requestId: DateTime.now().microsecondsSinceEpoch.toString(),
        conversationId: conversationId,
        expectedConversationRevision: conversation.revision,
      );
    } on CloudAppException catch (error) {
      if (error.code != ConversationErrorCode.staleRevision.name) rethrow;
      final latest = await _gateway.getConversation(conversationId);

      return await _gateway.continueTurn(
        requestId: DateTime.now().microsecondsSinceEpoch.toString(),
        conversationId: conversationId,
        expectedConversationRevision: latest.revision,
      );
    }
  }

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

  Future<ConversationMutationResult> _retryStaleDecision({
    required String turnId,
    required String toolCallId,
    required String argumentsDigest,
    required int revision,
    required Future<ConversationMutationResult> Function(int revision) action,
  }) async {
    try {
      return await action(revision);
    } on CloudAppException catch (error) {
      if (error.code != ConversationErrorCode.staleRevision.name) rethrow;
      final snapshot = await get(turnId);
      final call = snapshot.toolCalls
          .where((candidate) => candidate.id == toolCallId)
          .firstOrNull;
      if (call == null ||
          call.status != 'pending' ||
          call.argumentsDigest != argumentsDigest) {
        rethrow;
      }

      return await action(snapshot.turn.revision);
    }
  }

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
