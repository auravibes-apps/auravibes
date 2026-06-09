// ignore_for_file: no-equal-arguments
// Required: Existing argument values intentionally repeat.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/data/repositories/conversation_tools_repository_impl.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_tool_state.freezed.dart';
part 'conversation_tool_state.g.dart';

/// State for a single tool in a conversation context.
@freezed
abstract class ConversationToolState with _$ConversationToolState {
  const factory ConversationToolState({
    required WorkspaceToolEntity tool,
    required bool isEnabled,
    required ToolPermissionMode permissionMode,

    /// Whether this tool is enabled at the workspace level.
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
class ConversationToolsNotifier extends _$ConversationToolsNotifier {
  ConversationToolsRepository get _repository => ref.read(
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

    // ConversationToolEntity.toolId stores the workspace tool record ID.
    // It matches WorkspaceToolEntity.id, not WorkspaceToolEntity.toolId.
    final stateIndexByWorkspaceToolId = <String, int>{
      for (var i = 0; i < states.length; i++) states[i].tool.id: i,
    };

    if (conversationId != null && conversationId.isNotEmpty) {
      final conversationTools = await _repository.getConversationTools(
        conversationId,
      );
      for (final tool in conversationTools) {
        final index = stateIndexByWorkspaceToolId[tool.toolId];
        if (index == null) {
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

  /// Toggle a conversation tool's enabled status.
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

  /// Enable or disable a conversation tool.
  Future<bool> setToolEnabled(
    String toolId, {
    required bool isEnabled,
  }) {
    return _updateConversationTool(
      toolId: toolId,
      persist: (convId) => _repository.setConversationToolEnabled(
        convId,
        toolId,
        isEnabled: isEnabled,
      ),
      patch: (current) => current.copyWith(isEnabled: isEnabled),
    );
  }

  Future<bool> setToolPermission(
    String toolId, {
    required ToolPermissionMode permissionMode,
  }) {
    return _updateConversationTool(
      toolId: toolId,
      persist: (convId) => _repository.setConversationToolPermission(
        convId,
        toolId,
        permissionMode: permissionMode,
      ),
      patch: (current) => current.copyWith(permissionMode: permissionMode),
    );
  }

  Future<bool> _updateConversationTool({
    required String toolId,
    required Future<bool> Function(String conversationId) persist,
    required ConversationToolState Function(ConversationToolState) patch,
  }) async {
    final convId = conversationId;
    if (convId == null || convId.isEmpty) {
      return false;
    }
    final success = await persist(convId);
    final currentList = state.value;
    if (success && currentList != null) {
      final index = currentList.indexWhere(
        (t) => t.tool.id == toolId,
      );
      if (index != -1) {
        final updatedList = List<ConversationToolState>.of(currentList);
        updatedList[index] = patch(currentList[index]);
        state = AsyncData(updatedList);
      }
    }
    return success;
  }

  /// Get the current enabled tools as a list of tool IDs.
  List<String> getEnabledToolIds() {
    final currentState = state.value;
    if (currentState == null) return [];

    return currentState
        .where((tool) => tool.isEnabled)
        .map((tool) => tool.tool.id)
        .toList();
  }

  /// Get the current tool states list.
  List<ConversationToolState> getToolStates() {
    return state.value ?? [];
  }
}

/// Provider to get context-aware tools for chat.
/// (conversation -> workspace -> app defaults)
@riverpod
class ContextAwareToolsNotifier extends _$ContextAwareToolsNotifier {
  ConversationToolsRepository get _repository => ref.read(
    conversationToolsRepositoryProvider,
  );

  @override
  Future<List<String>> build({
    required String conversationId,
    required String workspaceId,
  }) async {
    return _getContextAwareTools();
  }

  Future<List<String>> _getContextAwareTools() {
    return _repository.getAvailableToolsForConversation(
      conversationId,
      workspaceId,
    );
  }

  /// Refresh the context-aware tools list.
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
class ContextAwareToolEntitiesNotifier
    extends _$ContextAwareToolEntitiesNotifier {
  ConversationToolsRepository get _repository => ref.read(
    conversationToolsRepositoryProvider,
  );

  @override
  Future<List<WorkspaceToolEntity>> build({
    required String conversationId,
    required String workspaceId,
  }) async {
    return _getContextAwareToolEntities();
  }

  Future<List<WorkspaceToolEntity>> _getContextAwareToolEntities() {
    return _repository.getAvailableToolEntitiesForConversation(
      conversationId,
      workspaceId,
    );
  }

  /// Refresh the context-aware tools list.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _getContextAwareToolEntities());
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
