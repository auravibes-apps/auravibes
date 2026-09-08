import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';

/// Contract for workspace tool persistence.
abstract interface class WorkspaceToolsRepositoryContract {
  Future<List<WorkspaceToolEntity>> getWorkspaceTools(String workspaceId);
  Future<List<WorkspaceToolEntity>> getEnabledWorkspaceTools(
    String workspaceId,
  );
  Future<WorkspaceToolEntity?> getWorkspaceTool(
    String workspaceId,
    String toolId,
  );
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
  Future<WorkspaceToolEntity?> getWorkspaceToolByToolName({
    required String toolGroupId,
    required String toolName,
  });
}
