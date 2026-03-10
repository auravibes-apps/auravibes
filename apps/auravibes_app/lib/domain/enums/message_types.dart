enum MessageType {
  text('text'),
  image('image'),
  toolCall('tool_call'),
  system('system')
  ;

  const MessageType(this.value);

  factory MessageType.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'tool_call':
        return MessageType.toolCall;
      case 'system':
        return MessageType.system;
      default:
        throw ArgumentError('Invalid message type: $value');
    }
  }
  final String value;

  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Text';
      case MessageType.image:
        return 'Image';
      case MessageType.toolCall:
        return 'Tool Call';
      case MessageType.system:
        return 'System';
    }
  }
}

/// Enum representing the status of a message.
///
/// ## Status Flow
///
/// ### User Message Flow:
/// 1. `sending` - Transient state, may be briefly persisted until confirmation
///    from AI service
/// 2. `sent` - Persisted to DB after successful confirmation from AI service
/// 3. `error` - If sending fails
///
/// ### AI Response Flow:
/// 1. `unfinished` - Persisted to DB immediately, represents "outcome unknown"
///    - Survives app restart/crash, allows recovery of incomplete responses
///    - Transitions to `streaming` when actively receiving content
/// 2. `streaming` - Actively receiving content (may be persisted
///    during streaming)
///    - Transient state that will become `sent` or `error`
/// 3. `sent` - Response completed successfully
/// 4. `error` - Response failed (partial content preserved in DB)
///
/// ### Key Distinction:
/// - `sending` = in-memory only, for UI feedback during active transmission
/// - `unfinished` = persisted to DB, means "pending outcome" (app could
///   close, crash, error)
enum MessageStatus {
  /// Transient state for UI feedback while actively transmitting.
  /// May be briefly persisted until confirmation from AI service.
  sending('sending'),

  /// Persisted "outcome unknown" state - survives app restart.
  /// Used for AI responses that are pending completion or may have failed.
  unfinished('unfinished'),

  /// Actively receiving streaming content.
  /// May be persisted during streaming, transitions to `sent` or `error`.
  streaming('streaming'),

  /// Message completed successfully.
  sent('sent'),

  /// Message failed - check error details in metadata.
  error('error')
  ;

  const MessageStatus(this.value);

  factory MessageStatus.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending;
      case 'unfinished':
        return MessageStatus.unfinished;
      case 'sent':
        return MessageStatus.sent;
      case 'error':
        return MessageStatus.error;
      case 'streaming':
        return MessageStatus.streaming;
      default:
        throw ArgumentError('Invalid message status: $value');
    }
  }
  final String value;

  String get displayName {
    switch (this) {
      case MessageStatus.sending:
        return 'Sending';
      case MessageStatus.unfinished:
        return 'Unfinished';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.error:
        return 'Error';

      case MessageStatus.streaming:
        return 'Streaming';
    }
  }
}
