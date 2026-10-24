import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';

class const DirectoryNavigation({
  final List<WorkspaceFolder> path = const [],
  final Object? selected,
  final Map<String?, double> offsets = const {},
  final bool recovered = false,
  final Object? failure,
}) {
  DirectoryNavigation select(Object? item) =>
      DirectoryNavigation(path: path, selected: item, offsets: offsets);
  DirectoryNavigation location(
    List<WorkspaceFolder> value, {
    bool recovered = false,
    Object? failure,
  }) => DirectoryNavigation(
    path: value,
    offsets: offsets,
    recovered: recovered,
    failure: failure,
  );
  DirectoryNavigation scroll(String? parent, double value) =>
      DirectoryNavigation(
        path: path,
        selected: selected,
        offsets: {...offsets, parent: value},
        recovered: recovered,
        failure: failure,
      );
}

/// Identifies an opened saved View without confusing its ID with a table ID.
class const DirectoryViewLocation(final String id);
