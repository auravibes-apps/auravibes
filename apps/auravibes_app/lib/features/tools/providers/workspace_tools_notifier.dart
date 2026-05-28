// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/workspace_tools_repository_impl.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/domain/repositories/workspace_tools_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/tools/tool_service.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_tools_notifier.g.dart';

@Riverpod(keepAlive: true)
WorkspaceToolsRepository workspaceToolsRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);
  return WorkspaceToolsRepositoryImpl(appDatabase);
}

@Riverpod(dependencies: [])
int workspaceToolIndexNotifier(Ref _) =>
    throw Exception('implement workspaceToolIndexNotifier');

@riverpod
class WorkspaceToolsNotifier extends _$WorkspaceToolsNotifier {
  WorkspaceToolsRepository? _repository;
  String _workspaceId = '';

  WorkspaceToolsRepository get _requiredRepository {
    final repository = _repository;
    if (repository == null) {
      throw StateError('_repository is not initialized');
    }

    return repository;
  }

  @override
  Future<List<WorkspaceToolEntity>> build(String workspaceId) async {
    final repository = ref.watch(workspaceToolsRepositoryProvider);
    _repository = repository;
    _workspaceId = workspaceId;
    return repository.getWorkspaceTools(workspaceId);
  }

  /// Add a new built-in tool to the workspace
  Future<void> addTool(UserToolType toolType) async {
    final _ = await _requiredRepository.setWorkspaceToolEnabled(
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
    final newTool = await _requiredRepository.setToolEnabledById(
      id,
      isEnabled: isEnabled,
    );
    _replaceTools([newTool]);
  }

  /// Update workspace tool configuration
  Future<void> updateToolConfig(String toolId, String? config) async {
    final success = await _requiredRepository.patchWorkspaceToolConfig(
      _workspaceId,
      toolId,
      config,
    );
    _replaceTools(success);
  }

  /// Remove a workspace tool by its database ID
  Future<bool> removeToolById(String id) async {
    final success = await _requiredRepository.removeWorkspaceToolById(id);
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
    final newTool = await _requiredRepository.setToolPermissionMode(
      id,
      permissionMode: permissionMode,
    );
    _replaceTools([newTool]);
  }
}

/// Provider that returns the list of available built-in tools
/// that can be added to the workspace
@riverpod
Future<List<UserToolType>> availableToolsToAdd(
  Ref ref,
  String workspaceId,
) async {
  final workspaceTools = await ref.watch(
    workspaceToolsProvider(workspaceId).future,
  );

  final addedBuiltInToolIds = workspaceTools
      .map((wt) => wt.buildInType)
      .whereType<UserToolType>()
      .map((type) => type.value)
      .toSet();

  return ToolService.getTypes()
      .where((type) => !addedBuiltInToolIds.contains(type.value))
      .toList();
}

@Riverpod(dependencies: [workspaceToolIndexNotifier])
WorkspaceToolEntity? workspaceToolRow(Ref ref, String workspaceId) {
  final workspaceToolIndex = ref.watch(workspaceToolIndexProvider);
  final workspaceTools = ref.watch(workspaceToolsProvider(workspaceId)).value;
  if (workspaceTools == null ||
      workspaceToolIndex < 0 ||
      workspaceToolIndex >= workspaceTools.length) {
    return null;
  }
  return workspaceTools[workspaceToolIndex];
}
