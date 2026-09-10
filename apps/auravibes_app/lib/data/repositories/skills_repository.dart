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

    return rows.map(_tableToEntity).toList();
  }

  Future<SkillEntity?> getSkillById(String skillId) async {
    final row = await _dao.getSkillById(skillId);
    if (row == null) return null;

    return _tableToEntity(row);
  }

  Future<SkillEntity?> getSkillBySlug(String workspaceId, String slug) async {
    final row = await _dao.getSkillBySlug(workspaceId, slug);
    if (row == null) return null;

    return _tableToEntity(row);
  }

  Future<SkillEntity?> getSkillByTitle(String workspaceId, String title) async {
    final row = await _dao.getSkillByTitle(workspaceId, title.trim());
    if (row == null) return null;

    return _tableToEntity(row);
  }

  Future<SkillEntity> createSkill(
    String workspaceId,
    SkillToCreate skill,
  ) async {
    final table = await _dao.createSkill(
      _createSkillCompanion(workspaceId, skill),
    );

    return _tableToEntity(table);
  }

  Future<SkillEntity> updateSkill(String skillId, SkillToUpdate skill) async {
    final table = await _dao.updateSkill(skillId, _updateSkillCompanion(skill));

    return _tableToEntity(table);
  }

  Future<bool> deleteSkill(String skillId) => _dao.deleteSkill(skillId);
}

extension SkillsRepositoryCompanionMappings on SkillsRepository {
  SkillsCompanion _createSkillCompanion(
    String workspaceId,
    SkillToCreate skill,
  ) {
    return _addSkillCreationFields(
      SkillsCompanion(
        source: const Value(SkillSourceTable.user),
        workspaceId: Value(workspaceId),
        kind: Value(_mapKindToTable(skill.kind)),
        title: Value(skill.title.trim()),
        slug: Value(generateSkillSlug(skill.title)),
      ),
      skill,
    );
  }

  SkillsCompanion _addSkillCreationFields(
    SkillsCompanion companion,
    SkillToCreate skill,
  ) => companion.copyWith(
    description: Value(skill.description),
    content: Value(skill.content),
    credentialDefinitionId: Value(skill.credentialDefinitionId),
    isCredentialOptional: Value(skill.isCredentialOptional),
    isEnabled: Value(skill.isEnabled),
  );

  SkillsCompanion _updateSkillCompanion(SkillToUpdate skill) {
    return _addSkillUpdateFields(
      SkillsCompanion(updatedAt: Value(DateTime.now())),
      skill,
    );
  }

  SkillsCompanion _addSkillUpdateFields(
    SkillsCompanion companion,
    SkillToUpdate skill,
  ) => companion.copyWith(
    title: _skillTitleValue(skill.title),
    description: Value.absentIfNull(skill.description),
    content: Value.absentIfNull(skill.content),
    credentialDefinitionId: _credentialDefinitionValue(skill),
    isCredentialOptional: Value.absentIfNull(skill.isCredentialOptional),
    isEnabled: Value.absentIfNull(skill.isEnabled),
  );

  Value<String>? _skillTitleValue(String? title) {
    return title == null ? const Value.absent() : Value(title.trim());
  }

  Value<String?> _credentialDefinitionValue(SkillToUpdate skill) {
    return skill.clearCredentialDefinition
        ? const Value(null)
        : Value.absentIfNull(skill.credentialDefinitionId);
  }
}

extension SkillsRepositoryEntityMappings on SkillsRepository {
  SkillEntity _tableToEntity(SkillsTable table) {
    return _withSkillState(
      _withSkillContent(_withSkillIdentity(_emptySkillEntity, table), table),
      table,
    );
  }

  SkillEntity _withSkillIdentity(SkillEntity skill, SkillsTable table) =>
      skill.copyWith(
        source: _mapSource(table.source),
        id: table.id,
        workspaceId: table.workspaceId,
        kind: _mapKind(table.kind),
      );

  SkillEntity _withSkillContent(SkillEntity skill, SkillsTable table) =>
      skill.copyWith(
        title: table.title,
        slug: table.slug,
        description: table.description,
        content: table.content,
      );

  SkillEntity _withSkillState(SkillEntity skill, SkillsTable table) =>
      skill.copyWith(
        isEnabled: table.isEnabled,
        isCredentialOptional: table.isCredentialOptional,
        createdAt: table.createdAt,
        updatedAt: table.updatedAt,
        credentialDefinitionId: table.credentialDefinitionId,
      );

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

final _emptySkillEntity = SkillEntity(
  id: '',
  workspaceId: '',
  source: SkillSource.user,
  kind: SkillKind.template,
  title: '',
  slug: '',
  description: '',
  content: '',
  isEnabled: false,
  isCredentialOptional: false,
  createdAt: DateTime(0),
  updatedAt: DateTime(0),
);
