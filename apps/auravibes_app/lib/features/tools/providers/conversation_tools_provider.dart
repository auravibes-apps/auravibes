import 'package:auravibes_app/data/repositories/conversation_tools_repository_impl.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_tools_provider.g.dart';

/// Combined state for workspace tools with their conversation-specific
/// toggle states
class ConversationToolsState {
  // toolType -> isEnabled for conversation

  const ConversationToolsState({required this.toolStates});
  final Map<UserToolType, bool> toolStates;

  /// Get the enabled state for a specific tool
  bool isToolEnabled(UserToolType toolType) {
    return toolStates[toolType] ?? true; // Default to enabled for new chats
  }
}

@riverpod
ConversationToolsRepository conversationToolsRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);
  final workspaceToolsRepository = ref.watch(workspaceToolsRepositoryProvider);
  return ConversationToolsRepositoryImpl(appDatabase, workspaceToolsRepository);
}

@riverpod
class ConversationToolsNotifier extends _$ConversationToolsNotifier {
  late final ConversationToolsRepository _repository = ref.read(
    conversationToolsRepositoryProvider,
  );

  @override
  Future<Map<UserToolType, bool>> build({
    required String workspaceId,
    String? conversationId,
  }) async {
    final repository = ref.watch(conversationToolsRepositoryProvider);

    final workspaceToolsRepository = ref.watch(
      workspaceToolsRepositoryProvider,
    );

    final workspaceTools = await workspaceToolsRepository
        .getEnabledWorkspaceTools(workspaceId);

    // Get available tool types from service
    final availableToolTypes = ToolService.getTypes();

    final workspaceEnabeldTools = availableToolTypes.where(
      (toolType) =>
          workspaceTools.any((element) => element.toolId == toolType.value),
    );

    final toolStates = {
      for (final typeTool in workspaceEnabeldTools) typeTool: true,
    };

    if (conversationId != null && conversationId.isNotEmpty) {
      // Get conversation tool overrides
      final conversationTools = await repository.getConversationTools(
        conversationId,
      );
      final disabledTools = conversationTools
          .map((e) => UserToolType.fromValue(e.toolId))
          .nonNulls;

      toolStates.addAll({
        for (final typeTool in disabledTools) typeTool: false,
      });
    }

    return toolStates;
  }

  /// Toggle a conversation tool's enabled status
  Future<bool> toggleTool(String toolType) async {
    final currentState = state.value;
    if (currentState == null) return false;

    if (currentState.containsKey(UserToolType.fromValue(toolType))) {
      final newEnabledState = currentState[UserToolType.fromValue(toolType)]!;
      return setToolEnabled(toolType, isEnabled: newEnabledState);
    }
    return false;
  }

  /// Enable or disable a conversation tool
  Future<bool> setToolEnabled(
    String toolType, {
    required bool isEnabled,
  }) async {
    var success = true;
    if (conversationId != null) {
      success = await _repository.setConversationToolEnabled(
        conversationId!,
        toolType,
        isEnabled: isEnabled,
      );
    }
    if (success && state.value != null) {
      state = AsyncData(
        state.value!.map((key, value) {
          if (key.value == toolType) {
            return MapEntry(key, isEnabled);
          }
          return MapEntry(key, value);
        }),
      );
    }
    return success;
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
    state = const .loading();
    try {
      state = .data(await _getContextAwareTools());
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
