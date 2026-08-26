import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/features/agents/usecases/list_conversation_agent_skills_usecase.dart';
import 'package:auravibes_app/features/skills/constants/skill_tool_permission_constants.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';

export 'package:auravibes_app/features/skills/constants/skill_tool_permission_constants.dart';

class SyncSkillToolPermissionsUsecase {
  const SyncSkillToolPermissionsUsecase({
    required this.database,
    required this.buildDynamicSkillToolSpecs,
    required this.buildSkillTemplateToolSpecs,
    required this.buildAppSkillNativeToolSpecs,
    this.listConversationAgentSkillsUsecase,
  });

  final AppDatabase database;
  final BuildDynamicSkillToolSpecsUsecase buildDynamicSkillToolSpecs;
  final BuildSkillTemplateToolSpecsUsecase buildSkillTemplateToolSpecs;
  final BuildAppSkillNativeToolSpecsUsecase buildAppSkillNativeToolSpecs;
  final ListConversationAgentSkillsUsecase? listConversationAgentSkillsUsecase;

  Future<void> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final _ = await _syncTools(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
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

  Future<List<ToolsTable>> _syncTools({
    required String conversationId,
    required String workspaceId,
  }) async {
    final agentSkills =
        await listConversationAgentSkillsUsecase?.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
        ) ??
        const [];
    final specs = [
      ...await buildDynamicSkillToolSpecs.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
      ),
      ...await buildSkillTemplateToolSpecs.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
        extraSkills: agentSkills,
      ),
      ...await buildAppSkillNativeToolSpecs.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
        extraSkills: agentSkills,
      ),
    ];

    return await database.transaction(() async {
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
        return await database.workspaceToolsDao.getToolsByGroupId(group.id);
      }

      return existing;
    });
  }

  Future<ToolsGroupsTable> _ensureSkillToolsGroup(String workspaceId) async {
    final existing = await database.toolsGroupsDao.getToolsGroupByName(
      workspaceId: workspaceId,
      name: SkillToolPermissionConstants.skillToolsGroupName,
    );
    if (existing != null) return existing;

    return await database.toolsGroupsDao.insertToolsGroup(
      ToolsGroupsCompanion.insert(
        workspaceId: workspaceId,
        name: SkillToolPermissionConstants.skillToolsGroupName,
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
        listConversationAgentSkillsUsecase: ref.watch(
          listConversationAgentSkillsUsecaseProvider,
        ),
      );
    });

abstract final class SkillPermissionTools {
  static bool isSkillPermissionToolName(String toolName) {
    final resolved = const AgentToolNameResolver(
      skillControlToolNames: {
        loadSkillToolName,
        unloadSkillToolName,
        SkillToolNames.listCredentials,
      },
    ).resolve(toolName);

    return resolved?.isSkill == true ||
        resolved?.kind == AgentResolvedToolKind.skillControl;
  }
}
