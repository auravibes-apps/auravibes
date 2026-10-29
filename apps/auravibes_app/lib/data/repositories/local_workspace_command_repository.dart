import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/workspace_command_receipts.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

typedef WorkspaceReceiptWrite = ({
  String workspaceId,
  String conversationId,
  String selectionId,
  String requestId,
  Map<String, dynamic> arguments,
  Future<Map<String, Object?>> Function() run,
  Future<void> Function(Map<String, Object?>) authorizeReplay,
});

/// Persists operation digests and resource identities without content.
class const LocalWorkspaceCommandRepository(final AppDatabase database) {
  Future<Map<String, Object?>> execute(WorkspaceReceiptWrite request) =>
      database.transaction(_ReceiptTransaction(database, request).execute);

  Future<List<WorkspaceCommandReceiptRow>> receiptPage(
    String workspaceId,
    String conversationId,
    String? cursor,
  ) => _ReceiptRows(database, workspaceId, conversationId).receiptPage(cursor);
}

class _ReceiptTransaction(
  final AppDatabase database,
  final WorkspaceReceiptWrite request,
) {
  final String digest = _ReceiptCodec.digest(request.arguments);
  _ReceiptRows get rows =>
      _ReceiptRows(database, request.workspaceId, request.conversationId);

  Future<Map<String, Object?>> execute() async {
    final previous = await rows.find(request.requestId);
    if (previous != null) return await _replay(previous);
    final result = await request.run();
    await _save(_ReceiptCodec.metadata(result));

    return result;
  }

  Future<Map<String, Object?>> _replay(
    WorkspaceCommandReceiptRow previous,
  ) async {
    if (previous.digest != digest) {
      throw const WorkspaceTableException(conflict: true);
    }
    final result = _ReceiptCodec.decode(previous.result);
    await request.authorizeReplay(result);

    return result;
  }

  Future<void> _save(Map<String, Object?> metadata) async {
    final _ = await database
        .into(database.workspaceCommandReceipts)
        .insert(_entry(metadata));
  }

  WorkspaceCommandReceiptsCompanion _entry(Map<String, Object?> metadata) =>
      WorkspaceCommandReceiptsCompanion.insert(
        workspaceId: request.workspaceId,
        conversationId: request.conversationId,
        selectionId: request.selectionId,
        requestId: request.requestId,
        digest: digest,
        result: jsonEncode(metadata),
        created: (request.arguments['action'] as String).startsWith('create'),
      );
}

class const _ReceiptRows(
  final AppDatabase database,
  final String workspaceId,
  final String conversationId,
) {
  Future<WorkspaceCommandReceiptRow?> find(String requestId) {
    final query = database.select(database.workspaceCommandReceipts)
      ..where((row) => _scope(row) & row.requestId.equals(requestId));

    return query.getSingleOrNull();
  }

  Future<List<WorkspaceCommandReceiptRow>> receiptPage(String? cursor) {
    final query = database.select(database.workspaceCommandReceipts)
      ..where((row) => _pageScope(row, cursor))
      ..orderBy([(row) => OrderingTerm.asc(row.requestId)])
      ..limit(101);

    return query.get();
  }

  Expression<bool> _pageScope(WorkspaceCommandReceipts row, String? cursor) =>
      _scope(row) &
      (cursor == null
          ? const Constant(true)
          : row.requestId.isBiggerThanValue(cursor));

  Expression<bool> _scope(WorkspaceCommandReceipts row) =>
      row.workspaceId.equals(workspaceId) &
      row.conversationId.equals(conversationId);
}

abstract final class _ReceiptCodec {
  static const _metadataKeys = [
    'id',
    'kind',
    'revision',
    'schemaRevision',
    'tableId',
    'parentId',
  ];

  static Map<String, Object?> decode(String value) =>
      (jsonDecode(value) as Map<String, dynamic>).cast<String, Object?>();

  static String digest(Map<String, dynamic> arguments) =>
      sha256.convert(utf8.encode(jsonEncode(_canonical(arguments)))).toString();

  static Map<String, Object?> metadata(Map<String, Object?> result) {
    final metadata = {
      for (final key in _metadataKeys)
        if (result.containsKey(key)) key: result[key],
    };
    if (metadata['id'] is! String) throw const WorkspaceTableException();

    return metadata;
  }
}

Object? _canonical(Object? value) => switch (value) {
  final Map<String, dynamic> map => {
    for (final key in map.keys.toList()..sort()) key: _canonical(map[key]),
  },
  final List<Object?> list => list.map(_canonical).toList(),
  _ => value,
};
