class const CloudToolDecisionItem({
  required final String conversationId,
  required final String turnId,
  required final String toolCallId,
  required final String argumentsDigest,
  required final int expectedTurnRevision,
  final String? editedArgumentsJson,
});
