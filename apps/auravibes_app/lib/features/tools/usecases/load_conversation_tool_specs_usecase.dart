// ignore_for_file: implementation_imports
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_combined_tool_specs_use_case.dart';
import 'package:auravibes_app/features/agents/usecases/list_conversation_agent_skills_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/sync_skill_tool_permissions_usecase.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/mcp_tool_spec_lookup.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:auravibes_engine/auravibes_engine.dart'
    show ToolSpec, loadSkillToolName, unloadSkillToolName;
import 'package:riverpod/src/providers/provider.dart';

class LoadConversationToolSpecsUsecase {
  const LoadConversationToolSpecsUsecase({
    required this._conversationToolsRepository,
    required this._buildCombinedToolSpecsUseCase,
    required this._buildDynamicSkillToolSpecsUsecase,
    required this._syncSkillToolPermissionsUsecase,
    this._listConversationAgentSkillsUsecase,
    this._buildSkillTemplateToolSpecsUsecase,
    this._buildAppSkillNativeToolSpecsUsecase,
  });

  final ConversationToolsRepository _conversationToolsRepository;
  final BuildCombinedToolSpecsUseCase _buildCombinedToolSpecsUseCase;
  final BuildDynamicSkillToolSpecsUsecase _buildDynamicSkillToolSpecsUsecase;
  final SyncSkillToolPermissionsUsecase _syncSkillToolPermissionsUsecase;
  final ListConversationAgentSkillsUsecase? _listConversationAgentSkillsUsecase;
  final BuildSkillTemplateToolSpecsUsecase? _buildSkillTemplateToolSpecsUsecase;
  final BuildAppSkillNativeToolSpecsUsecase?
  _buildAppSkillNativeToolSpecsUsecase;

  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    await _syncSkillToolPermissionsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
    final enabledTools = await _conversationToolsRepository
        .getAvailableToolEntitiesForConversation(conversationId, workspaceId);
    final agentSkills =
        await _listConversationAgentSkillsUsecase?.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
        ) ??
        const [];

    final toolSpecs = await _buildCombinedToolSpecsUseCase.call(enabledTools);
    final skillToolSpecs = await _buildDynamicSkillToolSpecsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
    final skillTemplateToolSpecs =
        await _buildSkillTemplateToolSpecsUsecase?.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
          extraSkills: agentSkills,
        ) ??
        const <ToolSpec>[];
    final appSkillNativeToolSpecs =
        await _buildAppSkillNativeToolSpecsUsecase?.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
          extraSkills: agentSkills,
        ) ??
        const <ToolSpec>[];
    final enabledSkillToolNames = enabledTools
        .where(
          (tool) => SkillPermissionTools.isSkillPermissionToolName(tool.toolId),
        )
        .map((tool) => tool.toolId)
        .toSet();

    return agent.uniqueToolSpecs([
      ...toolSpecs,
      ...skillToolSpecs.where(_isAvailableSkillControlTool),
      ...skillTemplateToolSpecs.where(
        (spec) => enabledSkillToolNames.contains(spec.name),
      ),
      ...appSkillNativeToolSpecs.where(
        (spec) => enabledSkillToolNames.contains(spec.name),
      ),
      agent.runSubAgentToolSpec,
    ]);
  }

  bool _isAvailableSkillControlTool(ToolSpec spec) {
    return spec.name == loadSkillToolName ||
        spec.name == unloadSkillToolName ||
        spec.name == SkillToolNames.listCredentials;
  }
}

final ProviderFamily<LoadConversationToolSpecsUsecase, String>
loadConversationToolSpecsUsecaseProvider =
    Provider.family<LoadConversationToolSpecsUsecase, String>((
      ref,
      workspaceId,
    ) {
      final session = ref
          .watch(workspaceSessionForRouteProvider(workspaceId))
          .requireValue;

      return LoadConversationToolSpecsUsecase(
        conversationToolsRepository: ref.watch(
          conversationToolsRepositoryProvider(workspaceId),
        ),
        buildCombinedToolSpecsUseCase: BuildCombinedToolSpecsUseCase(
          getToolsGroupById: ref
              .watch(toolsGroupsRepositoryProvider(session))
              .getToolsGroupById,
          getMcpToolSpec: ref.watch(mcpToolSpecLookupProvider).call,
        ),
        buildDynamicSkillToolSpecsUsecase: ref.watch(
          buildDynamicSkillToolSpecsUsecaseProvider,
        ),
        syncSkillToolPermissionsUsecase: ref.watch(
          syncSkillToolPermissionsUsecaseProvider,
        ),
        listConversationAgentSkillsUsecase: ref.watch(
          listConversationAgentSkillsUsecaseProvider,
        ),
        buildSkillTemplateToolSpecsUsecase: ref.watch(
          buildSkillTemplateToolSpecsUsecaseProvider,
        ),
        buildAppSkillNativeToolSpecsUsecase: ref.watch(
          buildAppSkillNativeToolSpecsUsecaseProvider,
        ),
      );
    });
