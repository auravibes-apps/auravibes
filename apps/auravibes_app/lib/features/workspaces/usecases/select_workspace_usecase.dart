import 'package:auravibes_app/domain/repositories/workspace_selection_repository.dart';
import 'package:auravibes_app/features/workspaces/providers/last_workspace_selection_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'select_workspace_usecase.g.dart';

class const SelectWorkspaceUsecase({
  required final WorkspaceSelectionRepository _selectionRepository,
}) {
  Future<String> call({
    required String workspaceId,
    bool Function()? isCurrent,
  }) async {
    if (workspaceId.isEmpty ||
        workspaceId == '.' ||
        workspaceId == '..' ||
        workspaceId != Uri.encodeComponent(workspaceId)) {
      throw ArgumentError.value(
        workspaceId,
        'workspaceId',
        'Must be a single URI path segment',
      );
    }

    final previous = isCurrent == null
        ? null
        : await _selectionRepository.read();
    if (isCurrent?.call() == false) return workspaceId;
    await _selectionRepository.save(workspaceId);
    if (isCurrent?.call() == false) {
      await _restoreSelection(previous, workspaceId);
    }

    return workspaceId;
  }

  Future<void> _restoreSelection(String? previous, String attempted) =>
      previous == null
      ? _selectionRepository.clearIfMatches(attempted)
      : _selectionRepository.save(previous);
}

@Riverpod(keepAlive: true)
SelectWorkspaceUsecase selectWorkspaceUsecase(Ref ref) {
  return SelectWorkspaceUsecase(
    selectionRepository: ref.watch(lastWorkspaceSelectionRepositoryProvider),
  );
}
