import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/messages_table.dart';
import 'package:drift/drift.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<AppDatabase> with _$MessageDaoMixin {
  MessageDao(super.attachedDatabase);

  // Core CRUD operations
  Future<MessagesTable> insertMessage(MessagesCompanion message) =>
      into(messages).insertReturning(message);

  Future<MessagesTable?> getMessageById(String id) =>
      (select(messages)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<MessagesTable?> updateMessage(
    String id,
    MessagesCompanion companion,
  ) => (update(messages)..where((tbl) => tbl.id.equals(id)))
      .writeReturning(companion)
      .then((tables) => tables.firstOrNull);

  Future<bool> deleteMessage(String id) => (delete(
    messages,
  )..where((tbl) => tbl.id.equals(id))).go().then((count) => count > 0);

  // Business-specific queries
  Future<List<MessagesTable>> getMessagesByConversation(
    String conversationId,
  ) =>
      (select(messages)
            ..where((tbl) => tbl.conversationId.equals(conversationId))
            ..orderBy([
              (tbl) => OrderingTerm(
                expression: tbl.createdAt,
              ),
            ]))
          .get();

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

  Future<bool> messageExists(String id) =>
      (selectOnly(messages)
            ..addColumns([messages.id.count()])
            ..where(messages.id.equals(id)))
          .map((row) => row.read(messages.id.count()) ?? 0)
          .getSingle()
          .then((result) => result > 0);

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
}
