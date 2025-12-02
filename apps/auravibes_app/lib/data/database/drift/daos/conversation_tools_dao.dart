import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_tools_table.dart';
import 'package:drift/drift.dart';

part 'conversation_tools_dao.g.dart';

@DriftAccessor(tables: [ConversationTools])
class ConversationToolsDao extends DatabaseAccessor<AppDatabase>
    with _$ConversationToolsDaoMixin {
  ConversationToolsDao(super.attachedDatabase);

  // Core operations for disabled tools
  Future<ConversationToolsTable?> getDisabledConversationTool(
    String conversationId,
    String toolId,
  ) =>
      (select(conversationTools)..where(
            (tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.toolId.equals(toolId),
          ))
          .getSingleOrNull();

  Future<ConversationToolsTable> disableConversationTool(
    String conversationId,
    String toolId,
  ) {
    return into(conversationTools).insertReturning(
      ConversationToolsCompanion(
        conversationId: Value(conversationId),
        toolId: Value(toolId),
      ),
    );
  }

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
          ),
      ]);
    });
  }

  Future<bool> enableConversationTool(String conversationId, String toolId) =>
      (delete(conversationTools)..where(
            (tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.toolId.equals(toolId),
          ))
          .go()
          .then((count) => count > 0);

  Future<bool> toggleConversationTool(
    String conversationId,
    String toolId,
  ) async {
    final isCurrentlyDisabled = await isConversationToolDisabled(
      conversationId,
      toolId,
    );
    if (isCurrentlyDisabled) {
      return enableConversationTool(conversationId, toolId);
    } else {
      await disableConversationTool(conversationId, toolId);
      return true;
    }
  }

  Future<bool> isConversationToolDisabled(
    String conversationId,
    String toolId,
  ) =>
      (selectOnly(conversationTools)
            ..addColumns([conversationTools.id.count()])
            ..where(
              conversationTools.conversationId.equals(conversationId) &
                  conversationTools.toolId.equals(toolId),
            ))
          .map((row) => row.read(conversationTools.id.count()) ?? 0)
          .getSingle()
          .then((result) => result > 0);

  // Query operations for disabled tools
  Future<List<ConversationToolsTable>> getDisabledConversationTools(
    String conversationId,
  ) =>
      (select(conversationTools)
            ..where((tbl) => tbl.conversationId.equals(conversationId))
            ..orderBy([
              (tbl) => OrderingTerm(expression: tbl.toolId),
            ]))
          .get();

  Future<int> getDisabledConversationToolsCount(String conversationId) =>
      (selectOnly(conversationTools)
            ..addColumns([conversationTools.id.count()])
            ..where(
              conversationTools.conversationId.equals(conversationId),
            ))
          .map((row) => row.read(conversationTools.id.count()) ?? 0)
          .getSingle();

  // Bulk operations
  Future<void> removeDisabledToolsForConversation(String conversationId) =>
      (delete(
        conversationTools,
      )..where((tbl) => tbl.conversationId.equals(conversationId))).go();

  Future<void> copyConversationTools(
    String sourceConversationId,
    String targetConversationId,
  ) async {
    // Copy disabled tools from source conversation to target conversation
    final sourceDisabledTools = await getDisabledConversationTools(
      sourceConversationId,
    );

    for (final tool in sourceDisabledTools) {
      await disableConversationTool(targetConversationId, tool.toolId);
    }
  }
}
