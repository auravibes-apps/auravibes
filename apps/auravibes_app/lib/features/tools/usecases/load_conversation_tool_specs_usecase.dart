// ignore_for_file: implementation_imports
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_combined_tool_specs_use_case.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
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
  final ConversationRepository? conversationRepository,
  // Ponytail: Compatibility only; manifests now own materialization.
  // ignore: avoid_unused_constructor_parameters
  BuildSkillTemplateToolSpecsUsecase? buildSkillTemplateToolSpecsUsecase,
  // Native materializer remains accepted by legacy direct callers.
  // ignore: avoid_unused_constructor_parameters
  BuildAppSkillNativeToolSpecsUsecase? buildAppSkillNativeToolSpecsUsecase,
}) {
  Future<List<ToolSpec>> call({
    required String conversationId,
    required String workspaceId,
  }) async => (await buildCatalog(
    conversationId: conversationId,
    workspaceId: workspaceId,
  )).specs;

  Future<agent.ToolCatalog<ResolvedTool>> buildCatalog({
    required String conversationId,
    required String workspaceId,
  }) async {
    await _syncSkillToolPermissionsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );

    return await _buildCatalogForConversation(conversationId, workspaceId);
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
  ) async {
    final input = await _loadCatalogInput(conversationId, workspaceId);

    return _buildCatalog(
      toolCandidates: input.toolCandidates,
      skillCommandSpecs: input.skillCommandSpecs,
      includeRunSubAgent: await _includeRunSubAgent(conversationId),
    );
  }

  Future<
    ({
      List<agent.ToolCatalogCandidate<ResolvedTool>> toolCandidates,
      List<ToolSpec> skillCommandSpecs,
    })
  >
  _loadCatalogInput(String conversationId, String workspaceId) async => (
    toolCandidates: await _loadToolCandidates(conversationId, workspaceId),
    skillCommandSpecs: await _buildDynamicSkillToolSpecsUsecase.call(
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
  required List<agent.ToolCatalogCandidate<ResolvedTool>> toolCandidates,
  required List<ToolSpec> skillCommandSpecs,
  required bool includeRunSubAgent,
}) => agent.buildToolCatalog([
  ...toolCandidates,
  ...skillCommandSpecs.map(_skillCommandCandidate),
  if (includeRunSubAgent) _runSubAgentCandidate(),
]);

agent.ToolCatalogCandidate<ResolvedTool> _skillCommandCandidate(
  ToolSpec spec,
) => agent.ToolCatalogCandidate.reserved(
  spec: spec,
  target: ResolvedTool.skillCommand(commandName: spec.name),
);

agent.ToolCatalogCandidate<ResolvedTool> _runSubAgentCandidate() =>
    agent.ToolCatalogCandidate.reserved(
      spec: agent.runSubAgentToolSpec,
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
        conversationRepository: ref.watch(conversationRepositoryProvider),
      );
    });
