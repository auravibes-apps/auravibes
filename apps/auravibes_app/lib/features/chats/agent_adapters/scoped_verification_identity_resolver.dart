import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/models/scoped_verification_invocation.dart';
import 'package:drift/drift.dart';

class const ScopedVerificationIdentityResolver(final AppDatabase database) {
  Future<ScopedVerificationIdentity?> call(
    ScopedVerificationInvocation invocation,
  ) async {
    final chat = await database.conversationDao.getConversationById(
      invocation.conversationId,
    );
    if (chat == null) return null;
    final messages = await _messagesForConversation(
      database,
      invocation.conversationId,
    );

    return _resolvedIdentity(chat.workspaceId, invocation.toolCallId, messages);
  }
}

typedef _SequencedMessage = ({
  int sequence,
  bool isUser,
  String id,
  String? metadata,
});

Future<List<_SequencedMessage>> _messagesForConversation(
  AppDatabase database,
  String conversationId,
) async =>
    (await database
            .customSelect(
              'SELECT id, rowid AS sequence, metadata, is_user FROM messages '
              'WHERE conversation_id = ? ORDER BY rowid ASC',
              variables: [Variable<String>(conversationId)],
            )
            .get())
        .map(
          (row) => (
            id: row.read<String>('id'),
            sequence: row.read<int>('sequence'),
            metadata: row.readNullable<String>('metadata'),
            isUser: row.read<bool>('is_user'),
          ),
        )
        .toList();

ScopedVerificationIdentity _resolvedIdentity(
  String workspaceId,
  String toolCallId,
  List<_SequencedMessage> messages,
) {
  final call = _uniqueToolCall(messages, toolCallId);
  if (call == null) return (workspaceId: workspaceId, turnId: null);
  final origin = _originatingUserMessage(messages, call.sequence);

  return (workspaceId: workspaceId, turnId: origin?.id);
}

_SequencedMessage? _uniqueToolCall(
  List<_SequencedMessage> messages,
  String toolCallId,
) {
  final calls = messages.where((message) {
    if (message.isUser) return false;
    final metadata = MessageMetadataEntity.fromJsonString(message.metadata);

    return metadata?.toolCalls.any((call) => call.id == toolCallId) ?? false;
  }).take(2).toList();
  if (calls.length != 1) return null;

  return calls.single;
}

_SequencedMessage? _originatingUserMessage(
  List<_SequencedMessage> messages,
  int sequence,
) =>
    messages
        .where((message) => message.isUser && message.sequence < sequence)
        .lastOrNull;
