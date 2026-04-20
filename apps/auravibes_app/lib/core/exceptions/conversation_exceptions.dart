/// Exception thrown when no conversation is selected.
class NoConversationSelectedException implements Exception {
  const NoConversationSelectedException();

  @override
  String toString() =>
      'NoConversationSelectedException: No conversation is currently selected';
}
