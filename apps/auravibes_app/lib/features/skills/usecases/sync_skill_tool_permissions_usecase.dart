import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/features/skills/constants/skill_tool_permission_constants.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';

export 'package:auravibes_app/features/skills/constants/skill_tool_permission_constants.dart'
    show skillToolsGroupName;

class SyncSkillToolPermissionsUsecase {
  const SyncSkillToolPermissionsUsecase({
    required this.database,
    required this.buildDynamicSkillToolSpecs,
    required this.buildSkillTemplateToolSpecs,
    required this.buildAppSkillNativeToolSpecs,
  });

  final AppDatabase database;
  final BuildDynamicSkillToolSpecsUsecase buildDynamicSkillToolSpecs;
  final BuildSkillTemplateToolSpecsUsecase buildSkillTemplateToolSpecs;
  final BuildAppSkillNativeToolSpecsUsecase buildAppSkillNativeToolSpecs;

  Future<void> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final _ = await _syncTools(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
  }

  Future<List<ToolsTable>> _syncTools({
    required String conversationId,
    required String workspaceId,
  }) async {
    final specs = [
      ...await buildDynamicSkillToolSpecs.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
      ),
      ...await buildSkillTemplateToolSpecs.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
      ),
      ...await buildAppSkillNativeToolSpecs.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
      ),
    ];

    return database.transaction(() async {
      final group = await _ensureSkillToolsGroup(workspaceId);
      final existing = await database.workspaceToolsDao.getToolsByGroupId(
        group.id,
      );
      final existingByName = {for (final tool in existing) tool.toolId: tool};
      var insertedTool = false;
      for (final spec in specs) {
        final existingTool = existingByName[spec.name];
        final inputSchema = jsonEncode(spec.inputJsonSchema);
        if (existingTool == null) {
          await database.workspaceToolsDao.insertToolsBatch([
            ToolsCompanion.insert(
              workspaceId: workspaceId,
              workspaceToolsGroupId: Value(group.id),
              toolId: spec.name,
              description: Value(spec.description),
              inputSchema: Value(inputSchema),
              isEnabled: const Value(true),
              permissions: const Value(PermissionAccess.ask),
            ),
          ]);
          insertedTool = true;
          continue;
        }

        if (existingTool.description == spec.description &&
            existingTool.inputSchema == inputSchema) {
          continue;
        }

        await database.workspaceToolsDao.updateToolMetadata(
          id: existingTool.id,
          description: spec.description,
          inputSchema: inputSchema,
        );
      }

      if (insertedTool) {
        return database.workspaceToolsDao.getToolsByGroupId(group.id);
      }

      return existing;
    });
  }

  Future<String?> permissionTableIdFor({
    required String conversationId,
    required String workspaceId,
    required String toolName,
  }) async {
    final tools = await _syncTools(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
    final toolsByName = {for (final tool in tools) tool.toolId: tool};

    return toolsByName[toolName]?.id;
  }

  Future<ToolsGroupsTable> _ensureSkillToolsGroup(String workspaceId) async {
    final existing = await database.toolsGroupsDao.getToolsGroupByName(
      workspaceId: workspaceId,
      name: skillToolsGroupName,
    );
    if (existing != null) return existing;

    return database.toolsGroupsDao.insertToolsGroup(
      ToolsGroupsCompanion.insert(
        workspaceId: workspaceId,
        name: skillToolsGroupName,
        permissions: PermissionAccess.ask,
      ),
    );
  }
}

final syncSkillToolPermissionsUsecaseProvider =
    Provider<SyncSkillToolPermissionsUsecase>((ref) {
      return SyncSkillToolPermissionsUsecase(
        database: ref.watch(appDatabaseProvider),
        buildDynamicSkillToolSpecs: ref.watch(
          buildDynamicSkillToolSpecsUsecaseProvider,
        ),
        buildSkillTemplateToolSpecs: ref.watch(
          buildSkillTemplateToolSpecsUsecaseProvider,
        ),
        buildAppSkillNativeToolSpecs: ref.watch(
          buildAppSkillNativeToolSpecsUsecaseProvider,
        ),
      );
    });

bool isSkillPermissionToolName(String toolName) {
  return toolName == loadSkillToolName ||
      toolName == unloadSkillToolName ||
      toolName == listSkillCredentialsToolName ||
      toolName.startsWith('skill__user__') ||
      toolName.startsWith('skill__app__');
}
