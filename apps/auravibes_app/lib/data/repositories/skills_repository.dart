import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/skills_dao.dart';
import 'package:auravibes_app/data/database/drift/tables/skills.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';

class SkillsRepository(AppDatabase database) {
  final SkillsDao _dao = database.skillsDao;

  Future<List<SkillEntity>> getWorkspaceSkills(String workspaceId) async {
    final rows = await _dao.getWorkspaceSkills(workspaceId);

    return rows.map(this._tableToEntity).toList();
  }

  Future<SkillEntity?> getSkillById(String skillId) async {
    final row = await _dao.getSkillById(skillId);
    if (row == null) return null;

    return this._tableToEntity(row);
  }

  Future<SkillEntity?> getSkillBySlug(String workspaceId, String slug) async {
    final row = await _dao.getSkillBySlug(workspaceId, slug);
    if (row == null) return null;

    return this._tableToEntity(row);
  }

  Future<SkillEntity?> getSkillByTitle(String workspaceId, String title) async {
    final row = await _dao.getSkillByTitle(workspaceId, title.trim());
    if (row == null) return null;

    return this._tableToEntity(row);
  }

  Future<SkillEntity> createSkill(
    String workspaceId,
    SkillToCreate skill,
  ) async {
    final table = await _dao.createSkill(
      _createSkillCompanion(workspaceId, skill),
    );

    return this._tableToEntity(table);
  }

  Future<SkillEntity> updateSkill(String skillId, SkillToUpdate skill) async {
    final table = await _dao.updateSkill(skillId, _updateSkillCompanion(skill));

    return this._tableToEntity(table);
  }

  Future<bool> deleteSkill(String skillId) => _dao.deleteSkill(skillId);
}

extension on SkillsRepository {
  SkillsCompanion _createSkillCompanion(
    String workspaceId,
    SkillToCreate skill,
  ) {
    return SkillsCompanion(
      source: const Value(SkillSourceTable.user),
      workspaceId: Value(workspaceId),
      kind: Value(this._mapKindToTable(skill.kind)),
      title: Value(skill.title.trim()),
      slug: Value(generateSkillSlug(skill.title)),
      description: Value(skill.description),
      content: Value(skill.content),
      credentialDefinitionId: Value(skill.credentialDefinitionId),
      isCredentialOptional: Value(skill.isCredentialOptional),
      isEnabled: Value(skill.isEnabled),
    );
  }

  SkillsCompanion _updateSkillCompanion(SkillToUpdate skill) {
    return SkillsCompanion(
      updatedAt: Value(DateTime.now()),
      title: this._skillTitleValue(skill.title),
      description: Value.absentIfNull(skill.description),
      content: Value.absentIfNull(skill.content),
      credentialDefinitionId: this._credentialDefinitionValue(skill),
      isCredentialOptional: Value.absentIfNull(skill.isCredentialOptional),
      isEnabled: Value.absentIfNull(skill.isEnabled),
    );
  }

  Value<String?> _skillTitleValue(String? title) {
    return title == null ? const Value.absent() : Value(title.trim());
  }

  Value<String?> _credentialDefinitionValue(SkillToUpdate skill) {
    return skill.clearCredentialDefinition
        ? const Value(null)
        : Value.absentIfNull(skill.credentialDefinitionId);
  }

  SkillEntity _tableToEntity(SkillsTable table) {
    return SkillEntity(
      source: this._mapSource(table.source),
      id: table.id,
      workspaceId: table.workspaceId,
      kind: this._mapKind(table.kind),
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
      .user => SkillSource.user,
      .app => SkillSource.app,
    };
  }

  SkillKind _mapKind(SkillKindTable kind) {
    return switch (kind) {
      .template => SkillKind.template,
      .native => SkillKind.native,
    };
  }

  SkillKindTable _mapKindToTable(SkillKind kind) {
    return switch (kind) {
      .template => SkillKindTable.template,
      .native => SkillKindTable.native,
    };
  }
}
