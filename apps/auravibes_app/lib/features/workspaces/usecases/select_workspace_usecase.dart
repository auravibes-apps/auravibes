import 'package:auravibes_app/domain/repositories/workspace_selection_repository.dart';
import 'package:auravibes_app/features/workspaces/providers/last_workspace_selection_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'select_workspace_usecase.g.dart';

class SelectWorkspaceUsecase {
  const SelectWorkspaceUsecase({required this._selectionRepository});

  final WorkspaceSelectionRepository _selectionRepository;

  Future<String> call({required String workspaceId}) async {
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

    await _selectionRepository.save(workspaceId);

    return workspaceId;
  }
}

@Riverpod(keepAlive: true)
SelectWorkspaceUsecase selectWorkspaceUsecase(Ref ref) {
  return SelectWorkspaceUsecase(
    selectionRepository: ref.watch(lastWorkspaceSelectionRepositoryProvider),
  );
}
