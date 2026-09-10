import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/conversation_skills.dart';
import 'package:drift/drift.dart';

part 'conversation_skills_dao.g.dart';

@DriftAccessor(tables: [ConversationSkills])
class ConversationSkillsDao(super.attachedDatabase)
    extends DatabaseAccessor<AppDatabase>
    with _$ConversationSkillsDaoMixin;

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
    Future<ConversationSkillsTable?> find() =>
        getConversationWorkspaceSkill(conversationId, workspaceSkillId);

    return await _setSkillLoaded(
      find,
      _workspaceSkillMutation(conversationId, workspaceSkillId, isLoaded),
    );
  }

  Future<ConversationSkillsTable> setAppSkillLoaded(
    String conversationId,
    String appSkillIdentifier, {
    required bool isLoaded,
  }) async {
    Future<ConversationSkillsTable?> find() =>
        getConversationAppSkill(conversationId, appSkillIdentifier);

    return await _setSkillLoaded(
      find,
      _appSkillMutation(conversationId, appSkillIdentifier, isLoaded),
    );
  }
}

extension ConversationSkillsDaoPersistence on ConversationSkillsDao {
  ({
    ConversationSkillsCompanion insert,
    ConversationSkillsCompanion update,
    String error,
  })
  _workspaceSkillMutation(String conversationId, String id, bool isLoaded) =>
      _skillMutation(
        .new(
          conversationId: .new(conversationId),
          workspaceSkillId: .new(id),
          isLoaded: .new(isLoaded),
        ),
        isLoaded,
        'Updated conversation skill was not found',
      );

  ({
    ConversationSkillsCompanion insert,
    ConversationSkillsCompanion update,
    String error,
  })
  _appSkillMutation(String conversationId, String id, bool isLoaded) =>
      _skillMutation(
        .new(
          conversationId: .new(conversationId),
          appSkillIdentifier: .new(id),
          isLoaded: .new(isLoaded),
        ),
        isLoaded,
        'Updated conversation app skill was not found',
      );

  Future<ConversationSkillsTable> _setSkillLoaded(
    Future<ConversationSkillsTable?> Function() find,
    ({
      ConversationSkillsCompanion insert,
      ConversationSkillsCompanion update,
      String error,
    })
    mutation,
  ) async {
    final existing = await find();
    if (existing == null) {
      return await into(conversationSkills).insertReturning(mutation.insert);
    }

    final _ = await _updateSkill(existing.id, mutation.update);

    return await _requireUpdatedSkill(find, mutation.error);
  }

  Future<int> _updateSkill(String id, ConversationSkillsCompanion mutation) =>
      (update(
        conversationSkills,
      )..where((tbl) => tbl.id.equals(id))).write(mutation);

  ({
    ConversationSkillsCompanion insert,
    ConversationSkillsCompanion update,
    String error,
  })
  _skillMutation(
    ConversationSkillsCompanion insert,
    bool isLoaded,
    String error,
  ) => (
    insert: insert,
    update: ConversationSkillsCompanion(
      updatedAt: .new(DateTime.now()),
      isLoaded: .new(isLoaded),
    ),
    error: error,
  );

  Future<ConversationSkillsTable> _requireUpdatedSkill(
    Future<ConversationSkillsTable?> Function() find,
    String notFoundMessage,
  ) async {
    final updated = await find();
    if (updated == null) {
      throw StateError(notFoundMessage);
    }

    return updated;
  }
}
