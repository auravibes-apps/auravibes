// Required: Existing argument values intentionally repeat.
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/conversation_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/domain/entities/conversation_tool_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/enums/tool_permission_result.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';

/// Implementation of the ConversationToolsRepository.
class ConversationToolsRepository {
  ConversationToolsRepository(
    this._database,
    this._workspaceToolsRepository,
  ) : _dao = _database.conversationToolsDao;
  final AppDatabase _database;
  final WorkspaceToolsRepository _workspaceToolsRepository;
  final ConversationToolsDao _dao;

  Future<List<ConversationToolEntity>> getConversationTools(
    String conversationId,
  ) async {
    final results = await _dao.getConversationTools(conversationId);

    return results.map(_tableToEntity).toList();
  }

  Future<List<ConversationToolEntity>> getEnabledConversationTools(
    String conversationId,
  ) async {
    // Get available tools for the conversation by computing:.
    // Available tools = Workspace enabled tools - Conversation disabled tools.
    final availableToolTypes = await getAvailableToolsForConversation(
      conversationId,
      '', // WorkspaceId will be retrieved from conversation.
    );

    return availableToolTypes
        .map(
          (toolId) => ConversationToolEntity(
            conversationId: conversationId,
            toolId: toolId,
            isEnabled: true, // These are computed enabled tools.
            permissionMode: ToolPermissionMode.alwaysAsk,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        )
        .toList();
  }

  Future<ConversationToolEntity?> getConversationTool(
    String conversationId,
    String toolId,
  ) async {
    final result = await _dao.getConversationTool(
      conversationId,
      toolId,
    );
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

  Future<bool> toggleConversationTool(
    String conversationId,
    String toolId,
  ) async {
    return _dao.toggleConversationTool(conversationId, toolId);
  }

  Future<bool> isConversationToolEnabled(
    String conversationId,
    String toolId,
  ) async {
    return _dao.isConversationToolEnabled(
      conversationId,
      toolId,
    );
  }

  Future<bool> removeConversationTool(
    String conversationId,
    String toolId,
  ) async {
    return _dao.deleteConversationTool(conversationId, toolId);
  }

  Future<int> getConversationToolsCount(String conversationId) async {
    return _dao.getConversationToolsCount(conversationId);
  }

  Future<int> getEnabledConversationToolsCount(String conversationId) async {
    final conversation = await _database.conversationDao.getConversationById(
      conversationId,
    );
    if (conversation == null) {
      return 0;
    }

    // This is computed as available tools - disabled tools.
    final availableCount = await getAvailableToolsForConversation(
      conversationId,
      conversation.workspaceId,
    );

    return availableCount.length;
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
    String toolId, {
    required bool isEnabled,
  }) async {
    // Check if conversation exists.
    final conversation = await _database.conversationDao.getConversationById(
      conversationId,
    );
    if (conversation == null) {
      throw ConversationToolsValidationException(
        'Conversation not found: $conversationId',
      );
    }

    // Check if tool type is valid.
    if (!ToolService.hasTypeString(toolId)) {
      throw ConversationToolsValidationException(
        'Invalid tool type: $toolId',
      );
    }

    return true;
  }

  Future<bool> isToolAvailableForConversation(
    String conversationId,
    String workspaceId,
    String toolId,
  ) async {
    // Check if workspace has tool enabled.
    final workspaceEnabled = await _workspaceToolsRepository
        .isWorkspaceToolEnabled(workspaceId, toolId);

    // Check if conversation has disabled override for this tool.
    final conversationDisabled = await _dao.isConversationToolDisabled(
      conversationId,
      toolId,
    );

    // Tool is available if workspace enabled AND not conversation disabled.
    return workspaceEnabled && !conversationDisabled;
  }

  Future<List<String>> getAvailableToolsForConversation(
    String conversationId,
    String workspaceId,
  ) async {
    // Get workspace enabled tools.
    final workspaceEnabledTools = await _workspaceToolsRepository
        .getEnabledWorkspaceTools(workspaceId);

    // Get conversation disabled tools.
    final conversationTools = await _dao.getDisabledConversationTools(
      conversationId,
    );

    // Extract workspace tool row ids from disabled tools.
    final disabledWorkspaceToolIds = conversationTools
        .where((tool) => !tool.isEnabled)
        .map((tool) => tool.toolId)
        .toSet();

    // Available tools = workspace enabled tools - disabled tools.
    return workspaceEnabledTools
        .where((tool) => !disabledWorkspaceToolIds.contains(tool.id))
        .map((tool) => tool.toolId)
        .toList();
  }

  Future<List<WorkspaceToolEntity>> getAvailableToolEntitiesForConversation(
    String conversationId,
    String workspaceId,
  ) async {
    // Get workspace enabled tools (full entities with table IDs).
    final workspaceEnabledTools = await _workspaceToolsRepository
        .getEnabledWorkspaceTools(workspaceId);

    // Get conversation disabled tools.
    final conversationTools = await _dao.getDisabledConversationTools(
      conversationId,
    );

    // Extract workspace tool row ids from disabled tools.
    final disabledWorkspaceToolIds = conversationTools
        .where((tool) => !tool.isEnabled)
        .map((tool) => tool.toolId)
        .toSet();

    // Available tools = workspace enabled tools - disabled tools.
    return workspaceEnabledTools
        .where((tool) => !disabledWorkspaceToolIds.contains(tool.id))
        .toList();
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
      PermissionAccess.ask => ToolPermissionMode.alwaysAsk,
      PermissionAccess.granted => ToolPermissionMode.alwaysAllow,
    };
  }

  PermissionAccess _mapPermissionMode(ToolPermissionMode mode) {
    return switch (mode) {
      ToolPermissionMode.alwaysAsk => PermissionAccess.ask,
      ToolPermissionMode.alwaysAllow => PermissionAccess.granted,
    };
  }

  Future<ToolPermissionResult> checkToolPermission({
    required String conversationId,
    required String workspaceId,
    required String toolId,
  }) async {
    // 1. Check workspace - tool must exist and be enabled.
    final workspaceTool = await _workspaceToolsRepository.getWorkspaceTool(
      workspaceId,
      toolId,
    );

    // Tool not in workspace or disabled = cannot run.
    if (workspaceTool == null || !workspaceTool.isEnabled) {
      return ToolPermissionResult.notConfigured;
    }

    // 2. Check conversation override (takes priority).
    final conversationTool = await getConversationTool(
      conversationId,
      workspaceTool.id,
    );

    if (conversationTool != null) {
      // Conversation rule exists - it takes priority.
      if (!conversationTool.isEnabled) {
        return ToolPermissionResult.disabledInConversation;
      }

      if (conversationTool.permissionMode == ToolPermissionMode.alwaysAsk) {
        return ToolPermissionResult.needsConfirmation;
      }

      // Conversation says granted (alwaysAllow).
      return ToolPermissionResult.granted;
    }

    // 3. No conversation override - use workspace permission.
    if (workspaceTool.permissionMode == ToolPermissionMode.alwaysAsk) {
      return ToolPermissionResult.needsConfirmation;
    }

    return ToolPermissionResult.granted;
  }
}

/// Base exception for conversation tools-related operations.
class ConversationToolsException implements Exception {
  /// Creates a new ConversationToolsException.
  const ConversationToolsException(this.message, [this.cause]);

  /// Error message describing the exception.
  final String message;

  /// Optional original exception that caused this exception.
  final Exception? cause;

  @override
  String toString() {
    final causedBy = cause != null ? ' (Caused by: $cause)' : '';

    return 'ConversationToolsException: $message$causedBy';
  }
}

/// Exception thrown when conversation tool validation fails.
class ConversationToolsValidationException extends ConversationToolsException {
  /// Creates a new ConversationToolsValidationException.
  const ConversationToolsValidationException(super.message, [super.cause]);
}
