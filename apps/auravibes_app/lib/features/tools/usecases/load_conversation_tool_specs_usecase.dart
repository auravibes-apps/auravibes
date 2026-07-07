// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_agent/auravibes_agent.dart' as agent;
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_combined_tool_specs_use_case.dart';
import 'package:auravibes_app/features/agents/usecases/list_conversation_agent_skills_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/sync_skill_tool_permissions_usecase.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/mcp_tool_spec_lookup.dart';
import 'package:riverpod/riverpod.dart';

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
        .getAvailableToolEntitiesForConversation(
          conversationId,
          workspaceId,
        );
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
        .where((tool) => isSkillPermissionToolName(tool.toolId))
        .map((tool) => tool.toolId)
        .toSet();

    return [
      ...toolSpecs,
      ...skillToolSpecs.where(_isAvailableSkillControlTool),
      ...skillTemplateToolSpecs.where(
        (spec) => enabledSkillToolNames.contains(spec.name),
      ),
      ...appSkillNativeToolSpecs.where(
        (spec) => enabledSkillToolNames.contains(spec.name),
      ),
      _subAgentToolSpec(agent.runSubAgentToolSpec),
    ];
  }

  bool _isAvailableSkillControlTool(ToolSpec spec) {
    return spec.name == loadSkillToolName ||
        spec.name == unloadSkillToolName ||
        spec.name == listSkillCredentialsToolName;
  }
}

ToolSpec _subAgentToolSpec(agent.SubAgentToolSpec spec) {
  return ToolSpec(
    name: spec.name,
    description: spec.description,
    inputJsonSchema: spec.inputJsonSchema,
  );
}

final loadConversationToolSpecsUsecaseProvider =
    Provider<LoadConversationToolSpecsUsecase>((ref) {
      return LoadConversationToolSpecsUsecase(
        conversationToolsRepository: ref.watch(
          conversationToolsRepositoryProvider,
        ),
        buildCombinedToolSpecsUseCase: BuildCombinedToolSpecsUseCase(
          getToolsGroupById: ref
              .watch(toolsGroupsRepositoryProvider)
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
