// Required: Existing argument values intentionally repeat.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_tool_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_tool_state.freezed.dart';
part 'conversation_tool_state.g.dart';

/// State for a single tool in a conversation context.
@freezed
abstract class ConversationToolState with _$ConversationToolState {
  const factory({
    required WorkspaceToolEntity tool,
    required bool isEnabled,
    required ToolPermissionMode permissionMode,

    /// Whether this tool is enabled at the workspace level.
    required bool isWorkspaceEnabled,
  }) = _ConversationToolState;
}

@riverpod
ConversationToolsRepository conversationToolsRepository(
  Ref ref,
  String workspaceId,
) {
  final session = ref
      .watch(workspaceSessionForRouteProvider(workspaceId))
      .requireValue;
  session.capabilities.require(
    supported: session.capabilities.conversationToolOverrides,
  );

  return ConversationToolsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(workspaceToolsRepositoryProvider(session))
        as WorkspaceToolsRepository,
  );
}

Future<List<ConversationToolState>> _loadConversationToolStates(
  WorkspaceToolsRepositoryContract workspaceToolsRepository,
  ConversationToolsRepository repository,
  String workspaceId,
  String? conversationId,
) async {
  final workspaceTools = await workspaceToolsRepository.getWorkspaceTools(
    workspaceId,
  );
  final states = _conversationToolStates(workspaceTools);

  if (conversationId == null || conversationId.isEmpty) return states;

  final conversationTools = await repository.getConversationTools(
    conversationId,
  );
  _applyConversationToolOverrides(states, conversationTools);

  return states;
}

List<ConversationToolState> _conversationToolStates(
  List<WorkspaceToolEntity> workspaceTools,
) => workspaceTools.map(_conversationToolState).toList();

ConversationToolState _conversationToolState(WorkspaceToolEntity tool) =>
    ConversationToolState(
      tool: tool,
      isEnabled: tool.isEnabled,
      permissionMode: tool.permissionMode,
      isWorkspaceEnabled: tool.isEnabled,
    );

void _applyConversationToolOverrides(
  List<ConversationToolState> states,
  List<ConversationToolEntity> tools,
) {
  final stateIndexByWorkspaceToolId = _stateIndexByWorkspaceToolId(states);
  for (final tool in tools) {
    _applyConversationToolOverride(states, stateIndexByWorkspaceToolId, tool);
  }
}

Map<String, int> _stateIndexByWorkspaceToolId(
  List<ConversationToolState> states,
) => {for (var i = 0; i < states.length; i++) states[i].tool.id: i};

void _applyConversationToolOverride(
  List<ConversationToolState> states,
  Map<String, int> stateIndexByWorkspaceToolId,
  ConversationToolEntity tool,
) {
  final index = stateIndexByWorkspaceToolId[tool.toolId];
  if (index == null) return;

  states[index] = states[index].copyWith(
    isEnabled: tool.isEnabled,
    permissionMode: tool.permissionMode,
  );
}

int _toolStateIndex(List<ConversationToolState> states, String toolId) =>
    states.indexWhere((tool) => tool.tool.id == toolId);

/// Provider for managing conversation tool settings
///
/// Returns a list of all workspace tools with their conversation-level states.
@riverpod
class ConversationToolsNotifier extends _$ConversationToolsNotifier
    with _ConversationToolsNotifierActions {
  @override
  String _workspaceIdValue = '';

  @override
  Future<List<ConversationToolState>> build({
    required String workspaceId,
    String? conversationId,
  }) async {
    _workspaceIdValue = workspaceId;
    final session = ref
        .watch(workspaceSessionForRouteProvider(workspaceId))
        .requireValue;
    final workspaceToolsRepository = ref.watch(
      workspaceToolsRepositoryProvider(session),
    );

    return await _loadConversationToolStates(
      workspaceToolsRepository,
      _repository,
      workspaceId,
      conversationId,
    );
  }

  /// Toggle a conversation tool's enabled status.
  Future<bool> toggleTool(String toolId) async {
    final currentState = state.value;
    if (currentState == null) return false;

    final index = _toolStateIndex(currentState, toolId);
    if (index == -1) return false;

    return await setToolEnabled(
      toolId,
      isEnabled: !currentState[index].isEnabled,
    );
  }

  /// Enable or disable a conversation tool.
  Future<bool> setToolEnabled(String toolId, {required bool isEnabled}) {
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

mixin _ConversationToolsNotifierActions on _$ConversationToolsNotifier {
  String get _workspaceIdValue;

  String get _workspaceId => _workspaceIdValue.isNotEmpty
      ? _workspaceIdValue
      : (throw StateError('Conversation tools are not initialized'));

  ConversationToolsRepository get _repository =>
      ref.read(conversationToolsRepositoryProvider(_workspaceId));

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
    if (success) _patchConversationTool(toolId, patch);

    return success;
  }

  void _patchConversationTool(
    String toolId,
    ConversationToolState Function(ConversationToolState) patch,
  ) {
    final currentList = state.value;
    if (currentList == null) return;

    final index = _toolStateIndex(currentList, toolId);
    if (index == -1) return;

    state = AsyncData(_updatedConversationToolList(currentList, index, patch));
  }

  List<ConversationToolState> _updatedConversationToolList(
    List<ConversationToolState> currentList,
    int index,
    ConversationToolState Function(ConversationToolState) patch,
  ) {
    final updatedList = List<ConversationToolState>.of(currentList);
    updatedList[index] = patch(currentList[index]);

    return updatedList;
  }
}

/// Provider to get context-aware tools for chat (conversation, workspace, and
/// app defaults).
@riverpod
class ContextAwareToolsNotifier extends _$ContextAwareToolsNotifier {
  String? _workspaceIdValue;

  String get _workspaceId =>
      _workspaceIdValue ??
      (throw StateError('Context-aware tools are not initialized'));

  ConversationToolsRepository get _repository =>
      ref.read(conversationToolsRepositoryProvider(_workspaceId));

  @override
  Future<List<String>> build({
    required String conversationId,
    required String workspaceId,
  }) async {
    _workspaceIdValue = workspaceId;

    return await _getContextAwareTools();
  }

  /// Refresh the context-aware tools list.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = .data(await _getContextAwareTools());
    } on Exception catch (error, stackTrace) {
      state = .error(error, stackTrace);
    }
  }

  Future<List<String>> _getContextAwareTools() {
    return _repository.getAvailableToolsForConversation(
      conversationId,
      workspaceId,
    );
  }
}

/// Provider to get context-aware tools as full entities for chat.
///
/// Returns a [WorkspaceToolEntity] list with table IDs needed for generating
/// composite tool IDs across conversation, workspace, and app defaults.
@riverpod
class ContextAwareToolEntitiesNotifier
    extends _$ContextAwareToolEntitiesNotifier {
  String? _workspaceIdValue;

  String get _workspaceId =>
      _workspaceIdValue ??
      (throw StateError('Context-aware tool entities are not initialized'));

  ConversationToolsRepository get _repository =>
      ref.read(conversationToolsRepositoryProvider(_workspaceId));

  @override
  Future<List<WorkspaceToolEntity>> build({
    required String conversationId,
    required String workspaceId,
  }) async {
    _workspaceIdValue = workspaceId;

    return await _getContextAwareToolEntities();
  }

  /// Refresh the context-aware tools list.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = .data(await _getContextAwareToolEntities());
    } on Exception catch (error, stackTrace) {
      state = .error(error, stackTrace);
    }
  }

  Future<List<WorkspaceToolEntity>> _getContextAwareToolEntities() {
    return _repository.getAvailableToolEntitiesForConversation(
      conversationId,
      workspaceId,
    );
  }
}
