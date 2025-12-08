import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';

/// Implementation of the WorkspaceToolsRepository
class WorkspaceToolsRepositoryImpl implements WorkspaceToolsRepository {
  WorkspaceToolsRepositoryImpl(this._database) {
    _dao = _database.workspaceToolsDao;
  }
  final AppDatabase _database;
  late WorkspaceToolsDao _dao;

  @override
  Future<List<WorkspaceToolEntity>> getWorkspaceTools(
    String workspaceId,
  ) async {
    final results = await _dao.getWorkspaceTools(workspaceId);
    return results.map(_tableToEntity).toList();
  }

  @override
  Future<List<WorkspaceToolEntity>> getEnabledWorkspaceTools(
    String workspaceId,
  ) async {
    final results = await _dao.getEnabledWorkspaceTools(workspaceId);
    return results.map(_tableToEntity).toList();
  }

  @override
  Future<WorkspaceToolEntity?> getWorkspaceTool(
    String workspaceId,
    String toolId,
  ) async {
    final result = await _dao.getWorkspaceTool(workspaceId, toolId);
    if (result == null) return null;

    return _tableToEntity(result);
  }

  @override
  Future<WorkspaceToolEntity> setWorkspaceToolEnabled(
    String workspaceId,
    String toolType, {
    required bool isEnabled,
  }) async {
    try {
      return await _dao
          .setWorkspaceToolEnabled(workspaceId, toolType, isEnabled: isEnabled)
          .then(_tableToEntity);
    } catch (e) {
      throw WorkspaceToolsException(
        'Failed to set workspace tool enabled: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<WorkspaceToolEntity> setToolEnabledById(
    String id, {
    required bool isEnabled,
  }) async {
    try {
      return await _dao
          .setWorkspaceToolEnabledById(id, isEnabled: isEnabled)
          .then(_tableToEntity);
    } catch (e) {
      throw WorkspaceToolsException(
        'Failed to set workspace tool enabled by ID: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<bool> isWorkspaceToolEnabled(
    String workspaceId,
    String toolType,
  ) async {
    try {
      final result = await _dao.getWorkspaceTool(workspaceId, toolType);

      return result?.isEnabled ?? false;
    } catch (e) {
      throw WorkspaceToolsException(
        'Failed to check workspace tool status: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<bool> removeWorkspaceTool(String workspaceId, String toolType) async {
    try {
      return await _dao.deleteWorkspaceTool(workspaceId, toolType);
    } catch (e) {
      throw WorkspaceToolsException(
        'Failed to remove workspace tool: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<bool> removeWorkspaceToolById(String id) async {
    try {
      return await _dao.deleteWorkspaceToolById(id);
    } catch (e) {
      throw WorkspaceToolsException(
        'Failed to remove workspace tool by ID: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<int> getWorkspaceToolsCount(String workspaceId) async {
    try {
      return await _dao.getWorkspaceToolsCount(workspaceId);
    } catch (e) {
      throw WorkspaceToolsException(
        'Failed to count workspace tools: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<int> getEnabledWorkspaceToolsCount(String workspaceId) async {
    try {
      return await _dao.getEnabledWorkspaceToolsCount(workspaceId);
    } catch (e) {
      throw WorkspaceToolsException(
        'Failed to count enabled workspace tools: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<void> copyWorkspaceToolsToConversation(
    String workspaceId,
    String conversationId,
  ) async {
    try {
      // This method is no longer needed since we use disabled tools approach
      // Copying workspace tools to conversation is handled by the conversation
      // tools repository
    } catch (e) {
      throw WorkspaceToolsException(
        'Failed to copy workspace tools to conversation: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<bool> validateWorkspaceToolSetting(
    String workspaceId,
    String toolType, {
    required bool isEnabled,
    String? config,
  }) async {
    try {
      // Check if workspace exists
      final workspace = await _database.workspaceDao.getWorkspaceById(
        workspaceId,
      );
      if (workspace == null) {
        throw WorkspaceToolsValidationException(
          'Workspace not found: $workspaceId',
        );
      }

      // Check if tool type is valid
      if (!ToolService.hasTypeString(toolType)) {
        throw WorkspaceToolsValidationException('Invalid tool type: $toolType');
      }

      // Validate config if provided
      if (config != null && config.isNotEmpty) {
        try {
          // Basic JSON validation
          // can be extended based on tool type requirements
          // This is a simple check, you might want to add more
          // sophisticated validation
          if (config.trim().startsWith('{') && config.trim().endsWith('}')) {
            // It looks like JSON, could parse it if needed
          }
        } on Exception catch (_) {
          throw WorkspaceToolsValidationException(
            'Invalid config format: $config',
          );
        }
      }

      return true;
    } catch (e) {
      if (e is WorkspaceToolsValidationException) rethrow;
      throw WorkspaceToolsException(
        'Failed to validate workspace tool setting: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<String?> getWorkspaceToolConfig(
    String workspaceId,
    String toolType,
  ) async {
    try {
      final result = await _dao.getWorkspaceTool(workspaceId, toolType);
      return result?.config;
    } catch (e) {
      throw WorkspaceToolsException(
        'Failed to get workspace tool config: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<List<WorkspaceToolEntity>> updateWorkspaceToolConfig(
    String workspaceId,
    String toolType,
    String? config,
  ) async {
    return _dao
        .updateWorkspaceToolConfig(workspaceId, toolType, config)
        .then((value) => value.map(_tableToEntity).toList());
  }

  WorkspaceToolEntity _tableToEntity(ToolsTable table) {
    return WorkspaceToolEntity(
      id: table.id,
      workspaceId: table.workspaceId,
      toolId: table.toolId,
      config: table.config,
      isEnabled: table.isEnabled,
      permissionMode: _mapPermissionAccess(table.permissions),
      createdAt: table.createdAt,
      updatedAt: table.updatedAt,
      description: table.description,
      inputSchema: table.inputSchema,
      workspaceToolsGroupId: table.workspaceToolsGroupId,
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

  @override
  Future<WorkspaceToolEntity> setToolPermissionMode(
    String id, {
    required ToolPermissionMode permissionMode,
  }) async {
    try {
      return await _dao
          .setWorkspaceToolPermission(
            id,
            permission: _mapPermissionMode(permissionMode),
          )
          .then(_tableToEntity);
    } catch (e) {
      throw WorkspaceToolsException(
        'Failed to set workspace tool permission: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<WorkspaceToolEntity?> getWorkspaceToolByToolName({
    required String toolGroupId,
    required String toolName,
  }) {
    return _dao
        .getEnabledToolByToolName(toolGroupId: toolGroupId, toolName: toolName)
        .then((value) {
          if (value == null) return null;
          return _tableToEntity(value);
        });
  }
}
