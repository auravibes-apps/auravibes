enum MessagesTableType {
  text('text'),
  image('image'),
  toolCall('tool_call'),
  system('system')
  ;

  const MessagesTableType(this.value);
  final String value;
}

/// Database enum representing the status of a message.
///
/// See MessageStatus in domain layer for full documentation on status flow.
///
/// Note: `sending` is rarely persisted - it's primarily an in-memory state.
/// Use `unfinished` for messages with unknown outcome that need to survive
/// app restart.
enum MessageTableStatus {
  /// Transient state - rarely persisted, primarily in-memory for UI feedback.
  sending('sending'),

  /// Persisted "outcome unknown" state - AI responses pending completion
  /// or recovery.
  unfinished('unfinished'),

  /// Message completed successfully.
  sent('sent'),

  /// Actively streaming (in-memory overlay).
  streaming('streaming'),

  /// Message failed - error details in metadata.
  error('error')
  ;

  const MessageTableStatus(this.value);

  factory MessageTableStatus.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sending':
        return MessageTableStatus.sending;
      case 'sent':
        return MessageTableStatus.sent;
      case 'unfinished':
        return MessageTableStatus.unfinished;
      case 'error':
        return MessageTableStatus.error;
      case 'streaming':
        return MessageTableStatus.streaming;
      default:
        throw ArgumentError('Invalid message status: $value');
    }
  }
  final String value;
}
