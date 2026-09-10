import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/messages.dart';
import 'package:drift/drift.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [Messages])
class MessageDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$MessageDaoMixin {}

extension MessageDaoMethods on MessageDao {
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

    final rows = await _latestAssistantMessagesQuery(conversationIds).get();

    return rows.map(_messageFromRow).toList();
  }

  Stream<MessagesTable?> watchLatestAssistantMessageByConversation(
    String conversationId,
  ) => _latestAssistantMessageQuery(conversationId).watchSingleOrNull();

  Stream<List<MessagesTable>> watchMessagesByConversation(
    String conversationId,
  ) => _messagesByConversationQuery(conversationId).watch();

  Future<List<MessagesTable>> getMessagesByConversationPaginated(
    String conversationId,
    int limit,
    int offset,
  ) =>
      (select(messages)
            ..where((tbl) => tbl.conversationId.equals(conversationId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)])
            ..limit(limit, offset: offset))
          .get();

  Future<List<MessagesTable>> getMessagesByType(
    String conversationId,
    MessagesTableType messageType,
  ) => _messagesByTypeQuery(conversationId, messageType).get();

  Future<List<MessagesTable>> getUserMessages(String conversationId) =>
      (select(messages)
            ..where(
              (tbl) =>
                  tbl.conversationId.equals(conversationId) &
                  tbl.isUser.equals(true),
            )
            ..orderBy([
              (tbl) => OrderingTerm(expression: tbl.createdAt, mode: .desc),
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
              (tbl) => OrderingTerm(expression: tbl.createdAt, mode: .desc),
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
  ) => _messagesByStatusQuery(conversationId, status).get();

  Future<MessagesTable?> getLatestCompactionSummary(
    String conversationId,
  ) async {
    final rows = await _compactionSummaryCandidates(conversationId).get();

    return _findCompactionSummary(rows);
  }

  Selectable<QueryRow> _latestAssistantMessagesQuery(
    List<String> conversationIds,
  ) {
    return customSelect(
      _latestAssistantMessagesSql(conversationIds.length),
      variables: _latestAssistantMessagesVariables(conversationIds),
      readsFrom: {messages},
    );
  }

  String _latestAssistantMessagesSql(int conversationCount) =>
      '''
    SELECT * FROM (
      SELECT *,
        ROW_NUMBER() OVER (
          PARTITION BY conversation_id
          ORDER BY created_at DESC, id DESC
        ) AS row_number
      FROM messages
      WHERE is_user = 0 AND conversation_id IN (
        ${List.filled(conversationCount, '?').join(', ')}
      )
    )
    WHERE row_number = 1
    ''';

  List<Variable> _latestAssistantMessagesVariables(
    List<String> conversationIds,
  ) => [for (final conversationId in conversationIds) Variable(conversationId)];

  MessagesTable _messageFromRow(QueryRow row) =>
      MessagesTable.fromJson(_messageJson(row));

  Map<String, dynamic> _messageJson(QueryRow row) => {
    ..._messageIdentityJson(row),
    ..._messageContentJson(row),
    ..._messageStateJson(row),
    ..._messageMetadataJson(row),
  };

  Map<String, dynamic> _messageIdentityJson(QueryRow row) => {
    'id': _readRequired<String>(row, 'id'),
    'createdAt': _readRequired<DateTime>(row, 'created_at'),
    'updatedAt': _readRequired<DateTime>(row, 'updated_at'),
  };

  Map<String, dynamic> _messageContentJson(QueryRow row) => {
    'conversationId': _readRequired<String>(row, 'conversation_id'),
    'content': _readRequired<String>(row, 'content'),
  };

  Map<String, dynamic> _messageStateJson(QueryRow row) => {
    'messageType': _messageTypeFromStorage(
      _readRequired<String>(row, 'message_type'),
    ).name,
    'isUser': _readRequired<bool>(row, 'is_user'),
    'status': MessageTableStatus.fromString(
      _readRequired<String>(row, 'status'),
    ).name,
  };

  Map<String, dynamic> _messageMetadataJson(QueryRow row) => {
    'metadata': _readNullable<String>(row, 'metadata'),
  };

  T _readRequired<T extends Object>(QueryRow row, String column) =>
      row.read<T>(column);

  T? _readNullable<T extends Object>(QueryRow row, String column) =>
      row.readNullable<T>(column);

  SimpleSelectStatement<$MessagesTable, MessagesTable>
  _latestAssistantMessageQuery(String conversationId) {
    final query = select(messages)
      ..where((tbl) => _assistantMessageFilter(tbl, conversationId));

    return query
      ..orderBy(_latestAssistantOrdering())
      ..limit(1);
  }

  SimpleSelectStatement<$MessagesTable, MessagesTable> _messagesByTypeQuery(
    String conversationId,
    MessagesTableType messageType,
  ) {
    final query = select(messages)
      ..where((tbl) => _messageTypeFilter(tbl, conversationId, messageType));

    return query..orderBy(_descendingCreatedAtOrdering());
  }

  SimpleSelectStatement<$MessagesTable, MessagesTable> _messagesByStatusQuery(
    String conversationId,
    String status,
  ) {
    final query = select(messages)
      ..where((tbl) => _messageStatusFilter(tbl, conversationId, status));

    return query..orderBy(_descendingCreatedAtOrdering());
  }

  SimpleSelectStatement<$MessagesTable, MessagesTable>
  _compactionSummaryCandidates(String conversationId) {
    final query = select(messages)
      ..where((tbl) => _compactionSummaryFilter(tbl, conversationId));

    return query..orderBy(_descendingCreatedAtOrdering());
  }

  Expression<bool> _assistantMessageFilter(
    $MessagesTable tbl,
    String conversationId,
  ) => tbl.conversationId.equals(conversationId) & tbl.isUser.equals(false);

  Expression<bool> _messageTypeFilter(
    $MessagesTable tbl,
    String conversationId,
    MessagesTableType messageType,
  ) =>
      tbl.conversationId.equals(conversationId) &
      tbl.messageType.equals(messageType.value);

  Expression<bool> _messageStatusFilter(
    $MessagesTable tbl,
    String conversationId,
    String status,
  ) => tbl.conversationId.equals(conversationId) & tbl.status.equals(status);

  Expression<bool> _compactionSummaryFilter(
    $MessagesTable tbl,
    String conversationId,
  ) =>
      _compactionSummaryMessageFilter(tbl, conversationId) &
      tbl.metadata.isNotNull();

  Expression<bool> _compactionSummaryMessageFilter(
    $MessagesTable tbl,
    String conversationId,
  ) =>
      tbl.conversationId.equals(conversationId) &
      tbl.messageType.equals(MessagesTableType.system.value) &
      tbl.status.equals(MessageTableStatus.sent.value);

  List<OrderingTerm Function($MessagesTable)> _latestAssistantOrdering() => [
    (tbl) => OrderingTerm(expression: tbl.createdAt, mode: .desc),
    (tbl) => OrderingTerm(expression: tbl.id, mode: .desc),
  ];

  List<OrderingTerm Function($MessagesTable)> _descendingCreatedAtOrdering() =>
      [(tbl) => OrderingTerm(expression: tbl.createdAt, mode: .desc)];

  MessagesTable? _findCompactionSummary(Iterable<MessagesTable> rows) {
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

  MessagesTableType _messageTypeFromStorage(String value) {
    return MessagesTableType.values.asNameMap()[value] ??
        MessagesTableType.text;
  }

  SimpleSelectStatement<$MessagesTable, MessagesTable>
  _messagesByConversationQuery(String conversationId) {
    return (select(messages)
      ..where((tbl) => tbl.conversationId.equals(conversationId))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]));
  }
}
