// ignore_for_file: prefer-async-await
// Required: Existing Future chains preserve callback flow.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_tools.dart';
import 'package:drift/drift.dart';

part 'conversation_tools_dao.g.dart';

@DriftAccessor(tables: [ConversationTools])
class ConversationToolsDao extends DatabaseAccessor<AppDatabase>
    with _$ConversationToolsDaoMixin {
  ConversationToolsDao(super.attachedDatabase);

  /// Get a specific conversation tool setting
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

  /// Get all conversation tool settings for a conversation
  Future<List<ConversationToolsTable>> getConversationTools(
    String conversationId,
  ) =>
      (select(conversationTools)
            ..where((tbl) => tbl.conversationId.equals(conversationId))
            ..orderBy([
              (tbl) => OrderingTerm(expression: tbl.toolId),
            ]))
          .get();

  /// Upsert a conversation tool setting (enabled with permission)
  Future<ConversationToolsTable> upsertConversationTool(
    String conversationId,
    String toolId, {
    required bool isEnabled,
    required PermissionAccess permission,
  }) {
    return into(conversationTools).insertReturning(
      ConversationToolsCompanion(
        conversationId: Value(conversationId),
        toolId: Value(toolId),
        isEnabled: Value(isEnabled),
        permissions: Value(permission),
      ),
      onConflict: DoUpdate(
        (old) => ConversationToolsCompanion(
          updatedAt: Value(DateTime.now()),
          isEnabled: Value(isEnabled),
          permissions: Value(permission),
        ),
      ),
    );
  }

  /// Set whether a tool is enabled for a conversation
  Future<ConversationToolsTable> setConversationToolEnabled(
    String conversationId,
    String toolId, {
    required bool isEnabled,
  }) async {
    // Check if exists first
    final existing = await getConversationTool(conversationId, toolId);

    if (existing != null) {
      // Update existing
      final _ =
          await (update(conversationTools)..where(
                (tbl) =>
                    tbl.conversationId.equals(conversationId) &
                    tbl.toolId.equals(toolId),
              ))
              .write(
                ConversationToolsCompanion(
                  updatedAt: Value(DateTime.now()),
                  isEnabled: Value(isEnabled),
                ),
              );
      final updated = await getConversationTool(conversationId, toolId);
      if (updated == null) {
        throw StateError('Updated conversation tool was not found');
      }
      return updated;
    } else {
      // Insert new
      return into(conversationTools).insertReturning(
        ConversationToolsCompanion(
          conversationId: Value(conversationId),
          toolId: Value(toolId),
          isEnabled: Value(isEnabled),
        ),
      );
    }
  }

  /// Set the permission for a conversation tool
  Future<ConversationToolsTable> setConversationToolPermission(
    String conversationId,
    String toolId, {
    required PermissionAccess permission,
  }) async {
    final existing = await getConversationTool(conversationId, toolId);

    if (existing != null) {
      final _ =
          await (update(conversationTools)..where(
                (tbl) =>
                    tbl.conversationId.equals(conversationId) &
                    tbl.toolId.equals(toolId),
              ))
              .write(
                ConversationToolsCompanion(
                  updatedAt: Value(DateTime.now()),
                  permissions: Value(permission),
                ),
              );
      final updated = await getConversationTool(conversationId, toolId);
      if (updated == null) {
        throw StateError('Updated conversation tool was not found');
      }
      return updated;
    } else {
      return into(conversationTools).insertReturning(
        ConversationToolsCompanion(
          conversationId: Value(conversationId),
          toolId: Value(toolId),
          isEnabled: const Value(true),
          permissions: Value(permission),
        ),
      );
    }
  }

  /// Delete a conversation tool setting
  Future<bool> deleteConversationTool(
    String conversationId,
    String toolId,
  ) =>
      (delete(conversationTools)..where(
            (tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.toolId.equals(toolId),
          ))
          .go()
          .then((count) => count > 0);

  /// Check if a tool is enabled for a conversation
  Future<bool> isConversationToolEnabled(
    String conversationId,
    String toolId,
  ) async {
    final tool = await getConversationTool(conversationId, toolId);
    // If no override exists, tool follows workspace setting
    // (considered enabled)
    return tool?.isEnabled ?? true;
  }

  /// Get count of conversation tool settings
  Future<int> getConversationToolsCount(String conversationId) =>
      (selectOnly(conversationTools)
            ..addColumns([conversationTools.id.count()])
            ..where(
              conversationTools.conversationId.equals(conversationId),
            ))
          .map((row) => row.read(conversationTools.id.count()) ?? 0)
          .getSingle();

  /// Remove all tool settings for a conversation
  Future<void> removeToolsForConversation(String conversationId) => (delete(
    conversationTools,
  )..where((tbl) => tbl.conversationId.equals(conversationId))).go();

  /// Copy conversation tools from one conversation to another
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

  // Legacy methods for backward compatibility
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
            conversationId: Value(conversationId),
            toolId: Value(toolId),
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
