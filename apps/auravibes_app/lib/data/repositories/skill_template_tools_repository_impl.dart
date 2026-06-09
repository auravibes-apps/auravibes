import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/skill_template_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/tables/skill_template_tools.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/domain/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/features/skills/usecases/generate_skill_slug_usecase.dart';
import 'package:drift/drift.dart';

class SkillTemplateToolsRepositoryImpl implements SkillTemplateToolsRepository {
  SkillTemplateToolsRepositoryImpl(AppDatabase database)
    : _dao = database.skillTemplateToolsDao;

  final SkillTemplateToolsDao _dao;
  final GenerateSkillSlugUsecase _generateSlug =
      const GenerateSkillSlugUsecase();

  @override
  Future<List<SkillTemplateToolEntity>> getSkillTools(String skillId) async {
    final rows = await _dao.getSkillTools(skillId);

    return rows.map(_tableToEntity).toList();
  }

  @override
  Future<SkillTemplateToolEntity?> getToolById(String toolId) async {
    final row = await _dao.getToolById(toolId);
    if (row == null) return null;

    return _tableToEntity(row);
  }

  @override
  Future<SkillTemplateToolEntity?> getToolBySlug(
    String skillId,
    String slug,
  ) async {
    final row = await _dao.getToolBySlug(skillId, slug);
    if (row == null) return null;

    return _tableToEntity(row);
  }

  @override
  Future<SkillTemplateToolEntity> createTool(
    String skillId,
    SkillTemplateToolToCreate tool,
  ) async {
    final table = await _dao.createTool(
      SkillTemplateToolsCompanion(
        skillId: Value(skillId),
        templateType: Value(_mapTypeToTable(tool.templateType)),
        title: Value(tool.title.trim()),
        description: Value(tool.description.trim()),
        slug: Value(_generateSlug.call(tool.title)),
        templateJson: Value(tool.templateJson),
        inputsJson: Value(tool.inputsJson),
        requiresCredential: Value(tool.requiresCredential),
        isEnabled: Value(tool.isEnabled),
      ),
    );

    return _tableToEntity(table);
  }

  @override
  Future<SkillTemplateToolEntity> updateTool(
    String toolId,
    SkillTemplateToolToUpdate tool,
  ) async {
    final table = await _dao.updateTool(
      toolId,
      SkillTemplateToolsCompanion(
        updatedAt: Value(DateTime.now()),
        title: switch (tool.title) {
          null => const Value.absent(),
          final title => Value(title.trim()),
        },
        description: switch (tool.description) {
          null => const Value.absent(),
          final description => Value(description.trim()),
        },
        templateJson: Value.absentIfNull(tool.templateJson),
        inputsJson: Value.absentIfNull(tool.inputsJson),
        requiresCredential: Value.absentIfNull(tool.requiresCredential),
        isEnabled: Value.absentIfNull(tool.isEnabled),
      ),
    );

    return _tableToEntity(table);
  }

  @override
  Future<bool> deleteTool(String toolId) => _dao.deleteTool(toolId);

  SkillTemplateToolEntity _tableToEntity(SkillTemplateToolsTable table) {
    return SkillTemplateToolEntity(
      id: table.id,
      skillId: table.skillId,
      templateType: _mapType(table.templateType),
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
      SkillTemplateToolTypeTable.url => SkillTemplateToolType.url,
    };
  }

  SkillTemplateToolTypeTable _mapTypeToTable(SkillTemplateToolType type) {
    return switch (type) {
      SkillTemplateToolType.url => SkillTemplateToolTypeTable.url,
    };
  }
}
