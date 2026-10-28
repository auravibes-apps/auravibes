import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_conversation_context.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Host-owned context events are never derived from transcript imports.
class const LocalWorkspaceContextRepository(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceConversationContextRepository {
  @override
  Future<WorkspaceConversationContext> read(String conversationId) async {
    final value = await latest(workspaceId, conversationId);

    return WorkspaceConversationContext(
      id: value?.id,
      selection: .decode(value?.selection, workspaceId, conversationId),
    );
  }

  /// Establishes a root context only for conversations with no prior event.
  Future<WorkspaceConversationContext> readOrInitialize(
    String conversationId,
  ) => database.transaction(() async {
    final current = await read(conversationId);
    if (current.id != null) return current;

    return await save(
      conversationId,
      const Uuid().v4(),
      .new(
        workspaceId: workspaceId,
        conversationId: conversationId,
        itemId: '',
        kind: 'directory',
      ),
    );
  });

  @override
  Future<WorkspaceConversationContext> save(
    String conversationId,
    String requestId,
    WorkspaceContextSelection? selection,
  ) async {
    final write = _SelectionWrite(database, (
      workspaceId: workspaceId,
      conversationId: conversationId,
      requestId: requestId,
      encoded: selection == null ? null : jsonEncode(selection.toJson()),
    ));
    await database.transaction(write.save);

    return WorkspaceConversationContext(id: requestId, selection: selection);
  }

  Future<({String id, Map<String, dynamic>? selection})?> latest(
    String workspaceId,
    String conversationId,
  ) async {
    final row = await _latestRow(workspaceId, conversationId);
    if (row == null) return null;
    final value = row.readNullable<String>('selection');

    return (
      id: row.read<String>('id'),
      selection: value == null
          ? null
          : jsonDecode(value) as Map<String, dynamic>,
    );
  }

  Future<QueryRow?> _latestRow(String workspaceId, String conversationId) =>
      database
          .customSelect(
            'SELECT id, selection FROM workspace_context_selections '
            'WHERE workspace_id = ? AND conversation_id = ? '
            'ORDER BY rowid DESC LIMIT 1',
            variables: [
              Variable<String>(workspaceId),
              Variable<String>(conversationId),
            ],
            readsFrom: {database.workspaceContextSelections},
          )
          .getSingleOrNull();
}

typedef _SelectionValues = ({
  String workspaceId,
  String conversationId,
  String requestId,
  String? encoded,
});

class const _SelectionWrite(
  final AppDatabase database,
  final _SelectionValues values,
) {
  Future<void> save() async {
    final existing = await _existing();
    if (existing != null) {
      _validate(existing);

      return;
    }
    final _ = await database
        .into(database.workspaceContextSelections)
        .insert(_entry());
  }

  Future<WorkspaceContextSelectionRow?> _existing() => (database.select(
    database.workspaceContextSelections,
  )..where((row) => row.id.equals(values.requestId))).getSingleOrNull();

  void _validate(WorkspaceContextSelectionRow existing) {
    if (existing.workspaceId != values.workspaceId ||
        existing.conversationId != values.conversationId ||
        existing.selection != values.encoded) {
      throw const WorkspaceTableException(conflict: true);
    }
  }

  WorkspaceContextSelectionsCompanion _entry() =>
      WorkspaceContextSelectionsCompanion.insert(
        id: values.requestId,
        workspaceId: values.workspaceId,
        conversationId: values.conversationId,
        selection: .new(values.encoded),
      );
}
