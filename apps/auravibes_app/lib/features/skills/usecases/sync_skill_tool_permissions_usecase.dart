import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/features/agents/usecases/list_conversation_agent_skills_usecase.dart';
import 'package:auravibes_app/features/skills/constants/skill_tool_permission_constants.dart';
import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';

export 'package:auravibes_app/features/skills/constants/skill_tool_permission_constants.dart';

typedef _SyncToolsRequest = ({
  String workspaceId,
  String groupId,
  List<ToolsTable> existing,
  List<ToolSpec> specs,
});

typedef _SyncToolRequest = ({
  String workspaceId,
  String groupId,
  ToolSpec spec,
  ToolsTable? existing,
});

typedef _InsertToolRequest = ({
  String workspaceId,
  String groupId,
  ToolSpec spec,
  String inputSchema,
});

class const SyncSkillToolPermissionsUsecase({
  required final AppDatabase database,
  required final BuildDynamicSkillToolSpecsUsecase buildDynamicSkillToolSpecs,
  required final BuildSkillTemplateToolSpecsUsecase buildSkillTemplateToolSpecs,
  required final BuildAppSkillNativeToolSpecsUsecase
  buildAppSkillNativeToolSpecs,
  final ListConversationAgentSkillsUsecase? listConversationAgentSkillsUsecase,
}) {
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
}

extension _SyncSkillToolPermissionsUsecaseSync
    on SyncSkillToolPermissionsUsecase {
  Future<List<ToolsTable>> _syncTools({
    required String conversationId,
    required String workspaceId,
  }) async {
    final specs = await _loadToolSpecs(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );

    return await database.transaction(
      () => _syncToolsInDatabase(workspaceId: workspaceId, specs: specs),
    );
  }

  Future<List<ToolSpec>> _loadToolSpecs({
    required String conversationId,
    required String workspaceId,
  }) async {
    final agentSkills = await _loadAgentSkills(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );

    return [
      ...await _dynamicSpecs(conversationId, workspaceId),
      ...await _templateSpecs(conversationId, workspaceId, agentSkills),
      ...await _nativeSpecs(conversationId, workspaceId, agentSkills),
    ];
  }

  Future<List<ToolSpec>> _dynamicSpecs(
    String conversationId,
    String workspaceId,
  ) => buildDynamicSkillToolSpecs.call(
    conversationId: conversationId,
    workspaceId: workspaceId,
  );

  Future<List<ToolSpec>> _templateSpecs(
    String conversationId,
    String workspaceId,
    List<AvailableSkill> extraSkills,
  ) => buildSkillTemplateToolSpecs.call(
    conversationId: conversationId,
    workspaceId: workspaceId,
    extraSkills: extraSkills,
  );

  Future<List<ToolSpec>> _nativeSpecs(
    String conversationId,
    String workspaceId,
    List<AvailableSkill> extraSkills,
  ) => buildAppSkillNativeToolSpecs.call(
    conversationId: conversationId,
    workspaceId: workspaceId,
    extraSkills: extraSkills,
  );

  Future<List<AvailableSkill>> _loadAgentSkills({
    required String conversationId,
    required String workspaceId,
  }) async =>
      await listConversationAgentSkillsUsecase?.call(
        conversationId: conversationId,
        workspaceId: workspaceId,
      ) ??
      const [];
}

extension _SyncSkillToolPermissionsUsecaseDatabase
    on SyncSkillToolPermissionsUsecase {
  Future<List<ToolsTable>> _syncToolsInDatabase({
    required String workspaceId,
    required List<ToolSpec> specs,
  }) async {
    final group = await _ensureSkillToolsGroup(workspaceId);
    final existing = await _existingTools(group.id);
    final insertedTool = await _syncExistingTools((
      workspaceId: workspaceId,
      groupId: group.id,
      existing: existing,
      specs: specs,
    ));

    return insertedTool ? await _reloadTools(group.id) : existing;
  }

  Future<List<ToolsTable>> _existingTools(String groupId) =>
      database.workspaceToolsDao.getToolsByGroupId(groupId);

  Future<List<ToolsTable>> _reloadTools(String groupId) =>
      database.workspaceToolsDao.getToolsByGroupId(groupId);

  Future<bool> _syncExistingTools(_SyncToolsRequest request) async {
    final existingByName = _toolsByName(request.existing);
    var insertedTool = false;
    for (final spec in request.specs) {
      final didInsert = await _syncTool(
        _toolRequest(request, spec, existingByName),
      );
      insertedTool = insertedTool || didInsert;
    }

    return insertedTool;
  }

  Map<String, ToolsTable> _toolsByName(List<ToolsTable> tools) => {
    for (final tool in tools) tool.toolId: tool,
  };

  _SyncToolRequest _toolRequest(
    _SyncToolsRequest request,
    ToolSpec spec,
    Map<String, ToolsTable> existingByName,
  ) => (
    workspaceId: request.workspaceId,
    groupId: request.groupId,
    spec: spec,
    existing: existingByName[spec.name],
  );
}

extension _SyncSkillToolPermissionsUsecaseMutation
    on SyncSkillToolPermissionsUsecase {
  Future<bool> _syncTool(_SyncToolRequest request) async {
    final inputSchema = _inputSchema(request.spec);
    final existing = request.existing;
    if (existing == null) {
      await _insertTool(_insertRequest(request, inputSchema));

      return true;
    }

    return await _syncExistingTool(
      existing,
      request.spec.description,
      inputSchema,
    );
  }

  String _inputSchema(ToolSpec spec) => jsonEncode(spec.inputJsonSchema);

  _InsertToolRequest _insertRequest(
    _SyncToolRequest request,
    String inputSchema,
  ) => (
    workspaceId: request.workspaceId,
    groupId: request.groupId,
    spec: request.spec,
    inputSchema: inputSchema,
  );

  Future<bool> _syncExistingTool(
    ToolsTable existing,
    String description,
    String inputSchema,
  ) async {
    if (_hasCurrentMetadata(existing, description, inputSchema)) return false;

    await database.workspaceToolsDao.updateToolMetadata(
      id: existing.id,
      description: description,
      inputSchema: inputSchema,
    );

    return false;
  }

  Future<void> _insertTool(_InsertToolRequest request) async {
    await database.workspaceToolsDao.insertToolsBatch([
      _toolCompanion(request),
    ]);
  }

  ToolsCompanion _toolCompanion(_InsertToolRequest request) =>
      ToolsCompanion.insert(
        workspaceId: request.workspaceId,
        workspaceToolsGroupId: .new(request.groupId),
        toolId: request.spec.name,
        description: .new(request.spec.description),
        inputSchema: .new(request.inputSchema),
        isEnabled: const Value(true),
        permissions: const Value(PermissionAccess.ask),
      );

  bool _hasCurrentMetadata(
    ToolsTable tool,
    String description,
    String inputSchema,
  ) => tool.description == description && tool.inputSchema == inputSchema;

  Future<ToolsGroupsTable> _ensureSkillToolsGroup(String workspaceId) async {
    final existing = await database.toolsGroupsDao.getToolsGroupByName(
      workspaceId: workspaceId,
      name: SkillToolPermissionConstants.skillToolsGroupName,
    );

    return await (existing ??
        database.toolsGroupsDao.insertToolsGroup(
          .insert(
            workspaceId: workspaceId,
            name: SkillToolPermissionConstants.skillToolsGroupName,
            permissions: PermissionAccess.ask,
          ),
        ));
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
