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
    final messages = await database
        .customSelect(
          'SELECT id, rowid AS sequence, metadata, is_user FROM messages '
          'WHERE conversation_id = ? ORDER BY rowid ASC',
          variables: [Variable<String>(invocation.conversationId)],
        )
        .get();
    final calls = messages.where((row) {
      if (row.read<bool>('is_user')) return false;
      final metadata = MessageMetadataEntity.fromJsonString(
        row.readNullable<String>('metadata'),
      );

      return metadata?.toolCalls.any(
            (call) => call.id == invocation.toolCallId,
          ) ??
          false;
    }).toList();
    if (calls.length != 1) return (workspaceId: chat.workspaceId, turnId: null);
    final sequence = calls.single.read<int>('sequence');
    final origin = messages
        .where(
          (row) =>
              row.read<bool>('is_user') && row.read<int>('sequence') < sequence,
        )
        .lastOrNull;

    return (workspaceId: chat.workspaceId, turnId: origin?.read<String>('id'));
  }
}
