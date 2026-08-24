import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/repositories/workspace_selection_repository.dart';
import 'package:auravibes_app/features/workspaces/providers/last_workspace_selection_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'workspace_selection.dart';

export 'workspace_selection.dart';

part 'resolve_workspace_selection_usecase.g.dart';

class ResolveWorkspaceSelectionUsecase {
  ResolveWorkspaceSelectionUsecase({
    required this._loadWorkspaces,
    required this._selectionRepository,
  });

  final Future<List<WorkspaceEntity>> Function() _loadWorkspaces;
  final WorkspaceSelectionRepository _selectionRepository;
  final _logger = Logger('ResolveWorkspaceSelectionUsecase');

  Future<WorkspaceSelection?> call() async {
    final workspaces = await _loadWorkspaceList();
    if (workspaces == null) return null;

    var savedWorkspaceId = await _readSavedWorkspaceId();
    if (savedWorkspaceId != null &&
        !workspaces.any((workspace) => workspace.id == savedWorkspaceId)) {
      await _clearStaleSelection(savedWorkspaceId);
      savedWorkspaceId = null;
    }

    return WorkspaceSelection(
      workspaces: workspaces,
      savedWorkspaceId: savedWorkspaceId,
    );
  }

  Future<List<WorkspaceEntity>?> _loadWorkspaceList() async {
    try {
      return await _loadWorkspaces();
    } on Object catch (error, stackTrace) {
      _logger.severe(
        'Failed to load workspaces for route resolution',
        error,
        stackTrace,
      );

      return null;
    }
  }

  Future<String?> _readSavedWorkspaceId() async {
    try {
      return await _selectionRepository.read();
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Failed to read the saved workspace selection',
        error,
        stackTrace,
      );

      return null;
    }
  }

  Future<void> _clearStaleSelection(String workspaceId) async {
    try {
      await _selectionRepository.clearIfMatches(workspaceId);
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Failed to clear the saved workspace selection',
        error,
        stackTrace,
      );
    }
  }
}

@Riverpod(keepAlive: true)
ResolveWorkspaceSelectionUsecase resolveWorkspaceSelectionUsecase(Ref ref) {
  return ResolveWorkspaceSelectionUsecase(
    loadWorkspaces: ref.watch(workspaceRepositoryProvider).getAllWorkspaces,
    selectionRepository: ref.watch(lastWorkspaceSelectionRepositoryProvider),
  );
}
