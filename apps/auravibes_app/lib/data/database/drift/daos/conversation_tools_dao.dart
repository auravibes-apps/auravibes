import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_tools.dart';
import 'package:drift/drift.dart';

part 'conversation_tools_dao.g.dart';

@DriftAccessor(tables: [ConversationTools])
class ConversationToolsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$ConversationToolsDaoMixin;

extension ConversationToolsDaoPrimaryOperations on ConversationToolsDao {
  /// Get a specific conversation tool setting.
  Future<ConversationToolsTable?> getConversationTool(
    String conversationId,
    String toolId,
  ) =>
      (select(conversationTools)..where(
            (tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.toolId.equals(toolId),
          ))
          .getSingleOrNull();

  /// Get all conversation tool settings for a conversation.
  Future<List<ConversationToolsTable>> getConversationTools(
    String conversationId,
  ) =>
      (select(conversationTools)
            ..where((tbl) => tbl.conversationId.equals(conversationId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.toolId)]))
          .get();

  /// Upsert a conversation tool setting (enabled with permission).
  Future<ConversationToolsTable> Function(
    String,
    String, {
    required bool isEnabled,
    required PermissionAccess permission,
  })
  get upsertConversationTool =>
      (conversationId, toolId, {required isEnabled, required permission}) =>
          _upsertConversationTool(
            (conversationId: conversationId, toolId: toolId),
            (isEnabled: isEnabled, permission: permission),
          );

  Future<ConversationToolsTable> _upsertConversationTool(
    ({String conversationId, String toolId}) ids,
    ({bool isEnabled, PermissionAccess permission}) state,
  ) {
    return into(conversationTools).insertReturning(
      _conversationToolInsertCompanion(ids, state),
      onConflict: DoUpdate(
        (_) =>
            _conversationToolUpdateCompanion(state.isEnabled, state.permission),
      ),
    );
  }

  /// Set whether a tool is enabled for a conversation.
  Future<ConversationToolsTable> setConversationToolEnabled(
    String conversationId,
    String toolId, {
    required bool isEnabled,
  }) async {
    // Check if exists first.
    final existing = await getConversationTool(conversationId, toolId);

    if (existing == null) {
      return await _insertConversationTool(conversationId, toolId, isEnabled);
    }

    return await _updateAndRequireConversationTool(
      (conversationId: conversationId, toolId: toolId),
      .new(updatedAt: .new(DateTime.now()), isEnabled: .new(isEnabled)),
      'Updated conversation tool was not found',
    );
  }

  /// Set the permission for a conversation tool.
  Future<ConversationToolsTable> setConversationToolPermission(
    String conversationId,
    String toolId, {
    required PermissionAccess permission,
  }) async {
    final existing = await getConversationTool(conversationId, toolId);

    if (existing == null) {
      return await _insertConversationToolWithPermission(
        conversationId,
        toolId,
        permission,
      );
    }

    return await _updateAndRequireConversationTool(
      (conversationId: conversationId, toolId: toolId),
      _permissionUpdate(permission),
      'Updated conversation tool was not found',
    );
  }

  /// Delete a conversation tool setting.
  Future<bool> deleteConversationTool(
    String conversationId,
    String toolId,
  ) async {
    final count =
        await (delete(conversationTools)..where(
              (tbl) =>
                  tbl.conversationId.equals(conversationId) &
                  tbl.toolId.equals(toolId),
            ))
            .go();

    return count > 0;
  }
}

extension ConversationToolsDaoStateOperations on ConversationToolsDao {
  /// Check if a tool is enabled for a conversation.
  Future<bool> isConversationToolEnabled(
    String conversationId,
    String toolId,
  ) async {
    final tool = await getConversationTool(conversationId, toolId);

    // If no override exists, tool follows workspace setting.
    // (Considered enabled).
    return tool?.isEnabled ?? true;
  }

  /// Get count of conversation tool settings.
  Future<int> getConversationToolsCount(String conversationId) =>
      (selectOnly(conversationTools)
            ..addColumns([conversationTools.id.count()])
            ..where(conversationTools.conversationId.equals(conversationId)))
          .map((row) => row.read(conversationTools.id.count()) ?? 0)
          .getSingle();

  /// Remove all tool settings for a conversation.
  Future<void> removeToolsForConversation(String conversationId) => (delete(
    conversationTools,
  )..where((tbl) => tbl.conversationId.equals(conversationId))).go();

  /// Copy conversation tools from one conversation to another.
  Future<void> copyConversationTools(
    String sourceConversationId,
    String targetConversationId,
  ) async {
    final sourceTools = await getConversationTools(sourceConversationId);

    for (final tool in sourceTools) {
      final _ = await upsertConversationTool(
        targetConversationId,
        tool.toolId,
        isEnabled: tool.isEnabled,
        permission: tool.permissions,
      );
    }
  }
}

extension ConversationToolsDaoLegacyOperations on ConversationToolsDao {
  // Legacy methods for backward compatibility.
  Future<ConversationToolsTable?> getDisabledConversationTool(
    String conversationId,
    String toolId,
  ) => getConversationTool(conversationId, toolId);

  Future<void> disableConversationTools(
    String conversationId,
    List<String> toolIds,
  ) {
    return batch((batch) {
      batch.insertAllOnConflictUpdate(conversationTools, [
        for (final toolId in toolIds)
          ConversationToolsCompanion(
            conversationId: .new(conversationId),
            toolId: .new(toolId),
            isEnabled: const Value(false),
          ),
      ]);
    });
  }

  Future<bool> enableConversationTool(String conversationId, String toolId) =>
      deleteConversationTool(conversationId, toolId);

  Future<bool> toggleConversationTool(
    String conversationId,
    String toolId,
  ) async {
    final tool = await getConversationTool(conversationId, toolId);
    final isCurrentlyEnabled = tool?.isEnabled ?? true;

    final _ = await setConversationToolEnabled(
      conversationId,
      toolId,
      isEnabled: !isCurrentlyEnabled,
    );

    return true;
  }

  Future<bool> isConversationToolDisabled(
    String conversationId,
    String toolId,
  ) async {
    final isEnabled = await isConversationToolEnabled(conversationId, toolId);

    return !isEnabled;
  }

  Future<List<ConversationToolsTable>> getDisabledConversationTools(
    String conversationId,
  ) async {
    final tools = await getConversationTools(conversationId);

    return tools.where((t) => !t.isEnabled).toList();
  }

  Future<int> getDisabledConversationToolsCount(String conversationId) async {
    final disabled = await getDisabledConversationTools(conversationId);

    return disabled.length;
  }

  Future<void> removeDisabledToolsForConversation(String conversationId) =>
      removeToolsForConversation(conversationId);
}

extension ConversationToolsDaoPersistence on ConversationToolsDao {
  ConversationToolsCompanion _permissionUpdate(PermissionAccess permission) =>
      .new(updatedAt: .new(DateTime.now()), permissions: .new(permission));

  Future<ConversationToolsTable> _insertConversationTool(
    String conversationId,
    String toolId,
    bool isEnabled,
  ) => into(conversationTools).insertReturning(
    ConversationToolsCompanion(
      conversationId: .new(conversationId),
      toolId: .new(toolId),
      isEnabled: .new(isEnabled),
    ),
  );

  Future<ConversationToolsTable> _insertConversationToolWithPermission(
    String conversationId,
    String toolId,
    PermissionAccess permission,
  ) => into(conversationTools).insertReturning(
    ConversationToolsCompanion(
      conversationId: .new(conversationId),
      toolId: .new(toolId),
      isEnabled: const Value(true),
      permissions: .new(permission),
    ),
  );

  ConversationToolsCompanion _conversationToolInsertCompanion(
    ({String conversationId, String toolId}) ids,
    ({bool isEnabled, PermissionAccess permission}) state,
  ) => ConversationToolsCompanion(
    conversationId: .new(ids.conversationId),
    toolId: .new(ids.toolId),
    isEnabled: .new(state.isEnabled),
    permissions: .new(state.permission),
  );

  ConversationToolsCompanion _conversationToolUpdateCompanion(
    bool isEnabled,
    PermissionAccess permission,
  ) => ConversationToolsCompanion(
    updatedAt: .new(DateTime.now()),
    isEnabled: .new(isEnabled),
    permissions: .new(permission),
  );

  Future<int> _updateConversationTool(
    String conversationId,
    String toolId,
    ConversationToolsCompanion companion,
  ) =>
      (update(conversationTools)..where(
            (tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.toolId.equals(toolId),
          ))
          .write(companion);

  Future<ConversationToolsTable> _updateAndRequireConversationTool(
    ({String conversationId, String toolId}) ids,
    ConversationToolsCompanion companion,
    String error,
  ) async {
    final _ = await _updateConversationTool(
      ids.conversationId,
      ids.toolId,
      companion,
    );

    return await _requireConversationTool(
      ids.conversationId,
      ids.toolId,
      error,
    );
  }

  Future<ConversationToolsTable> _requireConversationTool(
    String conversationId,
    String toolId,
    String notFoundMessage,
  ) async {
    final updated = await getConversationTool(conversationId, toolId);
    if (updated == null) {
      throw StateError(notFoundMessage);
    }

    return updated;
  }
}
