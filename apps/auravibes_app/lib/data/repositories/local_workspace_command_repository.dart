import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

/// Stores no content: only operation digest and host-verified resource identities.
class const LocalWorkspaceCommandRepository(final AppDatabase database) {
  Future<Map<String, Object?>> execute({
    required String workspaceId,
    required String conversationId,
    required String selectionId,
    required String requestId,
    required Map<String, dynamic> arguments,
    required Future<Map<String, Object?>> Function() run,
    required Future<void> Function(Map<String, Object?>) authorizeReplay,
  }) => database.transaction(() async {
    final digest = sha256
        .convert(utf8.encode(jsonEncode(_canonical(arguments))))
        .toString();
    final query = database.select(database.workspaceCommandReceipts)
      ..where(
        (row) =>
            row.workspaceId.equals(workspaceId) &
            row.conversationId.equals(conversationId) &
            row.requestId.equals(requestId),
      );
    final previous = await query.getSingleOrNull();
    if (previous != null) {
      if (previous.digest != digest || previous.selectionId != selectionId)
        throw const WorkspaceTableException(conflict: true);
      final result = (jsonDecode(previous.result) as Map<String, dynamic>)
          .cast<String, Object?>();
      await authorizeReplay(result);
      return result;
    }
    final result = await run();
    final receipt = {
      for (final key in [
        'id',
        'kind',
        'revision',
        'schemaRevision',
        'tableId',
        'parentId',
      ])
        if (result.containsKey(key)) key: result[key],
    };
    if (receipt['id'] is! String) throw const WorkspaceTableException();
    final _ = await database
        .into(database.workspaceCommandReceipts)
        .insert(
          WorkspaceCommandReceiptsCompanion.insert(
            workspaceId: workspaceId,
            conversationId: conversationId,
            selectionId: selectionId,
            requestId: requestId,
            digest: digest,
            result: jsonEncode(receipt),
            created: (arguments['action'] as String).startsWith('create'),
          ),
        );
    return result;
  });

  Future<List<Map<String, Object?>>> created(
    String workspaceId,
    String conversationId,
    String selectionId,
  ) async {
    final query = database.select(database.workspaceCommandReceipts)
      ..where(
        (row) =>
            row.workspaceId.equals(workspaceId) &
            row.conversationId.equals(conversationId) &
            row.selectionId.equals(selectionId) &
            row.created.equals(true),
      );
    return [
      for (final row in await query.get())
        (jsonDecode(row.result) as Map<String, dynamic>)
            .cast<String, Object?>(),
    ];
  }
}

Object? _canonical(Object? value) => switch (value) {
  final Map<String, dynamic> map => {
    for (final key in map.keys.toList()..sort()) key: _canonical(map[key]),
  },
  final List<Object?> list => list.map(_canonical).toList(),
  _ => value,
};
