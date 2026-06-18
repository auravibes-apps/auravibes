import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';

const skillToolsGroupName = 'Skills';

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
    await database.transaction(() async {
      final group = await _ensureSkillToolsGroup(workspaceId);
      final existing = await database.workspaceToolsDao.getToolsByGroupId(
        group.id,
      );
      final existingByName = {for (final tool in existing) tool.toolId: tool};
      final currentNames = specs.map((spec) => spec.name).toSet();

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
          continue;
        }

        await database.workspaceToolsDao.updateToolMetadata(
          id: existingTool.id,
          description: spec.description,
          inputSchema: inputSchema,
        );
      }

      for (final existingTool in existing) {
        if (!currentNames.contains(existingTool.toolId)) {
          final _ = await database.workspaceToolsDao.deleteWorkspaceToolById(
            existingTool.id,
          );
        }
      }
    });
  }

  Future<String?> permissionTableIdFor({
    required String conversationId,
    required String workspaceId,
    required String toolName,
  }) async {
    await call(conversationId: conversationId, workspaceId: workspaceId);
    final group = await database.toolsGroupsDao.getToolsGroupByName(
      workspaceId: workspaceId,
      name: skillToolsGroupName,
    );
    if (group == null) return null;

    final tools = await database.workspaceToolsDao.getToolsByGroupId(group.id);
    for (final tool in tools) {
      if (tool.toolId == toolName) return tool.id;
    }

    return null;
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
