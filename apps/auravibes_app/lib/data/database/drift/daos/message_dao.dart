import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/messages.dart';
import 'package:drift/drift.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<AppDatabase> with _$MessageDaoMixin {
  MessageDao(super.attachedDatabase);

  // Core CRUD operations.
  Future<MessagesTable> insertMessage(MessagesCompanion message) =>
      into(messages).insertReturning(message);

  Future<MessagesTable?> getMessageById(String id) =>
      (select(messages)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<MessagesTable?> patchMessage(
    String id,
    MessagesCompanion companion,
  ) async {
    final tables = await (update(
      messages,
    )..where((tbl) => tbl.id.equals(id))).writeReturning(companion);

    return tables.firstOrNull;
  }

  Future<bool> deleteMessage(String id) async {
    final count = await (delete(
      messages,
    )..where((tbl) => tbl.id.equals(id))).go();

    return count > 0;
  }

  // Business-specific queries.
  Future<List<MessagesTable>> getMessagesByConversation(
    String conversationId,
  ) => _messagesByConversationQuery(conversationId).get();

  Future<List<MessagesTable>> getLatestAssistantMessagesByConversations(
    List<String> conversationIds,
  ) async {
    if (conversationIds.isEmpty) return const [];

    final placeholders = List.filled(conversationIds.length, '?').join(', ');
    final rows = await customSelect(
      '''
      SELECT * FROM (
        SELECT *,
          ROW_NUMBER() OVER (
            PARTITION BY conversation_id
            ORDER BY created_at DESC, id DESC
          ) AS row_number
        FROM messages
        WHERE is_user = 0 AND conversation_id IN ($placeholders)
      )
      WHERE row_number = 1
      ''',
      variables: [
        for (final conversationId in conversationIds) Variable(conversationId),
      ],
      readsFrom: {messages},
    ).get();

    return rows
        .map(
          (row) => MessagesTable(
            id: row.read<String>('id'),
            createdAt: row.read<DateTime>('created_at'),
            updatedAt: row.read<DateTime>('updated_at'),
            conversationId: row.read<String>('conversation_id'),
            content: row.read<String>('content'),
            messageType: _messageTypeFromStorage(
              row.read<String>('message_type'),
            ),
            isUser: row.read<bool>('is_user'),
            status: MessageTableStatus.fromString(row.read<String>('status')),
            metadata: row.readNullable<String>('metadata'),
          ),
        )
        .toList();
  }

  MessagesTableType _messageTypeFromStorage(String value) {
    return MessagesTableType.values.asNameMap()[value] ??
        MessagesTableType.text;
  }

  Stream<MessagesTable?> watchLatestAssistantMessageByConversation(
    String conversationId,
  ) {
    return (select(messages)
          ..where(
            (tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.isUser.equals(false),
          )
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.createdAt,
              mode: OrderingMode.desc,
            ),
            (tbl) => OrderingTerm(
              expression: tbl.id,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  Stream<List<MessagesTable>> watchMessagesByConversation(
    String conversationId,
  ) => _messagesByConversationQuery(conversationId).watch();

  SimpleSelectStatement<$MessagesTable, MessagesTable>
  _messagesByConversationQuery(String conversationId) {
    return (select(messages)
      ..where((tbl) => tbl.conversationId.equals(conversationId))
      ..orderBy([
        (tbl) => OrderingTerm(
          expression: tbl.createdAt,
        ),
      ]));
  }

  Future<List<MessagesTable>> getMessagesByConversationPaginated(
    String conversationId,
    int limit,
    int offset,
  ) =>
      (select(messages)
            ..where((tbl) => tbl.conversationId.equals(conversationId))
            ..orderBy([
              (tbl) => OrderingTerm(
                expression: tbl.createdAt,
              ),
            ])
            ..limit(limit, offset: offset))
          .get();

  Future<List<MessagesTable>> getMessagesByType(
    String conversationId,
    MessagesTableType messageType,
  ) =>
      (select(messages)
            ..where(
              (tbl) =>
                  tbl.conversationId.equals(conversationId) &
                  tbl.messageType.equals(messageType.value),
            )
            ..orderBy([
              (tbl) => OrderingTerm(
                expression: tbl.createdAt,
                mode: OrderingMode.desc,
              ),
            ]))
          .get();

  Future<List<MessagesTable>> getUserMessages(String conversationId) =>
      (select(messages)
            ..where(
              (tbl) =>
                  tbl.conversationId.equals(conversationId) &
                  tbl.isUser.equals(true),
            )
            ..orderBy([
              (tbl) => OrderingTerm(
                expression: tbl.createdAt,
                mode: OrderingMode.desc,
              ),
            ]))
          .get();

  Future<List<MessagesTable>> getSystemMessages(String conversationId) =>
      (select(messages)
            ..where(
              (tbl) =>
                  tbl.conversationId.equals(conversationId) &
                  tbl.isUser.equals(false),
            )
            ..orderBy([
              (tbl) => OrderingTerm(
                expression: tbl.createdAt,
                mode: OrderingMode.desc,
              ),
            ]))
          .get();

  Future<int> getMessageCountByConversation(String conversationId) =>
      (selectOnly(messages)
            ..addColumns([messages.id.count()])
            ..where(messages.conversationId.equals(conversationId)))
          .map((row) => row.read(messages.id.count()) ?? 0)
          .getSingle();

  Future<bool> messageExists(String id) async {
    final result =
        await (selectOnly(messages)
              ..addColumns([messages.id.count()])
              ..where(messages.id.equals(id)))
            .map((row) => row.read(messages.id.count()) ?? 0)
            .getSingle();

    return result > 0;
  }

  Future<List<MessagesTable>> getMessagesByStatus(
    String conversationId,
    String status,
  ) =>
      (select(messages)
            ..where(
              (tbl) =>
                  tbl.conversationId.equals(conversationId) &
                  tbl.status.equals(status),
            )
            ..orderBy([
              (tbl) => OrderingTerm(
                expression: tbl.createdAt,
                mode: OrderingMode.desc,
              ),
            ]))
          .get();

  Future<MessagesTable?> getLatestCompactionSummary(
    String conversationId,
  ) async {
    final rows =
        await (select(messages)
              ..where(
                (tbl) =>
                    tbl.conversationId.equals(conversationId) &
                    tbl.messageType.equals(MessagesTableType.system.value) &
                    tbl.status.equals(MessageTableStatus.sent.value) &
                    tbl.metadata.isNotNull(),
              )
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.createdAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();

    for (final row in rows) {
      final metadataStr = row.metadata;
      if (metadataStr == null) continue;
      try {
        final json = jsonDecode(metadataStr) as Map<String, dynamic>;
        if (json['isCompactionSummary'] == true) return row;
      } on Exception {
        continue;
      }
    }

    return null;
  }
}
