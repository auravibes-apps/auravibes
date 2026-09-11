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

    return rows.map(_tableToEntity).toList();
  }

  Future<SkillTemplateToolEntity?> getToolById(String toolId) async {
    final row = await _dao.getToolById(toolId);
    if (row == null) return null;

    return _tableToEntity(row);
  }

  Future<SkillTemplateToolEntity?> getToolBySlug(
    String skillId,
    String slug,
  ) async {
    final row = await _dao.getToolBySlug(skillId, slug);
    if (row == null) return null;

    return _tableToEntity(row);
  }

  Future<SkillTemplateToolEntity> createTool(
    String skillId,
    SkillTemplateToolToCreate tool,
  ) async {
    final table = await _dao.createTool(_createToolCompanion(skillId, tool));

    return _tableToEntity(table);
  }

  Future<SkillTemplateToolEntity> updateTool(
    String toolId,
    SkillTemplateToolToUpdate tool,
  ) async {
    final table = await _dao.updateTool(toolId, _updateToolCompanion(tool));

    return _tableToEntity(table);
  }

  Future<bool> deleteTool(String toolId) => _dao.deleteTool(toolId);
}

extension SkillTemplateToolsCompanionMappings on SkillTemplateToolsRepository {
  SkillTemplateToolsCompanion _createToolCompanion(
    String skillId,
    SkillTemplateToolToCreate tool,
  ) {
    return _addToolCreationFields(
      .new(
        skillId: .new(skillId),
        templateType: .new(_mapTypeToTable(tool.templateType)),
        title: .new(tool.title.trim()),
        description: .new(tool.description.trim()),
        slug: .new(generateSkillSlug(tool.title)),
      ),
      tool,
    );
  }

  SkillTemplateToolsCompanion _addToolCreationFields(
    SkillTemplateToolsCompanion companion,
    SkillTemplateToolToCreate tool,
  ) => companion.copyWith(
    templateJson: .new(tool.templateJson),
    inputsJson: .new(tool.inputsJson),
    requiresCredential: .new(tool.requiresCredential),
    isEnabled: .new(tool.isEnabled),
  );

  SkillTemplateToolsCompanion _updateToolCompanion(
    SkillTemplateToolToUpdate tool,
  ) {
    return _addToolUpdateFields(.new(updatedAt: .new(DateTime.now())), tool);
  }

  SkillTemplateToolsCompanion _addToolUpdateFields(
    SkillTemplateToolsCompanion companion,
    SkillTemplateToolToUpdate tool,
  ) => companion.copyWith(
    title: _trimmedValue(tool.title),
    description: _trimmedValue(tool.description),
    templateJson: .absentIfNull(tool.templateJson),
    inputsJson: .absentIfNull(tool.inputsJson),
    requiresCredential: .absentIfNull(tool.requiresCredential),
    isEnabled: .absentIfNull(tool.isEnabled),
  );

  Value<String>? _trimmedValue(String? value) {
    return value == null ? const Value.absent() : .new(value.trim());
  }
}

extension on SkillTemplateToolsRepository {
  SkillTemplateToolEntity _tableToEntity(SkillTemplateToolsTable table) {
    return _withToolState(
      _withToolContent(
        _withToolIdentity(_emptySkillTemplateToolEntity, table),
        table,
      ),
      table,
    );
  }

  SkillTemplateToolEntity _withToolIdentity(
    SkillTemplateToolEntity tool,
    SkillTemplateToolsTable table,
  ) => tool.copyWith(
    id: table.id,
    skillId: table.skillId,
    templateType: _mapType(table.templateType),
  );

  SkillTemplateToolEntity _withToolContent(
    SkillTemplateToolEntity tool,
    SkillTemplateToolsTable table,
  ) => tool.copyWith(
    title: table.title,
    description: table.description,
    slug: table.slug,
    templateJson: table.templateJson,
    inputsJson: table.inputsJson,
  );

  SkillTemplateToolEntity _withToolState(
    SkillTemplateToolEntity tool,
    SkillTemplateToolsTable table,
  ) => tool.copyWith(
    isEnabled: table.isEnabled,
    requiresCredential: table.requiresCredential,
    createdAt: table.createdAt,
    updatedAt: table.updatedAt,
  );

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

final _emptySkillTemplateToolEntity = SkillTemplateToolEntity(
  id: '',
  skillId: '',
  templateType: .url,
  title: '',
  description: '',
  slug: '',
  templateJson: '',
  inputsJson: '',
  isEnabled: false,
  requiresCredential: false,
  createdAt: .new(0),
  updatedAt: .new(0),
);
