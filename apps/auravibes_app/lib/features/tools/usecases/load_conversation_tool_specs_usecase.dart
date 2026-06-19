// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/mcp/build_combined_tool_specs_use_case.dart';
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
    this._buildSkillTemplateToolSpecsUsecase,
    this._buildAppSkillNativeToolSpecsUsecase,
  });

  final ConversationToolsRepository _conversationToolsRepository;
  final BuildCombinedToolSpecsUseCase _buildCombinedToolSpecsUseCase;
  final BuildDynamicSkillToolSpecsUsecase _buildDynamicSkillToolSpecsUsecase;
  final SyncSkillToolPermissionsUsecase _syncSkillToolPermissionsUsecase;
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

    final toolSpecs = await _buildCombinedToolSpecsUseCase.call(enabledTools);
    final skillToolSpecs = await _buildDynamicSkillToolSpecsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
    final skillTemplateToolSpecs =
        await _buildSkillTemplateToolSpecsUsecase?.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
        ) ??
        const <ToolSpec>[];
    final appSkillNativeToolSpecs =
        await _buildAppSkillNativeToolSpecsUsecase?.call(
          conversationId: conversationId,
          workspaceId: workspaceId,
        ) ??
        const <ToolSpec>[];
    final enabledSkillToolNames = enabledTools
        .where((tool) => isSkillPermissionToolName(tool.toolId))
        .map((tool) => tool.toolId)
        .toSet();

    return [
      ...toolSpecs,
      ...skillToolSpecs.where(
        (spec) => enabledSkillToolNames.contains(spec.name),
      ),
      ...skillTemplateToolSpecs.where(
        (spec) => enabledSkillToolNames.contains(spec.name),
      ),
      ...appSkillNativeToolSpecs.where(
        (spec) => enabledSkillToolNames.contains(spec.name),
      ),
    ];
  }
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
        buildSkillTemplateToolSpecsUsecase: ref.watch(
          buildSkillTemplateToolSpecsUsecaseProvider,
        ),
        buildAppSkillNativeToolSpecsUsecase: ref.watch(
          buildAppSkillNativeToolSpecsUsecaseProvider,
        ),
      );
    });
