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

@Riverpod(keepAlive: true)
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
  Future<List<WorkspaceToolEntity>> build() async {
    _repository = ref.watch(workspaceToolsRepositoryProvider);
    _workspaceId = await ref.watch(
      selectedWorkspaceProvider.selectAsync((w) => w.id),
    );

    final workspaceTools = await _repository.getWorkspaceTools(_workspaceId);

    // Return all tools (both built-in and MCP)
    return workspaceTools;
  }

  /// Add a new built-in tool to the workspace
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
            (element) => element.id == wt.id,
          );
          return workspaceTool ?? wt;
        }).toList(),
      );
    }
  }

  void _removeToolsByIds(List<String> toolIds) {
    if (state case AsyncData(:final value)) {
      state = AsyncData(
        value.where((wt) => !toolIds.contains(wt.id)).toList(),
      );
    }
  }

  /// Enable or disable a workspace tool by its database ID
  Future<void> setToolEnabled(
    String id, {
    required bool isEnabled,
  }) async {
    final newTool = await _repository.setToolEnabledById(
      id,
      isEnabled: isEnabled,
    );
    _replaceTools([newTool]);
  }

  /// Update workspace tool configuration
  Future<void> updateToolConfig(String toolId, String? config) async {
    final success = await _repository.updateWorkspaceToolConfig(
      _workspaceId,
      toolId,
      config,
    );
    _replaceTools(success);
  }

  /// Remove a workspace tool by its database ID
  Future<bool> removeToolById(String id) async {
    final success = await _repository.removeWorkspaceToolById(id);
    if (success) {
      _removeToolsByIds([id]);
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

/// Provider that returns the list of available built-in tools
/// that can be added to the workspace
@riverpod
Future<List<UserToolType>> availableToolsToAdd(Ref ref) async {
  final workspaceTools = await ref.watch(workspaceToolsProvider.future);

  // Get IDs of tools already added
  final addedToolIds = workspaceTools.map((wt) => wt.id).toSet();

  // Return built-in tools that haven't been added yet
  return ToolService.getTypes()
      .where((type) => !addedToolIds.contains(type.value))
      .toList();
}

@Riverpod(dependencies: [workspaceToolIndexNotifier])
WorkspaceToolEntity? workspaceToolRow(Ref ref) {
  final workspaceToolIndex = ref.watch(workspaceToolIndexProvider);
  return ref.watch(
    workspaceToolsProvider.select((e) => e.value?[workspaceToolIndex]),
  );
}
