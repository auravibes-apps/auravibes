import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/skill_template_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/tables/skill_template_tools.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';

class SkillTemplateToolsRepository(AppDatabase database) {
  final SkillTemplateToolsDao _dao = database.skillTemplateToolsDao;

  Future<List<SkillTemplateToolEntity>> getSkillTools(String skillId) async {
    final rows = await _dao.getSkillTools(skillId);

    return rows.map(this._tableToEntity).toList();
  }

  Future<SkillTemplateToolEntity?> getToolById(String toolId) async {
    final row = await _dao.getToolById(toolId);
    if (row == null) return null;

    return this._tableToEntity(row);
  }

  Future<SkillTemplateToolEntity?> getToolBySlug(
    String skillId,
    String slug,
  ) async {
    final row = await _dao.getToolBySlug(skillId, slug);
    if (row == null) return null;

    return this._tableToEntity(row);
  }

  Future<SkillTemplateToolEntity> createTool(
    String skillId,
    SkillTemplateToolToCreate tool,
  ) async {
    final table = await _dao.createTool(
      this._createToolCompanion(skillId, tool),
    );

    return this._tableToEntity(table);
  }

  Future<SkillTemplateToolEntity> updateTool(
    String toolId,
    SkillTemplateToolToUpdate tool,
  ) async {
    final table = await _dao.updateTool(
      toolId,
      this._updateToolCompanion(tool),
    );

    return this._tableToEntity(table);
  }

  Future<bool> deleteTool(String toolId) => _dao.deleteTool(toolId);
}

extension on SkillTemplateToolsRepository {
  SkillTemplateToolsCompanion _createToolCompanion(
    String skillId,
    SkillTemplateToolToCreate tool,
  ) {
    return SkillTemplateToolsCompanion(
      skillId: Value(skillId),
      templateType: Value(this._mapTypeToTable(tool.templateType)),
      title: Value(tool.title.trim()),
      description: Value(tool.description.trim()),
      slug: Value(generateSkillSlug(tool.title)),
      templateJson: Value(tool.templateJson),
      inputsJson: Value(tool.inputsJson),
      requiresCredential: Value(tool.requiresCredential),
      isEnabled: Value(tool.isEnabled),
    );
  }

  SkillTemplateToolsCompanion _updateToolCompanion(
    SkillTemplateToolToUpdate tool,
  ) {
    return SkillTemplateToolsCompanion(
      updatedAt: Value(DateTime.now()),
      title: this._trimmedValue(tool.title),
      description: this._trimmedValue(tool.description),
      templateJson: Value.absentIfNull(tool.templateJson),
      inputsJson: Value.absentIfNull(tool.inputsJson),
      requiresCredential: Value.absentIfNull(tool.requiresCredential),
      isEnabled: Value.absentIfNull(tool.isEnabled),
    );
  }

  Value<String?> _trimmedValue(String? value) {
    return value == null ? const Value.absent() : Value(value.trim());
  }

  SkillTemplateToolEntity _tableToEntity(SkillTemplateToolsTable table) {
    return SkillTemplateToolEntity(
      id: table.id,
      skillId: table.skillId,
      templateType: this._mapType(table.templateType),
      title: table.title,
      description: table.description,
      slug: table.slug,
      templateJson: table.templateJson,
      inputsJson: table.inputsJson,
      isEnabled: table.isEnabled,
      requiresCredential: table.requiresCredential,
      createdAt: table.createdAt,
      updatedAt: table.updatedAt,
    );
  }

  SkillTemplateToolType _mapType(SkillTemplateToolTypeTable type) {
    return switch (type) {
      .url => SkillTemplateToolType.url,
    };
  }

  SkillTemplateToolTypeTable _mapTypeToTable(SkillTemplateToolType type) {
    return switch (type) {
      .url => SkillTemplateToolTypeTable.url,
    };
  }
}
