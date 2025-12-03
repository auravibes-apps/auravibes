import 'package:auravibes_app/data/repositories/workspace_tools_repository_impl.dart';
import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/features/workspaces/providers/selected_workspace.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_tools_provider.g.dart';

typedef WorkspaceTool = (UserToolType, WorkspaceToolEntity?);

@riverpod
WorkspaceToolsRepository workspaceToolsRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);
  return WorkspaceToolsRepositoryImpl(appDatabase);
}

@Riverpod(dependencies: [])
int workspaceToolIndexNotifier(Ref ref) =>
    throw Exception('implement workspaceToolIndexNotifier');

@riverpod
class WorkspaceToolsNotifier extends _$WorkspaceToolsNotifier {
  late WorkspaceToolsRepository _repository;
  late String _workspaceId;

  @override
  Future<List<WorkspaceTool>> build() async {
    _repository = ref.watch(workspaceToolsRepositoryProvider);
    _workspaceId = await ref.watch(
      selectedWorkspaceProvider.selectAsync((w) => w.id),
    );

    final workspaceTools = await _repository.getWorkspaceTools(_workspaceId);

    // Only return tools that have been explicitly added to the workspace
    return workspaceTools
        .map((wt) {
          final toolType = UserToolType.fromValue(wt.toolId);
          return toolType != null ? (toolType, wt) : null;
        })
        .whereType<WorkspaceTool>()
        .toList();
  }

  /// Add a new tool to the workspace
  Future<void> addTool(UserToolType toolType) async {
    await _repository.setWorkspaceToolEnabled(
      _workspaceId,
      toolType.value,
      isEnabled: true,
    );
    ref.invalidateSelf();
  }

  void _replaceTools(List<WorkspaceToolEntity> workspaceTools) {
    if (state case AsyncData(:final value)) {
      state = AsyncData(
        value.map((wt) {
          final workspaceTool = workspaceTools.firstWhereOrNull(
            (element) => element.toolId == wt.$1.value,
          );
          if (workspaceTool != null) {
            return (wt.$1, workspaceTool);
          }
          return wt;
        }).toList(),
      );
    }
  }

  void _removeTools(List<UserToolType> toolTypes) {
    if (state case AsyncData(:final value)) {
      state = AsyncData(
        value.where((wt) => !toolTypes.contains(wt.$1)).toList(),
      );
    }
  }

  /// Enable or disable a workspace tool
  Future<void> setToolEnabled(
    String toolType, {
    required bool isEnabled,
  }) async {
    final newTool = await _repository.setWorkspaceToolEnabled(
      _workspaceId,
      toolType,
      isEnabled: isEnabled,
    );
    _replaceTools([newTool]);
    return;
  }

  /// Update workspace tool configuration
  Future<void> updateToolConfig(String toolType, String? config) async {
    final success = await _repository.updateWorkspaceToolConfig(
      _workspaceId,
      toolType,
      config,
    );
    _replaceTools(success);
  }

  /// Remove a workspace tool by its database ID
  Future<bool> removeToolById(String id, UserToolType toolType) async {
    final success = await _repository.removeWorkspaceToolById(id);
    if (success) {
      _removeTools([toolType]);
    }
    return success;
  }

  /// Set the permission mode for a workspace tool
  Future<void> setToolPermissionMode(
    String id, {
    required ToolPermissionMode permissionMode,
  }) async {
    final newTool = await _repository.setToolPermissionMode(
      id,
      permissionMode: permissionMode,
    );
    _replaceTools([newTool]);
  }
}

/// Provider that returns the list of available tools
/// that can be added to the workspace
@riverpod
Future<List<UserToolType>> availableToolsToAdd(Ref ref) async {
  final workspaceTools = await ref.watch(workspaceToolsProvider.future);
  final addedToolTypes = workspaceTools.map((wt) => wt.$1).toSet();

  return ToolService.getTypes()
      .where((UserToolType type) => !addedToolTypes.contains(type))
      .toList();
}

@Riverpod(dependencies: [workspaceToolIndexNotifier])
WorkspaceTool? workspaceToolRow(Ref ref) {
  final workspaceToolIndex = ref.watch(workspaceToolIndexProvider);
  return ref.watch(
    workspaceToolsProvider.select((e) => e.value?[workspaceToolIndex]),
  );
}
