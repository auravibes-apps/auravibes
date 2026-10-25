import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:drift/drift.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_conversation_context.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Only explicit host controls write these events; transcript imports cannot.
class const LocalWorkspaceContextRepository(
  final AppDatabase database,
  final String workspaceId,
) implements WorkspaceConversationContextRepository {
  @override
  Future<WorkspaceConversationContext> read(String conversationId) async {
    final value = await latest(workspaceId, conversationId);
    return WorkspaceConversationContext(
      id: value?.id,
      selection: WorkspaceContextSelection.decode(
        value?.selection,
        workspaceId,
        conversationId,
      ),
    );
  }

  @override
  Future<WorkspaceConversationContext> save(
    String conversationId,
    String requestId,
    WorkspaceContextSelection? selection,
  ) async {
    await _save(
      workspaceId: workspaceId,
      conversationId: conversationId,
      requestId: requestId,
      selection: selection?.toJson(),
    );
    return WorkspaceConversationContext(id: requestId, selection: selection);
  }

  Future<({String id, Map<String, dynamic>? selection})?> latest(
    String workspaceId,
    String conversationId,
  ) async {
    final row = await database
        .customSelect(
          'SELECT id, selection FROM workspace_context_selections '
          'WHERE workspace_id = ? AND conversation_id = ? ORDER BY rowid DESC LIMIT 1',
          variables: [
            Variable<String>(workspaceId),
            Variable<String>(conversationId),
          ],
          readsFrom: {database.workspaceContextSelections},
        )
        .getSingleOrNull();
    if (row == null) return null;
    final value = row.readNullable<String>('selection');
    return (
      id: row.read<String>('id'),
      selection: value == null
          ? null
          : jsonDecode(value) as Map<String, dynamic>,
    );
  }

  Future<void> _save({
    required String workspaceId,
    required String conversationId,
    required String requestId,
    required Map<String, Object?>? selection,
  }) => database.transaction(() async {
    final existing = await (database.select(
      database.workspaceContextSelections,
    )..where((row) => row.id.equals(requestId))).getSingleOrNull();
    final encoded = selection == null ? null : jsonEncode(selection);
    if (existing != null) {
      if (existing.workspaceId != workspaceId ||
          existing.conversationId != conversationId ||
          existing.selection != encoded) {
        throw const WorkspaceTableException(conflict: true);
      }
      return;
    }
    final _ = await database
        .into(database.workspaceContextSelections)
        .insert(
          WorkspaceContextSelectionsCompanion.insert(
            id: requestId,
            workspaceId: workspaceId,
            conversationId: conversationId,
            selection: Value(encoded),
          ),
        );
  });
}
