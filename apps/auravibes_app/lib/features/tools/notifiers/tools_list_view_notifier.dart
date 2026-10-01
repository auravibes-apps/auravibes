import 'package:auravibes_app/features/tools/models/tools_sort.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tools_list_view_notifier.g.dart';

typedef ToolsListViewState = ({String searchQuery, ToolsSort sort});

/// Retains list choices across route replacement, independently per workspace.
@Riverpod(keepAlive: true)
class ToolsListViewNotifier extends _$ToolsListViewNotifier {
  @override
  ToolsListViewState build(String workspaceId) =>
      (searchQuery: '', sort: .name);

  void setSearchQuery(String value) {
    state = (searchQuery: value, sort: state.sort);
  }

  void setSort(ToolsSort value) {
    state = (searchQuery: state.searchQuery, sort: value);
  }
}
