import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';

/// Contract for workspace tool persistence.
abstract interface class WorkspaceToolsRepositoryContract
    implements
        WorkspaceToolsRepositoryReadContract,
        WorkspaceToolsRepositoryWriteContract;

abstract interface class WorkspaceToolsRepositoryReadContract {
  Future<List<WorkspaceToolEntity>> getWorkspaceTools(String workspaceId);
  Future<List<WorkspaceToolEntity>> getEnabledWorkspaceTools(
    String workspaceId,
  );
  Future<WorkspaceToolEntity?> getWorkspaceTool(
    String workspaceId,
    String toolId,
  );
  Future<WorkspaceToolEntity?> getWorkspaceToolByToolName({
    required String toolGroupId,
    required String toolName,
  });
}

abstract interface class WorkspaceToolsRepositoryWriteContract {
  Future<WorkspaceToolEntity> setWorkspaceToolEnabled(
    String workspaceId,
    String toolType, {
    required bool isEnabled,
  });
  Future<WorkspaceToolEntity> setToolEnabledById(
    String id, {
    required bool isEnabled,
  });
  Future<bool> removeWorkspaceToolById(String id);
  Future<List<WorkspaceToolEntity>> patchWorkspaceToolConfig(
    String workspaceId,
    String toolType,
    String? config,
  );
  Future<WorkspaceToolEntity> setToolPermissionMode(
    String id, {
    required ToolPermissionMode permissionMode,
  });
}
