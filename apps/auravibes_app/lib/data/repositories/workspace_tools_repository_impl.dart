import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/database/drift/daos/workspace_tools_dao.dart';
import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/services/tools/native_tool_service.dart';
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
    await _ensureNativeTools(workspaceId);
    final results = await _dao.getWorkspaceTools(workspaceId);
    return results.map(_tableToEntity).toList();
  }

  @override
  Future<List<WorkspaceToolEntity>> getEnabledWorkspaceTools(
    String workspaceId,
  ) async {
    await _ensureNativeTools(workspaceId);
    final results = await _dao.getEnabledWorkspaceTools(workspaceId);
    return results.map(_tableToEntity).toList();
  }

  @override
  Future<WorkspaceToolEntity?> getWorkspaceTool(
    String workspaceId,
    String toolId,
  ) async {
    await _ensureNativeTools(workspaceId);
    final result = await _dao.getWorkspaceToolByToolId(workspaceId, toolId);
    if (result == null) return null;

    return _tableToEntity(result);
  }

  Future<void> _ensureNativeTools(String workspaceId) async {
    await _database.transaction(() async {
      final workspaceTools = await _dao.getWorkspaceTools(workspaceId);
      final existingNativeToolIds = workspaceTools
          .where((tool) => tool.workspaceToolsGroupId == null)
          .where((tool) => NativeToolService.hasTypeString(tool.toolId))
          .map((tool) => tool.toolId)
          .toSet();

      for (final nativeType in NativeToolService.getTypes()) {
        if (existingNativeToolIds.contains(nativeType.value)) {
          continue;
        }

        await _dao.setWorkspaceToolEnabled(
          workspaceId,
          nativeType.value,
          isEnabled: true,
        );
      }
    });
  }

  @override
  Future<WorkspaceToolEntity> setWorkspaceToolEnabled(
    String workspaceId,
    String toolType, {
    required bool isEnabled,
  }) async {
    return _dao
        .setWorkspaceToolEnabled(workspaceId, toolType, isEnabled: isEnabled)
        .then(_tableToEntity);
  }

  @override
  Future<WorkspaceToolEntity> setToolEnabledById(
    String id, {
    required bool isEnabled,
  }) async {
    return _dao
        .setWorkspaceToolEnabledById(id, isEnabled: isEnabled)
        .then(_tableToEntity);
  }

  @override
  Future<bool> isWorkspaceToolEnabled(
    String workspaceId,
    String toolType,
  ) async {
    return _dao.isWorkspaceToolEnabledByToolId(workspaceId, toolType);
  }

  @override
  Future<bool> removeWorkspaceTool(String workspaceId, String toolType) async {
    if (NativeToolService.hasTypeString(toolType)) {
      throw WorkspaceToolsValidationException(
        'Native tools cannot be removed: $toolType',
      );
    }
    return _dao.deleteWorkspaceToolByToolId(workspaceId, toolType);
  }

  @override
  Future<bool> removeWorkspaceToolById(String id) async {
    return _dao.deleteWorkspaceToolById(id);
  }

  @override
  Future<int> getWorkspaceToolsCount(String workspaceId) async {
    return _dao.getWorkspaceToolsCount(workspaceId);
  }

  @override
  Future<int> getEnabledWorkspaceToolsCount(String workspaceId) async {
    return _dao.getEnabledWorkspaceToolsCount(workspaceId);
  }

  @override
  Future<void> copyWorkspaceToolsToConversation(
    String workspaceId,
    String conversationId,
  ) async {
    // This method is no longer needed since we use disabled tools approach.
    // Copying workspace tools to conversation is handled by the conversation
    // tools repository.
  }

  @override
  Future<bool> validateWorkspaceToolSetting(
    String workspaceId,
    String toolType, {
    required bool isEnabled,
    String? config,
  }) async {
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
    if (!ToolService.hasTypeString(toolType) &&
        !NativeToolService.hasTypeString(toolType)) {
      throw WorkspaceToolsValidationException('Invalid tool type: $toolType');
    }

    // Config string is currently optional and not parsed.
    return true;
  }

  @override
  Future<String?> getWorkspaceToolConfig(
    String workspaceId,
    String toolType,
  ) async {
    return _dao.getWorkspaceToolConfigByToolId(workspaceId, toolType);
  }

  @override
  Future<List<WorkspaceToolEntity>> patchWorkspaceToolConfig(
    String workspaceId,
    String toolType,
    String? config,
  ) async {
    try {
      return await _dao
          .patchWorkspaceToolConfig(workspaceId, toolType, config)
          .then((value) => value.map(_tableToEntity).toList());
    } catch (e) {
      throw WorkspaceToolsException(
        'Failed to patch workspace tool config: $e',
        e is Exception ? e : null,
      );
    }
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
    return _dao
        .setWorkspaceToolPermission(
          id,
          permission: _mapPermissionMode(permissionMode),
        )
        .then(_tableToEntity);
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
