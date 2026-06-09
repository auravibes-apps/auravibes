import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/skills_dao.dart';
import 'package:auravibes_app/data/database/drift/tables/skills.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/repositories/skills_repository.dart';
import 'package:auravibes_app/features/skills/usecases/generate_skill_slug_usecase.dart';
import 'package:drift/drift.dart';

class SkillsRepositoryImpl implements SkillsRepository {
  SkillsRepositoryImpl(AppDatabase database) : _dao = database.skillsDao;

  final SkillsDao _dao;
  final GenerateSkillSlugUsecase _generateSlug =
      const GenerateSkillSlugUsecase();

  @override
  Future<List<SkillEntity>> getWorkspaceSkills(String workspaceId) async {
    final rows = await _dao.getWorkspaceSkills(workspaceId);

    return rows.map(_tableToEntity).toList();
  }

  @override
  Future<SkillEntity?> getSkillById(String skillId) async {
    final row = await _dao.getSkillById(skillId);
    if (row == null) return null;

    return _tableToEntity(row);
  }

  @override
  Future<SkillEntity?> getSkillBySlug(String workspaceId, String slug) async {
    final row = await _dao.getSkillBySlug(workspaceId, slug);
    if (row == null) return null;

    return _tableToEntity(row);
  }

  @override
  Future<SkillEntity?> getSkillByTitle(String workspaceId, String title) async {
    final row = await _dao.getSkillByTitle(workspaceId, title.trim());
    if (row == null) return null;

    return _tableToEntity(row);
  }

  @override
  Future<SkillEntity> createSkill(
    String workspaceId,
    SkillToCreate skill,
  ) async {
    final table = await _dao.createSkill(
      SkillsCompanion(
        workspaceId: Value(workspaceId),
        source: const Value(SkillSourceTable.user),
        kind: Value(_mapKindToTable(skill.kind)),
        title: Value(skill.title.trim()),
        slug: Value(_generateSlug.call(skill.title)),
        description: Value(skill.description),
        content: Value(skill.content),
        credentialDefinitionId: Value(skill.credentialDefinitionId),
        isCredentialOptional: Value(skill.isCredentialOptional),
        isEnabled: Value(skill.isEnabled),
      ),
    );

    return _tableToEntity(table);
  }

  @override
  Future<SkillEntity> updateSkill(String skillId, SkillToUpdate skill) async {
    final table = await _dao.updateSkill(
      skillId,
      SkillsCompanion(
        updatedAt: Value(DateTime.now()),
        title: switch (skill.title) {
          null => const Value.absent(),
          final title => Value(title.trim()),
        },
        description: Value.absentIfNull(skill.description),
        content: Value.absentIfNull(skill.content),
        credentialDefinitionId: skill.clearCredentialDefinition
            ? const Value(null)
            : Value.absentIfNull(skill.credentialDefinitionId),
        isCredentialOptional: Value.absentIfNull(
          skill.isCredentialOptional,
        ),
        isEnabled: Value.absentIfNull(skill.isEnabled),
      ),
    );

    return _tableToEntity(table);
  }

  @override
  Future<bool> deleteSkill(String skillId) => _dao.deleteSkill(skillId);

  SkillEntity _tableToEntity(SkillsTable table) {
    return SkillEntity(
      id: table.id,
      workspaceId: table.workspaceId,
      source: _mapSource(table.source),
      kind: _mapKind(table.kind),
      title: table.title,
      slug: table.slug,
      description: table.description,
      content: table.content,
      isEnabled: table.isEnabled,
      isCredentialOptional: table.isCredentialOptional,
      createdAt: table.createdAt,
      updatedAt: table.updatedAt,
      credentialDefinitionId: table.credentialDefinitionId,
    );
  }

  SkillSource _mapSource(SkillSourceTable source) {
    return switch (source) {
      SkillSourceTable.user => SkillSource.user,
      SkillSourceTable.app => SkillSource.app,
    };
  }

  SkillKind _mapKind(SkillKindTable kind) {
    return switch (kind) {
      SkillKindTable.template => SkillKind.template,
      SkillKindTable.native => SkillKind.native,
    };
  }

  SkillKindTable _mapKindToTable(SkillKind kind) {
    return switch (kind) {
      SkillKind.template => SkillKindTable.template,
      SkillKind.native => SkillKindTable.native,
    };
  }
}
