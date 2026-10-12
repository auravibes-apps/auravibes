/// Identifies the invocation being detached from its foreground turn.
class const BackgroundWorkDetachRequest({
  required final String conversationId,
  required final String toolCallId,
  required final String toolKind,
  final String? originatingMessageId,
});
