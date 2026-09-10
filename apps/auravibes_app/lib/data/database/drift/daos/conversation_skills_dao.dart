import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_skills.dart';
import 'package:drift/drift.dart';

part 'conversation_skills_dao.g.dart';

@DriftAccessor(tables: [ConversationSkills])
class ConversationSkillsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$ConversationSkillsDaoMixin {}

extension ConversationSkillsDaoMethods on ConversationSkillsDao {
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
    return _setSkillLoaded(
      find: () =>
          getConversationWorkspaceSkill(conversationId, workspaceSkillId),
      insert: ConversationSkillsCompanion(
        conversationId: .new(conversationId),
        workspaceSkillId: .new(workspaceSkillId),
        isLoaded: .new(isLoaded),
      ),
      update: ConversationSkillsCompanion(
        updatedAt: .new(DateTime.now()),
        isLoaded: .new(isLoaded),
      ),
      notFoundMessage: 'Updated conversation skill was not found',
    );
  }

  Future<ConversationSkillsTable> setAppSkillLoaded(
    String conversationId,
    String appSkillIdentifier, {
    required bool isLoaded,
  }) async {
    return _setSkillLoaded(
      find: () => getConversationAppSkill(conversationId, appSkillIdentifier),
      insert: ConversationSkillsCompanion(
        conversationId: .new(conversationId),
        appSkillIdentifier: .new(appSkillIdentifier),
        isLoaded: .new(isLoaded),
      ),
      update: ConversationSkillsCompanion(
        updatedAt: .new(DateTime.now()),
        isLoaded: .new(isLoaded),
      ),
      notFoundMessage: 'Updated conversation app skill was not found',
    );
  }

  Future<ConversationSkillsTable> _setSkillLoaded({
    required Future<ConversationSkillsTable?> Function() find,
    required ConversationSkillsCompanion insert,
    required ConversationSkillsCompanion update,
    required String notFoundMessage,
  }) async {
    final existing = await find();
    if (existing == null) {
      return into(conversationSkills).insertReturning(insert);
    }

    await (this.update(
      conversationSkills,
    )..where((tbl) => tbl.id.equals(existing.id))).write(update);
    final updated = await find();
    if (updated == null) {
      throw StateError(notFoundMessage);
    }

    return updated;
  }
}
