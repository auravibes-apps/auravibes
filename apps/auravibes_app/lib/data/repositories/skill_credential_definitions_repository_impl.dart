import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/skill_credential_definitions_dao.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/features/skills/usecases/generate_skill_slug_usecase.dart';
import 'package:drift/drift.dart';

class SkillCredentialDefinitionsRepositoryImpl
    implements SkillCredentialDefinitionsRepository {
  SkillCredentialDefinitionsRepositoryImpl(AppDatabase database)
    : _dao = database.skillCredentialDefinitionsDao;

  final SkillCredentialDefinitionsDao _dao;

  @override
  Future<List<SkillCredentialDefinitionEntity>> getDefinitions(
    String workspaceId,
  ) async {
    final rows = await _dao.getDefinitions(workspaceId);

    return rows.map(_tableToEntity).toList();
  }

  @override
  Stream<List<SkillCredentialDefinitionEntity>> watchDefinitions(
    String workspaceId,
  ) {
    return _dao
        .watchDefinitions(workspaceId)
        .map(
          (rows) => rows.map(_tableToEntity).toList(),
        );
  }

  @override
  Future<SkillCredentialDefinitionEntity?> getDefinitionById(
    String definitionId,
  ) async {
    final row = await _dao.getDefinitionById(definitionId);
    if (row == null) return null;

    return _tableToEntity(row);
  }

  @override
  Future<SkillCredentialDefinitionEntity?> getDefinitionBySlug(
    String workspaceId,
    String slug,
  ) async {
    final row = await _dao.getDefinitionBySlug(workspaceId, slug);
    if (row == null) return null;

    return _tableToEntity(row);
  }

  @override
  Future<SkillCredentialDefinitionEntity> createDefinition(
    String workspaceId,
    SkillCredentialDefinitionToCreate definition,
  ) async {
    final table = await _dao.createDefinition(
      SkillCredentialDefinitionsCompanion(
        workspaceId: Value(workspaceId),
        title: Value(definition.title.trim()),
        slug: Value(generateSkillSlug(definition.title)),
        attributesJson: Value(definition.attributesJson),
      ),
    );

    return _tableToEntity(table);
  }

  @override
  Future<SkillCredentialDefinitionEntity> updateDefinition(
    String definitionId,
    SkillCredentialDefinitionToUpdate definition,
  ) async {
    final table = await _dao.updateDefinition(
      definitionId,
      SkillCredentialDefinitionsCompanion(
        updatedAt: Value(DateTime.now()),
        title: switch (definition.title) {
          null => const Value.absent(),
          final title => Value(title.trim()),
        },
        attributesJson: Value.absentIfNull(definition.attributesJson),
      ),
    );

    return _tableToEntity(table);
  }

  @override
  Future<bool> deleteDefinition(String definitionId) =>
      _dao.deleteDefinition(definitionId);

  SkillCredentialDefinitionEntity _tableToEntity(
    SkillCredentialDefinitionsTable table,
  ) {
    return SkillCredentialDefinitionEntity(
      id: table.id,
      workspaceId: table.workspaceId,
      title: table.title,
      slug: table.slug,
      attributesJson: table.attributesJson,
      createdAt: table.createdAt,
      updatedAt: table.updatedAt,
    );
  }
}
