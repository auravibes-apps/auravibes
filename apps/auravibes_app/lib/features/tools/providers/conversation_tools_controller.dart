import 'package:auravibes_app/data/repositories/conversation_tools_repository_impl.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/usecases/tools/conversation/get_context_aware_tool_entities_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/conversation/get_context_aware_tools_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/conversation/resolve_conversation_tool_states_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/conversation/set_conversation_tool_enabled_usecase.dart';
import 'package:auravibes_app/domain/usecases/tools/conversation/set_conversation_tool_permission_usecase.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_tools_controller.freezed.dart';
part 'conversation_tools_controller.g.dart';

/// State for a single tool in a conversation context
@freezed
abstract class ConversationToolState with _$ConversationToolState {
  const factory ConversationToolState({
    required WorkspaceToolEntity tool,
    required bool isEnabled,
    required ToolPermissionMode permissionMode,

    /// Whether this tool is enabled at the workspace level
    required bool isWorkspaceEnabled,
  }) = _ConversationToolState;
}

@Riverpod(keepAlive: true)
ConversationToolsRepository conversationToolsRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);
  final workspaceToolsRepository = ref.watch(workspaceToolsRepositoryProvider);
  return ConversationToolsRepositoryImpl(appDatabase, workspaceToolsRepository);
}

/// Provider for managing conversation tool settings
///
/// Returns a list of all workspace tools with their conversation-level states.
@riverpod
class ConversationToolsController extends _$ConversationToolsController {
  late final ConversationToolsRepository _repository = ref.read(
    conversationToolsRepositoryProvider,
  );

  @override
  Future<List<ConversationToolState>> build({
    required String workspaceId,
    String? conversationId,
  }) async {
    final workspaceToolsRepository = ref.watch(
      workspaceToolsRepositoryProvider,
    );

    final useCase = ResolveConversationToolStatesUseCase(
      getWorkspaceTools: workspaceToolsRepository.getWorkspaceTools,
      getConversationTools: _repository.getConversationTools,
    );

    final states = await useCase.call(
      workspaceId: workspaceId,
      conversationId: conversationId,
    );

    return states
        .map(
          (state) => ConversationToolState(
            tool: state.tool,
            isEnabled: state.isEnabled,
            permissionMode: state.permissionMode,
            isWorkspaceEnabled: state.isWorkspaceEnabled,
          ),
        )
        .toList();
  }

  /// Toggle a conversation tool's enabled status
  Future<bool> toggleTool(String toolId) async {
    final currentState = state.value;
    if (currentState == null) return false;

    final index = currentState.indexWhere(
      (t) => t.tool.id == toolId,
    );
    if (index == -1) return false;

    final currentToolState = currentState[index];
    return setToolEnabled(toolId, isEnabled: !currentToolState.isEnabled);
  }

  /// Enable or disable a conversation tool
  Future<bool> setToolEnabled(
    String toolId, {
    required bool isEnabled,
  }) async {
    final success =
        await SetConversationToolEnabledUseCase(
          setConversationToolEnabled: _repository.setConversationToolEnabled,
        ).call(
          conversationId: conversationId,
          toolId: toolId,
          isEnabled: isEnabled,
        );
    if (success && state.value != null) {
      final currentList = state.value!;
      final index = currentList.indexWhere(
        (t) => t.tool.id == toolId,
      );
      if (index != -1) {
        final updatedList = List<ConversationToolState>.from(currentList);
        updatedList[index] = currentList[index].copyWith(isEnabled: isEnabled);
        state = AsyncData(updatedList);
      }
    }
    return success;
  }

  /// Set the permission mode for a conversation tool
  Future<bool> setToolPermission(
    String toolId, {
    required ToolPermissionMode permissionMode,
  }) async {
    final success =
        await SetConversationToolPermissionUseCase(
          setConversationToolPermission:
              _repository.setConversationToolPermission,
        ).call(
          conversationId: conversationId,
          toolId: toolId,
          permissionMode: permissionMode,
        );
    if (success && state.value != null) {
      final currentList = state.value!;
      final index = currentList.indexWhere(
        (t) => t.tool.id == toolId,
      );
      if (index != -1) {
        final updatedList = List<ConversationToolState>.from(currentList);
        updatedList[index] = currentList[index].copyWith(
          permissionMode: permissionMode,
        );
        state = AsyncData(updatedList);
      }
    }
    return success;
  }

  /// Get the current enabled tools as a list of tool IDs
  List<String> getEnabledToolIds() {
    final currentState = state.value;
    if (currentState == null) return [];

    return currentState
        .where((tool) => tool.isEnabled)
        .map((tool) => tool.tool.id)
        .toList();
  }

  /// Get the current tool states list
  List<ConversationToolState> getToolStates() {
    return state.value ?? [];
  }
}

/// Provider to get context-aware tools for chat
/// (conversation -> workspace -> app defaults)
@riverpod
class ContextAwareToolsController extends _$ContextAwareToolsController {
  late ConversationToolsRepository _repository;

  @override
  Future<List<String>> build({
    required String conversationId,
    required String workspaceId,
  }) async {
    _repository = ref.read(conversationToolsRepositoryProvider);

    return _getContextAwareTools();
  }

  Future<List<String>> _getContextAwareTools() async {
    return GetContextAwareToolsUseCase(
      getAvailableTools: _repository.getAvailableToolsForConversation,
    ).call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
  }

  /// Refresh the context-aware tools list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _getContextAwareTools());
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider to get context-aware tools as full entities for chat.
///
/// Returns [WorkspaceToolEntity] list with table IDs needed for
/// generating composite tool IDs.
/// (conversation -> workspace -> app defaults)
@riverpod
class ContextAwareToolEntitiesController
    extends _$ContextAwareToolEntitiesController {
  late ConversationToolsRepository _repository;

  @override
  Future<List<WorkspaceToolEntity>> build({
    required String conversationId,
    required String workspaceId,
  }) async {
    _repository = ref.read(conversationToolsRepositoryProvider);

    return _getContextAwareToolEntities();
  }

  Future<List<WorkspaceToolEntity>> _getContextAwareToolEntities() async {
    return GetContextAwareToolEntitiesUseCase(
      getAvailableToolEntities:
          _repository.getAvailableToolEntitiesForConversation,
    ).call(
      conversationId: conversationId,
      workspaceId: workspaceId,
    );
  }

  /// Refresh the context-aware tools list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _getContextAwareToolEntities());
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
