import 'package:auravibes_app/data/repositories/conversation_tools_repository_impl.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
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

    final states =
        (await workspaceToolsRepository.getWorkspaceTools(workspaceId))
            .map(
              (workspaceTool) => ConversationToolState(
                tool: workspaceTool,
                isEnabled: workspaceTool.isEnabled,
                permissionMode: workspaceTool.permissionMode,
                isWorkspaceEnabled: workspaceTool.isEnabled,
              ),
            )
            .toList();

    if (conversationId != null && conversationId.isNotEmpty) {
      final conversationTools = await _repository.getConversationTools(
        conversationId,
      );
      for (final tool in conversationTools) {
        final index = states.indexWhere(
          (state) => state.tool.id == tool.toolId,
        );
        if (index == -1) {
          continue;
        }

        states[index] = states[index].copyWith(
          isEnabled: tool.isEnabled,
          permissionMode: tool.permissionMode,
        );
      }
    }

    return states;
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
        (conversationId == null || conversationId!.isEmpty) ||
        await _repository.setConversationToolEnabled(
          conversationId!,
          toolId,
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
        (conversationId == null || conversationId!.isEmpty) ||
        await _repository.setConversationToolPermission(
          conversationId!,
          toolId,
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
    return _repository.getAvailableToolsForConversation(
      conversationId,
      workspaceId,
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
    return _repository.getAvailableToolEntitiesForConversation(
      conversationId,
      workspaceId,
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
