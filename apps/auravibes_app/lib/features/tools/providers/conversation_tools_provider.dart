import 'package:auravibes_app/data/repositories/conversation_tools_repository_impl.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_tools_provider.freezed.dart';
part 'conversation_tools_provider.g.dart';

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

@riverpod
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

    // Get ALL workspace tools (not just enabled ones)
    final workspaceTools = await workspaceToolsRepository.getWorkspaceTools(
      workspaceId,
    );

    // Build initial tool states from workspace tools
    final toolStates = workspaceTools.map((workspaceTool) {
      return ConversationToolState(
        tool: workspaceTool,
        // Default: enabled if workspace has it enabled
        isEnabled: workspaceTool.isEnabled,
        // Default: inherit workspace permission
        permissionMode: workspaceTool.permissionMode,
        isWorkspaceEnabled: workspaceTool.isEnabled,
      );
    }).toList();

    // If we have a conversation, get conversation-level overrides
    if (conversationId != null && conversationId.isNotEmpty) {
      final conversationTools = await _repository.getConversationTools(
        conversationId,
      );

      for (final tool in conversationTools) {
        final index = toolStates.indexWhere(
          (t) => t.tool.id == tool.toolId,
        );
        if (index != -1) {
          toolStates[index] = toolStates[index].copyWith(
            isEnabled: tool.isEnabled,
            permissionMode: tool.permissionMode,
          );
        }
      }
    }

    return toolStates;
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
    var success = true;
    if (conversationId != null && conversationId!.isNotEmpty) {
      success = await _repository.setConversationToolEnabled(
        conversationId!,
        toolId,
        isEnabled: isEnabled,
      );
    }
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
    var success = true;
    if (conversationId != null && conversationId!.isNotEmpty) {
      success = await _repository.setConversationToolPermission(
        conversationId!,
        toolId,
        permissionMode: permissionMode,
      );
    }
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
class ContextAwareToolsNotifier extends _$ContextAwareToolsNotifier {
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

// ============================================================
// Composite Tool ID Generation
// ============================================================

/// Generates a composite ID for a built-in tool.
///
/// Format: `built_in::<table_id>::<tool_identifier>`
/// - table_id: Database ID of the workspace tool (for permission checks)
/// - tool_identifier: The tool type value (e.g., "calculator")
String generateBuiltInCompositeId({
  required String tableId,
  required String toolIdentifier,
}) {
  return 'built_in::$tableId::$toolIdentifier';
}

/// Provider to get context-aware tools as full entities for chat.
///
/// Returns [WorkspaceToolEntity] list with table IDs needed for
/// generating composite tool IDs.
/// (conversation -> workspace -> app defaults)
@riverpod
class ContextAwareToolEntitiesNotifier
    extends _$ContextAwareToolEntitiesNotifier {
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
