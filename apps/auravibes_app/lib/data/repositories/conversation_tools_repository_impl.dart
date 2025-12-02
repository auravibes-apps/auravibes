import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/conversation_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/conversation_tool.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/repositories/conversation_tools_repository.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';

/// Implementation of the ConversationToolsRepository
class ConversationToolsRepositoryImpl implements ConversationToolsRepository {
  ConversationToolsRepositoryImpl(
    this._database,
    this._workspaceToolsRepository,
  ) {
    _dao = _database.conversationToolsDao;
  }
  final AppDatabase _database;
  final WorkspaceToolsRepository _workspaceToolsRepository;
  late ConversationToolsDao _dao;

  @override
  Future<List<ConversationToolEntity>> getConversationTools(
    String conversationId,
  ) async {
    final results = await _dao.getConversationTools(conversationId);
    return results.map(_tableToEntity).toList();
  }

  @override
  Future<List<ConversationToolEntity>> getEnabledConversationTools(
    String conversationId,
  ) async {
    // Get available tools for the conversation by computing:
    // Available tools = Workspace enabled tools - Conversation disabled tools
    final availableToolTypes = await getAvailableToolsForConversation(
      conversationId,
      '', // workspaceId will be retrieved from conversation
    );

    return availableToolTypes
        .map(
          (toolId) => ConversationToolEntity(
            conversationId: conversationId,
            toolId: toolId,
            isEnabled: true, // These are computed enabled tools
            permissionMode: ToolPermissionMode.alwaysAsk,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        )
        .toList();
  }

  @override
  Future<ConversationToolEntity?> getConversationTool(
    String conversationId,
    String toolType,
  ) async {
    final result = await _dao.getConversationTool(
      conversationId,
      toolType,
    );
    if (result == null) return null;

    return _tableToEntity(result);
  }

  @override
  Future<bool> setConversationToolEnabled(
    String conversationId,
    String toolType, {
    required bool isEnabled,
  }) async {
    try {
      await _dao.setConversationToolEnabled(
        conversationId,
        toolType,
        isEnabled: isEnabled,
      );
      return true;
    } catch (e) {
      throw ConversationToolsException(
        'Failed to set conversation tool enabled: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<void> setConversationToolsDisabled(
    String conversationId,
    List<String> toolTypes,
  ) {
    return _dao.disableConversationTools(conversationId, toolTypes);
  }

  @override
  Future<bool> setConversationToolPermission(
    String conversationId,
    String toolType, {
    required ToolPermissionMode permissionMode,
  }) async {
    try {
      await _dao.setConversationToolPermission(
        conversationId,
        toolType,
        permission: _mapPermissionMode(permissionMode),
      );
      return true;
    } catch (e) {
      throw ConversationToolsException(
        'Failed to set conversation tool permission: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<bool> toggleConversationTool(
    String conversationId,
    String toolType,
  ) async {
    try {
      return await _dao.toggleConversationTool(conversationId, toolType);
    } catch (e) {
      throw ConversationToolsException(
        'Failed to toggle conversation tool: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<bool> isConversationToolEnabled(
    String conversationId,
    String toolType,
  ) async {
    try {
      return await _dao.isConversationToolEnabled(
        conversationId,
        toolType,
      );
    } catch (e) {
      throw ConversationToolsException(
        'Failed to check conversation tool status: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<bool> removeConversationTool(
    String conversationId,
    String toolType,
  ) async {
    try {
      return await _dao.deleteConversationTool(conversationId, toolType);
    } catch (e) {
      throw ConversationToolsException(
        'Failed to remove conversation tool: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<int> getConversationToolsCount(String conversationId) async {
    try {
      return await _dao.getConversationToolsCount(conversationId);
    } catch (e) {
      throw ConversationToolsException(
        'Failed to count conversation tools: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<int> getEnabledConversationToolsCount(String conversationId) async {
    try {
      // This is computed as available tools - disabled tools
      final availableCount = await getAvailableToolsForConversation(
        conversationId,
        '',
      );
      return availableCount.length;
    } catch (e) {
      throw ConversationToolsException(
        'Failed to count enabled conversation tools: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<void> copyConversationTools(
    String sourceConversationId,
    String targetConversationId,
  ) async {
    try {
      await _dao.copyConversationTools(
        sourceConversationId,
        targetConversationId,
      );
    } catch (e) {
      throw ConversationToolsException(
        'Failed to copy conversation tools: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<bool> validateConversationToolSetting(
    String conversationId,
    String toolType, {
    required bool isEnabled,
  }) async {
    try {
      // Check if conversation exists
      final conversation = await _database.conversationDao.getConversationById(
        conversationId,
      );
      if (conversation == null) {
        throw ConversationToolsValidationException(
          'Conversation not found: $conversationId',
        );
      }

      // Check if tool type is valid
      if (!ToolService.hasTypeString(toolType)) {
        throw ConversationToolsValidationException(
          'Invalid tool type: $toolType',
        );
      }

      return true;
    } catch (e) {
      if (e is ConversationToolsValidationException) rethrow;
      throw ConversationToolsException(
        'Failed to validate conversation tool setting: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<bool> isToolAvailableForConversation(
    String conversationId,
    String workspaceId,
    String toolType,
  ) async {
    try {
      // Check if workspace has tool enabled
      final workspaceEnabled = await _workspaceToolsRepository
          .isWorkspaceToolEnabled(workspaceId, toolType);

      // Check if conversation has disabled override for this tool
      final conversationDisabled = await _dao.isConversationToolDisabled(
        conversationId,
        toolType,
      );

      // Tool is available if workspace enabled AND not conversation disabled
      return workspaceEnabled && !conversationDisabled;
    } catch (e) {
      throw ConversationToolsException(
        'Failed to check tool availability for conversation: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<List<String>> getAvailableToolsForConversation(
    String conversationId,
    String workspaceId,
  ) async {
    try {
      // Get workspace enabled tools
      final workspaceEnabledTools = await _workspaceToolsRepository
          .getEnabledWorkspaceTools(workspaceId);

      // Get conversation disabled tools
      final conversationTools = await _dao.getDisabledConversationTools(
        conversationId,
      );

      // Extract tool types from workspace enabled tools
      final workspaceEnabledToolTypes = workspaceEnabledTools
          .map((tool) => tool.toolId)
          .toList();

      // Extract tool types from disabled tools
      final disabledToolTypes = conversationTools
          .where((tool) => !tool.isEnabled)
          .map((tool) => tool.toolId)
          .toSet();

      // Available tools = workspace enabled tools - disabled tools
      final availableTools = workspaceEnabledToolTypes
          .where((toolType) => !disabledToolTypes.contains(toolType))
          .toList();

      return availableTools;
    } catch (e) {
      throw ConversationToolsException(
        'Failed to get available tools for conversation: $e',
        e is Exception ? e : null,
      );
    }
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
}
