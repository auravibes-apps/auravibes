/// The user message exists even though agent continuation failed.
class const MessagePersistedException({
  required final String message,
  required final StackTrace stackTrace,
}) implements Exception {
  @override
  String toString() => 'MessagePersistedException: $message';
}
