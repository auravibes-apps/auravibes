import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/tables/skill_credential_definitions.dart';
import 'package:drift/drift.dart';

part 'skill_credential_definitions_dao.g.dart';

@DriftAccessor(tables: [SkillCredentialDefinitions])
class SkillCredentialDefinitionsDao extends DatabaseAccessor<AppDatabase>
    with _$SkillCredentialDefinitionsDaoMixin {
  SkillCredentialDefinitionsDao(super.attachedDatabase);

  Future<List<SkillCredentialDefinitionsTable>> getDefinitions(
    String workspaceId,
  ) =>
      (select(skillCredentialDefinitions)
            ..where((tbl) => tbl.workspaceId.equals(workspaceId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.title)]))
          .get();

  Stream<List<SkillCredentialDefinitionsTable>> watchDefinitions(
    String workspaceId,
  ) =>
      (select(skillCredentialDefinitions)
            ..where((tbl) => tbl.workspaceId.equals(workspaceId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.title)]))
          .watch();

  Future<SkillCredentialDefinitionsTable?> getDefinitionById(
    String definitionId,
  ) => (select(
    skillCredentialDefinitions,
  )..where((tbl) => tbl.id.equals(definitionId))).getSingleOrNull();

  Future<SkillCredentialDefinitionsTable?> getDefinitionBySlug(
    String workspaceId,
    String slug,
  ) =>
      (select(skillCredentialDefinitions)..where(
            (tbl) =>
                tbl.workspaceId.equals(workspaceId) & tbl.slug.equals(slug),
          ))
          .getSingleOrNull();

  Future<SkillCredentialDefinitionsTable> createDefinition(
    SkillCredentialDefinitionsCompanion definition,
  ) => into(skillCredentialDefinitions).insertReturning(definition);

  Future<SkillCredentialDefinitionsTable> updateDefinition(
    String definitionId,
    SkillCredentialDefinitionsCompanion definition,
  ) async {
    final _ =
        await (update(skillCredentialDefinitions)..where(
              (tbl) => tbl.id.equals(definitionId),
            ))
            .write(definition);
    final updated = await getDefinitionById(definitionId);
    if (updated == null) {
      throw StateError('Updated skill credential definition was not found');
    }

    return updated;
  }

  Future<bool> deleteDefinition(String definitionId) async {
    final count = await (delete(
      skillCredentialDefinitions,
    )..where((tbl) => tbl.id.equals(definitionId))).go();

    return count > 0;
  }
}
