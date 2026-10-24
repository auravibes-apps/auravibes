import 'package:auravibes_app/features/workspaces/models/directory_navigation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'directory_navigation_notifier.g.dart';

/// Keeps in-memory navigation when the responsive shell remounts its content.
@Riverpod(keepAlive: true)
class DirectoryNavigationNotifier extends _$DirectoryNavigationNotifier {
  @override
  DirectoryNavigation build(String workspaceId) => const DirectoryNavigation();
  void open(Object? item) => state = state.select(item);
  void enter(WorkspaceFolder folder) =>
      state = state.location([...state.path, folder]);
  void ancestor(int length) =>
      state = state.location(state.path.take(length).toList());
  void rememberOffset(String? parent, double offset) =>
      state = state.scroll(parent, offset);

  Future<void> refreshPath(
    Future<OrganizeWorkspaceFoldersUsecase> folders,
  ) async {
    final original = state.path;
    try {
      final path = await _PathReader(await folders).read(original);
      _apply(original, path);
    } on Object catch (error) {
      _fail(original, error);
    }
  }

  void _fail(List<WorkspaceFolder> original, Object error) {
    if (!ref.mounted || !identical(state.path, original)) return;
    state = state.location(original, failure: error);
  }

  void _apply(List<WorkspaceFolder> original, List<WorkspaceFolder> path) {
    if (!ref.mounted || !identical(state.path, original)) return;
    state = state.location(path, recovered: path.length != original.length);
  }
}

class const _PathReader(final OrganizeWorkspaceFoldersUsecase folders) {
  Future<List<WorkspaceFolder>> read(List<WorkspaceFolder> original) async {
    final current = <WorkspaceFolder>[];
    for (final ancestor in original) {
      final folder = await _folder(current.lastOrNull?.id, ancestor.id);
      if (folder == null) return [];
      current.add(folder);
    }

    return current;
  }

  Future<WorkspaceFolder?> _folder(String? parent, String id) async {
    final children = await folders.list(parentId: parent);

    return children.where((child) => child.id == id).firstOrNull;
  }
}
