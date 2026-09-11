// Required: Existing argument values intentionally repeat.
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_tool_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';

typedef _AvailableWorkspaceToolsInput = ({
  String conversationId,
  String workspaceId,
  List<WorkspaceToolEntity> workspaceEnabledTools,
  Set<String> disabledWorkspaceToolIds,
});

typedef _ChildPermissionPrecedence = ({
  ToolPermissionResult? agentResult,
  ToolPermissionResult? parentResult,
});

typedef _ChildPermissionFallbackInput = ({
  ToolPermissionResult? childResult,
  ToolPermissionResult? agentResult,
  ToolPermissionResult? parentResult,
  WorkspaceToolEntity workspaceTool,
});

/// Implementation of the ConversationToolsRepository.
class ConversationToolsRepository(
  final AppDatabase _database,
  final WorkspaceToolsRepository _workspaceToolsRepository,
) with
    _ConversationToolsRepositoryBasicApi,
    _ConversationToolsRepositoryBasicStateApi,
    _ConversationToolsRepositorySecondaryApi,
    _ConversationToolsAvailabilityApi {
  final ConversationToolsDao _dao = _database.conversationToolsDao;

  Future<List<ConversationToolEntity>> getConversationTools(
    String conversationId,
  ) async {
    final results = await _dao.getConversationTools(conversationId);

    return results.map(_tableToEntity).toList();
  }
}

mixin _ConversationToolsRepositoryBasicApi {
  Future<List<ConversationToolEntity>> getEnabledConversationTools(
    String conversationId,
  ) =>
      ConversationToolsRepositoryBasic(this as ConversationToolsRepository)
          .getEnabledConversationTools(conversationId);

  Future<ConversationToolEntity?> getConversationTool(
    String conversationId,
    String toolId,
  ) =>
      ConversationToolsRepositoryBasic(this as ConversationToolsRepository)
          .getConversationTool(conversationId, toolId);

  Future<bool> setConversationToolEnabled(
    String conversationId,
    String toolId, {
    required bool isEnabled,
  }) => ConversationToolsRepositoryBasic(this as ConversationToolsRepository)
      .setConversationToolEnabled(conversationId, toolId, isEnabled: isEnabled);

  Future<void> setConversationToolsDisabled(
    String conversationId,
    List<String> toolTypes,
  ) =>
      ConversationToolsRepositoryBasic(this as ConversationToolsRepository)
          .setConversationToolsDisabled(conversationId, toolTypes);

  Future<bool> setConversationToolPermission(
    String conversationId,
    String toolId, {
    required ToolPermissionMode permissionMode,
  }) => ConversationToolsRepositoryBasic(this as ConversationToolsRepository)
      .setConversationToolPermission(
        conversationId,
        toolId,
        permissionMode: permissionMode,
      );
}

mixin _ConversationToolsRepositoryBasicStateApi {
  Future<bool> toggleConversationTool(String conversationId, String toolId) =>
      ConversationToolsRepositoryBasicState(this as ConversationToolsRepository)
          .toggleConversationTool(conversationId, toolId);

  Future<bool> isConversationToolEnabled(
    String conversationId,
    String toolId,
  ) =>
      ConversationToolsRepositoryBasicState(this as ConversationToolsRepository)
          .isConversationToolEnabled(conversationId, toolId);

  Future<bool> removeConversationTool(String conversationId, String toolId) =>
      ConversationToolsRepositoryBasicState(this as ConversationToolsRepository)
          .removeConversationTool(conversationId, toolId);

  Future<int> getConversationToolsCount(String conversationId) =>
      ConversationToolsRepositoryBasicState(this as ConversationToolsRepository)
          .getConversationToolsCount(conversationId);
}

mixin _ConversationToolsRepositorySecondaryApi {
  Future<int> getEnabledConversationToolsCount(String conversationId) =>
      ConversationToolsRepositorySecondary(this as ConversationToolsRepository)
          .getEnabledConversationToolsCount(conversationId);

  Future<void> copyConversationTools(
    String sourceConversationId,
    String targetConversationId,
  ) =>
      ConversationToolsRepositorySecondary(this as ConversationToolsRepository)
          .copyConversationTools(sourceConversationId, targetConversationId);

  Future<bool> validateConversationToolSetting(
    String conversationId,
    String toolId,
  ) =>
      ConversationToolsRepositorySecondary(this as ConversationToolsRepository)
          .validateConversationToolSetting(conversationId, toolId);
}

mixin _ConversationToolsAvailabilityApi {
  Future<bool> isToolAvailableForConversation(
    String conversationId,
    String workspaceId,
    String toolId,
  ) => ConversationToolsRepositoryAvailability(
    this as ConversationToolsRepository,
  ).isToolAvailableForConversation(conversationId, workspaceId, toolId);

  Future<List<String>> getAvailableToolsForConversation(
    String conversationId,
    String workspaceId,
  ) => ConversationToolsRepositoryAvailability(
    this as ConversationToolsRepository,
  ).getAvailableToolsForConversation(conversationId, workspaceId);

  Future<List<WorkspaceToolEntity>> getAvailableToolEntitiesForConversation(
    String conversationId,
    String workspaceId,
  ) => ConversationToolsRepositoryAvailability(
    this as ConversationToolsRepository,
  ).getAvailableToolEntitiesForConversation(conversationId, workspaceId);

  Future<ToolPermissionResult> checkToolPermission({
    required String conversationId,
    required String workspaceId,
    required String toolId,
  }) =>
      ConversationToolsRepositoryAvailability(
        this as ConversationToolsRepository,
      ).checkToolPermission(
        conversationId: conversationId,
        workspaceId: workspaceId,
        toolId: toolId,
      );
}

extension ConversationToolsRepositoryBasic on ConversationToolsRepository {
  Future<List<ConversationToolEntity>> getEnabledConversationTools(
    String conversationId,
  ) async {
    final conversation = await _database.conversationDao.getConversationById(
      conversationId,
    );
    if (conversation == null) {
      return [];
    }

    // Get available tools for the conversation by computing:.
    // Available tools = Workspace enabled tools - Conversation disabled tools.
    return await _buildEnabledConversationTools(
      conversationId,
      conversation.workspaceId,
    );
  }

  Future<ConversationToolEntity?> getConversationTool(
    String conversationId,
    String toolId,
  ) async {
    final result = await _dao.getConversationTool(conversationId, toolId);
    if (result == null) return null;

    return _tableToEntity(result);
  }

  Future<bool> setConversationToolEnabled(
    String conversationId,
    String toolId, {
    required bool isEnabled,
  }) async {
    final _ = await _dao.setConversationToolEnabled(
      conversationId,
      toolId,
      isEnabled: isEnabled,
    );

    return true;
  }

  Future<void> setConversationToolsDisabled(
    String conversationId,
    List<String> toolTypes,
  ) {
    return _dao.disableConversationTools(conversationId, toolTypes);
  }

  Future<bool> setConversationToolPermission(
    String conversationId,
    String toolId, {
    required ToolPermissionMode permissionMode,
  }) async {
    final _ = await _dao.setConversationToolPermission(
      conversationId,
      toolId,
      permission: _mapPermissionMode(permissionMode),
    );

    return true;
  }
}

extension ConversationToolsRepositoryBasicState on ConversationToolsRepository {
  Future<bool> toggleConversationTool(String conversationId, String toolId) {
    return _dao.toggleConversationTool(conversationId, toolId);
  }

  Future<bool> isConversationToolEnabled(String conversationId, String toolId) {
    return _dao.isConversationToolEnabled(conversationId, toolId);
  }

  Future<bool> removeConversationTool(String conversationId, String toolId) {
    return _dao.deleteConversationTool(conversationId, toolId);
  }

  Future<int> getConversationToolsCount(String conversationId) {
    return _dao.getConversationToolsCount(conversationId);
  }
}

extension ConversationToolsRepositorySecondary on ConversationToolsRepository {
  Future<int> getEnabledConversationToolsCount(String conversationId) async {
    final conversation = await _database.conversationDao.getConversationById(
      conversationId,
    );
    if (conversation == null) return 0;

    return await _availableToolCount(conversationId, conversation.workspaceId);
  }

  Future<void> copyConversationTools(
    String sourceConversationId,
    String targetConversationId,
  ) async {
    await _dao.copyConversationTools(
      sourceConversationId,
      targetConversationId,
    );
  }

  Future<bool> validateConversationToolSetting(
    String conversationId,
    String toolId,
  ) async {
    await _requireConversationToolSetting(conversationId, toolId);

    return true;
  }
}

extension on ConversationToolsRepository {
  Future<void> _requireConversationToolSetting(
    String conversationId,
    String toolId,
  ) async {
    final conversation = await _requireConversation(conversationId);
    await _requireWorkspaceTool(conversation.workspaceId, toolId);
  }

  Future<ConversationsTable> _requireConversation(String conversationId) async {
    final conversation = await _database.conversationDao.getConversationById(
      conversationId,
    );

    if (conversation == null) {
      throw ConversationToolsValidationException(
        'Conversation not found: $conversationId',
        localizationKey:
            LocaleKeys.chats_screens_chat_conversation_error_not_found,
      );
    }

    return conversation;
  }

  Future<void> _requireWorkspaceTool(String workspaceId, String toolId) async {
    final tool = await _workspaceToolsRepository.getWorkspaceTool(
      workspaceId,
      toolId,
    );

    if (tool == null) {
      throw ConversationToolsValidationException(
        'Tool not found: $toolId',
        localizationKey: LocaleKeys.tool_call_status_tool_not_found,
      );
    }
  }
}

extension ConversationToolsRepositoryAvailability
    on ConversationToolsRepository {
  Future<bool> isToolAvailableForConversation(
    String conversationId,
    String workspaceId,
    String toolId,
  ) async {
    return await _isAvailableWorkspaceTool(
      conversationId: conversationId,
      workspaceId: workspaceId,
      toolId: toolId,
    );
  }

  Future<List<String>> getAvailableToolsForConversation(
    String conversationId,
    String workspaceId,
  ) async {
    final availableTools = await getAvailableToolEntitiesForConversation(
      conversationId,
      workspaceId,
    );

    return availableTools.map((tool) => tool.toolId).toList();
  }

  Future<List<WorkspaceToolEntity>> getAvailableToolEntitiesForConversation(
    String conversationId,
    String workspaceId,
  ) {
    return _getAvailableWorkspaceToolsForConversation(
      conversationId,
      workspaceId,
    );
  }

  Future<ToolPermissionResult> checkToolPermission({
    required String conversationId,
    required String workspaceId,
    required String toolId,
  }) async {
    final workspaceTool = await _workspaceToolsRepository.getWorkspaceTool(
      workspaceId,
      toolId,
    );

    if (workspaceTool == null || !workspaceTool.isEnabled) {
      return ToolPermissionResult.notConfigured;
    }

    return await _conversationToolPermission(
      conversationId: conversationId,
      workspaceTool: workspaceTool,
    );
  }
}

extension on ConversationToolsRepository {
  Future<ToolPermissionResult> _conversationToolPermission({
    required String conversationId,
    required WorkspaceToolEntity workspaceTool,
  }) async {
    final conversation = await _database.conversationDao.getConversationById(
      conversationId,
    );

    return await _conversationPermissionResult(
      conversationId: conversationId,
      conversation: conversation,
      workspaceTool: workspaceTool,
    );
  }

  Future<ToolPermissionResult> _conversationPermissionResult({
    required String conversationId,
    required ConversationsTable? conversation,
    required WorkspaceToolEntity workspaceTool,
  }) {
    final parentConversationId = conversation?.parentConversationId;
    if (parentConversationId != null) {
      return _childConversationToolPermissionResult(
        conversationId: conversationId,
        parentConversationId: parentConversationId,
        workspaceTool: workspaceTool,
      );
    }

    return _rootConversationToolPermissionResult(
      conversationId: conversationId,
      permissionConversationId: conversationId,
      workspaceTool: workspaceTool,
    );
  }
}

extension on ConversationToolsRepository {
  Future<List<ConversationToolEntity>> _buildEnabledConversationTools(
    String conversationId,
    String workspaceId,
  ) async {
    final availableToolTypes = await getAvailableToolsForConversation(
      conversationId,
      workspaceId,
    );

    return availableToolTypes
        .map((toolId) => _enabledConversationTool(conversationId, toolId))
        .toList();
  }

  ConversationToolEntity _enabledConversationTool(
    String conversationId,
    String toolId,
  ) => ConversationToolEntity(
    conversationId: conversationId,
    toolId: toolId,
    isEnabled: true,
    permissionMode: .alwaysAsk,
    createdAt: .now(),
    updatedAt: .now(),
  );

  Future<int> _availableToolCount(
    String conversationId,
    String workspaceId,
  ) async {
    final availableTools = await getAvailableToolsForConversation(
      conversationId,
      workspaceId,
    );

    return availableTools.length;
  }

  Future<bool> _isAvailableWorkspaceTool({
    required String conversationId,
    required String workspaceId,
    required String toolId,
  }) async {
    final workspaceEnabled = await _workspaceToolsRepository
        .isWorkspaceToolEnabled(workspaceId, toolId);
    if (!workspaceEnabled) return false;

    final permission = await checkToolPermission(
      conversationId: conversationId,
      workspaceId: workspaceId,
      toolId: toolId,
    );

    return _isPermissionAvailable(permission);
  }

  Future<List<WorkspaceToolEntity>> _getAvailableWorkspaceToolsForConversation(
    String conversationId,
    String workspaceId,
  ) async {
    // Get workspace enabled tools (full entities with table IDs).
    final workspaceEnabledTools = await _workspaceToolsRepository
        .getEnabledWorkspaceTools(workspaceId);

    // Get conversation disabled tools.
    final disabledWorkspaceToolIds = await _disabledWorkspaceToolIds(
      conversationId,
    );

    return await _filterAvailableWorkspaceTools((
      conversationId: conversationId,
      workspaceId: workspaceId,
      workspaceEnabledTools: workspaceEnabledTools,
      disabledWorkspaceToolIds: disabledWorkspaceToolIds,
    ));
  }

  Future<Set<String>> _disabledWorkspaceToolIds(String conversationId) async {
    final conversationTools = await _dao.getDisabledConversationTools(
      await _conversationPermissionConversationId(conversationId),
    );

    return conversationTools
        .where((tool) => !tool.isEnabled)
        .map((tool) => tool.toolId)
        .toSet();
  }

  Future<List<WorkspaceToolEntity>> _filterAvailableWorkspaceTools(
    _AvailableWorkspaceToolsInput input,
  ) async {
    final permissionEntries = await _checkWorkspaceToolsAvailability(
      conversationId: input.conversationId,
      workspaceId: input.workspaceId,
      candidateTools: input.workspaceEnabledTools.where(
        (tool) => !input.disabledWorkspaceToolIds.contains(tool.id),
      ),
    );

    return _availableWorkspaceTools(permissionEntries);
  }

  Future<List<({WorkspaceToolEntity tool, bool isAvailable})>>
  _checkWorkspaceToolsAvailability({
    required String conversationId,
    required String workspaceId,
    required Iterable<WorkspaceToolEntity> candidateTools,
  }) => Future.wait(
    candidateTools.map(
      (tool) => _checkWorkspaceToolAvailability(
        conversationId: conversationId,
        workspaceId: workspaceId,
        tool: tool,
      ),
    ),
  );

  List<WorkspaceToolEntity> _availableWorkspaceTools(
    List<({WorkspaceToolEntity tool, bool isAvailable})> permissionEntries,
  ) => permissionEntries
      .where((entry) => entry.isAvailable)
      .map((entry) => entry.tool)
      .toList();

  Future<({WorkspaceToolEntity tool, bool isAvailable})>
  _checkWorkspaceToolAvailability({
    required String conversationId,
    required String workspaceId,
    required WorkspaceToolEntity tool,
  }) async {
    final permission = await checkToolPermission(
      conversationId: conversationId,
      workspaceId: workspaceId,
      toolId: tool.toolId,
    );
    final isAvailable = _isPermissionAvailable(permission);

    return (tool: tool, isAvailable: isAvailable);
  }
}

extension on ConversationToolsRepository {
  Future<ToolPermissionResult> _rootConversationToolPermissionResult({
    required String conversationId,
    required String permissionConversationId,
    required WorkspaceToolEntity workspaceTool,
  }) async {
    final conversationTool = await getConversationTool(
      permissionConversationId,
      workspaceTool.id,
    );
    if (conversationTool != null) {
      return _conversationToolPermissionResult(conversationTool);
    }

    return await _rootPermissionFallback(
      conversationId: conversationId,
      workspaceTool: workspaceTool,
    );
  }

  Future<ToolPermissionResult> _rootPermissionFallback({
    required String conversationId,
    required WorkspaceToolEntity workspaceTool,
  }) async {
    final agentResult = await _agentToolPermissionResult(
      conversationId: conversationId,
      toolId: workspaceTool.id,
    );
    if (agentResult != null) return agentResult;

    return _permissionModeResult(
      workspaceTool.permissionMode,
      denyResult: .disabledInWorkspace,
    );
  }

  bool _isPermissionAvailable(ToolPermissionResult permission) {
    return switch (permission) {
      ToolPermissionResult.granted ||
      ToolPermissionResult.needsConfirmation => true,
      ToolPermissionResult.notConfigured ||
      ToolPermissionResult.disabledInWorkspace ||
      ToolPermissionResult.disabledInConversation ||
      ToolPermissionResult.disabledByAgent => false,
    };
  }

  ConversationToolEntity _tableToEntity(ConversationToolsTable table) {
    return ConversationToolEntity(
      conversationId: table.conversationId,
      toolId: table.toolId,
      isEnabled: table.isEnabled,
      permissionMode: _mapPermissionAccess(table.permissions),
      createdAt: table.createdAt,
      updatedAt: table.updatedAt,
    );
  }

  ToolPermissionMode _mapPermissionAccess(PermissionAccess access) {
    return switch (access) {
      .ask => ToolPermissionMode.alwaysAsk,
      .granted => ToolPermissionMode.alwaysAllow,
      .denied => ToolPermissionMode.alwaysDeny,
    };
  }

  PermissionAccess _mapPermissionMode(ToolPermissionMode mode) {
    return switch (mode) {
      .alwaysAsk => PermissionAccess.ask,
      .alwaysAllow => PermissionAccess.granted,
      .alwaysDeny => PermissionAccess.denied,
    };
  }

  Future<ToolPermissionResult> _childConversationToolPermissionResult({
    required String conversationId,
    required String parentConversationId,
    required WorkspaceToolEntity workspaceTool,
  }) async {
    final precedence = await _childPermissionPrecedence(
      conversationId: conversationId,
      parentConversationId: parentConversationId,
      toolId: workspaceTool.id,
    );

    return await _childPermissionResult(
      conversationId: conversationId,
      precedence: precedence,
      workspaceTool: workspaceTool,
    );
  }

  Future<ToolPermissionResult> _childPermissionResult({
    required String conversationId,
    required _ChildPermissionPrecedence precedence,
    required WorkspaceToolEntity workspaceTool,
  }) async {
    final override = _childPermissionOverride(precedence);
    if (override != null) return override;

    final childResult = await _conversationToolResult(
      conversationId: conversationId,
      toolId: workspaceTool.id,
    );

    return _childConversationPermissionFallback((
      childResult: childResult,
      agentResult: precedence.agentResult,
      parentResult: precedence.parentResult,
      workspaceTool: workspaceTool,
    ));
  }

  ToolPermissionResult? _childPermissionOverride(
    _ChildPermissionPrecedence precedence,
  ) {
    if (precedence.agentResult == ToolPermissionResult.disabledByAgent) {
      return ToolPermissionResult.disabledByAgent;
    }
    if (precedence.parentResult ==
        ToolPermissionResult.disabledInConversation) {
      return ToolPermissionResult.disabledInConversation;
    }

    return null;
  }

  Future<_ChildPermissionPrecedence> _childPermissionPrecedence({
    required String conversationId,
    required String parentConversationId,
    required String toolId,
  }) async {
    final agentResult = await _agentToolPermissionResult(
      conversationId: conversationId,
      toolId: toolId,
    );
    if (agentResult == ToolPermissionResult.disabledByAgent) {
      return (agentResult: agentResult, parentResult: null);
    }

    final parentResult = await _conversationToolResult(
      conversationId: parentConversationId,
      toolId: toolId,
    );

    return (agentResult: agentResult, parentResult: parentResult);
  }

  ToolPermissionResult _childConversationPermissionFallback(
    _ChildPermissionFallbackInput input,
  ) {
    final childResult = input.childResult;
    if (childResult != null) return childResult;

    final agentResult = input.agentResult;
    if (agentResult != null) return agentResult;

    final parentResult = input.parentResult;
    if (parentResult != null) return parentResult;

    return _permissionModeResult(
      input.workspaceTool.permissionMode,
      denyResult: .disabledInWorkspace,
    );
  }
}

extension on ConversationToolsRepository {
  Future<ToolPermissionResult?> _conversationToolResult({
    required String conversationId,
    required String toolId,
  }) async {
    final conversationTool = await getConversationTool(conversationId, toolId);

    return conversationTool == null
        ? null
        : _conversationToolPermissionResult(conversationTool);
  }

  ToolPermissionResult _conversationToolPermissionResult(
    ConversationToolEntity conversationTool,
  ) {
    if (!conversationTool.isEnabled) {
      return ToolPermissionResult.disabledInConversation;
    }

    return _permissionModeResult(
      conversationTool.permissionMode,
      denyResult: .disabledInConversation,
    );
  }

  Future<ToolPermissionResult?> _agentToolPermissionResult({
    required String conversationId,
    required String toolId,
  }) async {
    final agentTool = await _agentTool(conversationId, toolId);
    if (agentTool == null) {
      return null;
    }

    return _permissionModeResult(
      _mapPermissionAccess(agentTool.permissions),
      denyResult: .disabledByAgent,
    );
  }

  Future<AgentToolsTable?> _agentTool(
    String conversationId,
    String toolId,
  ) async {
    final agentId = await _conversationAgentId(conversationId);
    if (agentId == null) return null;

    return await _database.agentToolsDao.getAgentTool(agentId, toolId);
  }

  Future<String?> _conversationAgentId(String conversationId) async {
    final conversation = await _database.conversationDao.getConversationById(
      conversationId,
    );

    return conversation?.agentId;
  }

  Future<String> _conversationPermissionConversationId(
    String conversationId,
  ) async {
    final conversation = await _database.conversationDao.getConversationById(
      conversationId,
    );

    return conversation?.parentConversationId ?? conversationId;
  }

  ToolPermissionResult _permissionModeResult(
    ToolPermissionMode mode, {
    required ToolPermissionResult denyResult,
  }) {
    return switch (mode) {
      .alwaysDeny => denyResult,
      .alwaysAsk => ToolPermissionResult.needsConfirmation,
      .alwaysAllow => ToolPermissionResult.granted,
    };
  }
}

/// Base exception for conversation tools-related operations.
class ConversationToolsException implements Exception {
  /// Creates a new ConversationToolsException.
  const new(this.message, {this.localizationKey, this.cause});

  /// Error message describing the exception.
  final String message;

  /// Optional localization key for user-facing errors.
  final String? localizationKey;

  /// Optional original exception that caused this exception.
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: ${cause.runtimeType})' : '';

    return 'ConversationToolsException: $message$causedBy';
  }
}

/// Exception thrown when conversation tool validation fails.
class ConversationToolsValidationException extends ConversationToolsException {
  /// Creates a new ConversationToolsValidationException.
  // Null localization keys are valid for non-localized validation failures.
  // ignore: unnecessary-nullable
  const new(super.message, {super.localizationKey, super.cause});

  @override
  String toString() => StringBuffer(super.toString()).toString();
}
