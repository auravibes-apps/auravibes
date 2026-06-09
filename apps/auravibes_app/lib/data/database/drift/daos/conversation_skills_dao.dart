// ignore_for_file: prefer-async-await
// Required: Existing Future chains preserve callback flow.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_skills.dart';
import 'package:drift/drift.dart';

part 'conversation_skills_dao.g.dart';

@DriftAccessor(tables: [ConversationSkills])
class ConversationSkillsDao extends DatabaseAccessor<AppDatabase>
    with _$ConversationSkillsDaoMixin {
  ConversationSkillsDao(super.attachedDatabase);

  Future<List<ConversationSkillsTable>> getConversationSkills(
    String conversationId,
  ) =>
      (select(conversationSkills)
            ..where((tbl) => tbl.conversationId.equals(conversationId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
          .get();

  Future<ConversationSkillsTable?> getConversationWorkspaceSkill(
    String conversationId,
    String workspaceSkillId,
  ) =>
      (select(conversationSkills)..where(
            (tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.workspaceSkillId.equals(workspaceSkillId),
          ))
          .getSingleOrNull();

  Future<ConversationSkillsTable?> getConversationAppSkill(
    String conversationId,
    String appSkillIdentifier,
  ) =>
      (select(conversationSkills)..where(
            (tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.appSkillIdentifier.equals(appSkillIdentifier),
          ))
          .getSingleOrNull();

  Future<ConversationSkillsTable> setWorkspaceSkillLoaded(
    String conversationId,
    String workspaceSkillId, {
    required bool isLoaded,
  }) async {
    final existing = await getConversationWorkspaceSkill(
      conversationId,
      workspaceSkillId,
    );
    if (existing == null) {
      return into(conversationSkills).insertReturning(
        ConversationSkillsCompanion(
          conversationId: Value(conversationId),
          workspaceSkillId: Value(workspaceSkillId),
          isLoaded: Value(isLoaded),
        ),
      );
    }

    final _ =
        await (update(conversationSkills)..where(
              (tbl) => tbl.id.equals(existing.id),
            ))
            .write(
              ConversationSkillsCompanion(
                updatedAt: Value(DateTime.now()),
                isLoaded: Value(isLoaded),
              ),
            );
    final updated = await getConversationWorkspaceSkill(
      conversationId,
      workspaceSkillId,
    );
    if (updated == null) {
      throw StateError('Updated conversation skill was not found');
    }
    return updated;
  }

  Future<ConversationSkillsTable> setAppSkillLoaded(
    String conversationId,
    String appSkillIdentifier, {
    required bool isLoaded,
  }) async {
    final existing = await getConversationAppSkill(
      conversationId,
      appSkillIdentifier,
    );
    if (existing == null) {
      return into(conversationSkills).insertReturning(
        ConversationSkillsCompanion(
          conversationId: Value(conversationId),
          appSkillIdentifier: Value(appSkillIdentifier),
          isLoaded: Value(isLoaded),
        ),
      );
    }

    final _ =
        await (update(conversationSkills)..where(
              (tbl) => tbl.id.equals(existing.id),
            ))
            .write(
              ConversationSkillsCompanion(
                updatedAt: Value(DateTime.now()),
                isLoaded: Value(isLoaded),
              ),
            );
    final updated = await getConversationAppSkill(
      conversationId,
      appSkillIdentifier,
    );
    if (updated == null) {
      throw StateError('Updated conversation app skill was not found');
    }
    return updated;
  }
}
