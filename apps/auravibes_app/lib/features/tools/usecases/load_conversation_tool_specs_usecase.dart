// ignore_for_file: implementation_imports
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_combined_tool_specs_use_case.dart';
import 'package:auravibes_app/features/skills/usecases/build_app_skill_native_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_dynamic_skill_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/build_skill_template_tool_specs_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/sync_skill_tool_permissions_usecase.dart';
import 'package:auravibes_app/features/tools/notifiers/conversation_tool_state.dart';
import 'package:auravibes_app/features/tools/notifiers/grouped_tools_notifier.dart';
import 'package:auravibes_app/features/tools/providers/mcp_tool_spec_lookup.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:auravibes_engine/auravibes_engine.dart' show ToolSpec;
import 'package:riverpod/src/providers/provider.dart';

class LoadConversationToolSpecsUsecase {
  const LoadConversationToolSpecsUsecase({
    required this._conversationToolsRepository,
    required this._buildCombinedToolSpecsUseCase,
    required this._buildDynamicSkillToolSpecsUsecase,
    required this._syncSkillToolPermissionsUsecase,
    // ponytail: Compatibility only; manifests now own materialization.
    // ignore: avoid_unused_constructor_parameters
    BuildSkillTemplateToolSpecsUsecase? buildSkillTemplateToolSpecsUsecase,
    // Native materializer remains accepted by legacy direct callers.
    // ignore: avoid_unused_constructor_parameters
    BuildAppSkillNativeToolSpecsUsecase? buildAppSkillNativeToolSpecsUsecase,
  });

  final ConversationToolsRepository _conversationToolsRepository;
  final BuildCombinedToolSpecsUseCase _buildCombinedToolSpecsUseCase;
  final BuildDynamicSkillToolSpecsUsecase _buildDynamicSkillToolSpecsUsecase;
  final SyncSkillToolPermissionsUsecase _syncSkillToolPermissionsUsecase;
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
    final toolSpecs = await _buildCombinedToolSpecsUseCase.call(enabledTools);
    final skillToolSpecs = await _buildDynamicSkillToolSpecsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );

    return agent.uniqueToolSpecs([
      ...toolSpecs,
      ...skillToolSpecs,
      agent.runSubAgentToolSpec,
    ]);
  }
}

final ProviderFamily<LoadConversationToolSpecsUsecase, String>
loadConversationToolSpecsUsecaseProvider =
    Provider.family<LoadConversationToolSpecsUsecase, String>((
      ref,
      workspaceId,
    ) {
      final session = ref
          .watch(
            workspaceSessionForRouteProvider(workspaceId),
          )
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
      );
    });
