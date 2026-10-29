// ignore_for_file: implementation_imports
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_combined_tool_specs_use_case.dart';
import 'package:auravibes_app/features/agents/agent_guidance.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/sync_connector_tool_permissions_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/sync_skill_tool_permissions_usecase.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/mcp_tool_spec_lookup.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:auravibes_engine/auravibes_engine.dart' show ToolSpec;
import 'package:riverpod/src/providers/provider.dart';

class const LoadConversationToolSpecsUsecase({
  required final ConversationToolsRepository _conversationToolsRepository,
  required final BuildCombinedToolSpecsUseCase _buildCombinedToolSpecsUseCase,
  required final BuildDynamicSkillToolSpecsUsecase
  _buildDynamicSkillToolSpecsUsecase,
  required final SyncSkillToolPermissionsUsecase
  _syncSkillToolPermissionsUsecase,
  final SyncConnectorToolPermissionsUsecase?
  syncConnectorToolPermissionsUsecase,
  final ConversationRepository? conversationRepository,
}) {
  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
    String? languageCode,
  }) async => (await buildCatalog(
    conversationId: conversationId,
    workspaceId: workspaceId,
    languageCode: languageCode,
  )).specs;

  Future<List<ToolSpec>> preview({
    required String conversationId,
    required String workspaceId,
    String? languageCode,
  }) async => (await _buildCatalogForConversation(
    conversationId,
    workspaceId,
    languageCode,
  )).specs;

  Future<agent.ToolCatalog<ResolvedTool>> buildCatalog({
    required String conversationId,
    required String workspaceId,
    String? languageCode,
  }) async {
    await _syncSkillToolPermissionsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      languageCode: languageCode,
    );
    await syncConnectorToolPermissionsUsecase?.call(workspaceId: workspaceId);

    return await _buildCatalogForConversation(
      conversationId,
      workspaceId,
      languageCode,
    );
  }

  Future<List<agent.ToolCatalogCandidate<ResolvedTool>>> _loadToolCandidates(
    String conversationId,
    String workspaceId,
  ) async {
    final enabledTools = await _conversationToolsRepository
        .getAvailableToolEntitiesForConversation(conversationId, workspaceId);

    return await _buildCombinedToolSpecsUseCase.call(enabledTools);
  }

  Future<agent.ToolCatalog<ResolvedTool>> _buildCatalogForConversation(
    String conversationId,
    String workspaceId,
    String? languageCode,
  ) async {
    final input = await _loadCatalogInput(conversationId, workspaceId);

    return _buildCatalog(
      input: input,
      includeRunSubAgent: await _includeRunSubAgent(conversationId),
      languageCode: languageCode,
    );
  }

  Future<
    ({
      List<agent.ToolCatalogCandidate<ResolvedTool>> toolCandidates,
      List<ToolSpec> skillControlSpecs,
    })
  >
  _loadCatalogInput(String conversationId, String workspaceId) async => (
    toolCandidates: await _loadToolCandidates(conversationId, workspaceId),
    skillControlSpecs: await _buildDynamicSkillToolSpecsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    ),
  );

  Future<bool> _includeRunSubAgent(String conversationId) async {
    final repository = conversationRepository;
    if (repository == null) return true;

    final conversation = await repository.getConversationById(conversationId);

    return conversation != null && conversation.parentConversationId == null;
  }
}

agent.ToolCatalog<ResolvedTool> _buildCatalog({
  required ({
    List<agent.ToolCatalogCandidate<ResolvedTool>> toolCandidates,
    List<ToolSpec> skillControlSpecs,
  })
  input,
  required bool includeRunSubAgent,
  String? languageCode,
}) => agent.buildToolCatalog([
  ...input.toolCandidates,
  ...agent.workspaceReadToolSpecs().map(_workspaceCandidate),
  ...agent.workspaceMutationToolSpecs().map(_workspaceCandidate),
  ...agent.buildConnectorCommandToolSpecs().map(_connectorCommandCandidate),
  ...input.skillControlSpecs.map(_skillControlCandidate),
  if (includeRunSubAgent) _runSubAgentCandidate(languageCode),
]);

agent.ToolCatalogCandidate<ResolvedTool> _workspaceCandidate(ToolSpec spec) =>
    agent.ToolCatalogCandidate.reserved(
      spec: spec,
      target: ResolvedTool.workspaceAction(toolIdentifier: spec.name),
    );

agent.ToolCatalogCandidate<ResolvedTool> _connectorCommandCandidate(
  ToolSpec spec,
) => agent.ToolCatalogCandidate.reserved(
  spec: spec,
  target: ResolvedTool.connectorCommand(commandName: spec.name),
);

agent.ToolCatalogCandidate<ResolvedTool> _skillControlCandidate(
  ToolSpec spec,
) => agent.ToolCatalogCandidate.reserved(
  spec: spec,
  target: ResolvedTool.skillControl(toolIdentifier: spec.name),
);

agent.ToolCatalogCandidate<ResolvedTool> _runSubAgentCandidate(
  String? languageCode,
) => agent.ToolCatalogCandidate.reserved(
  spec: AgentGuidance.runSubAgentToolSpecForLanguageCode(languageCode),
  target: ResolvedTool.skillNative(
    tableId: agent.runSubAgentToolName,
    skillSlug: agent.agentsSkillSlug,
    toolIdentifier: agent.runSubAgentToolName,
  ),
);

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
        buildCombinedToolSpecsUseCase: .new(
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
        syncConnectorToolPermissionsUsecase: ref.watch(
          syncConnectorToolPermissionsUsecaseProvider,
        ),
        conversationRepository: ref.watch(conversationRepositoryProvider),
      );
    });
