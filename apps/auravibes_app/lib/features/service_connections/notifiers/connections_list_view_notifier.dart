import 'package:auravibes_app/features/service_connections/models/connection_filter.dart';
import 'package:auravibes_app/router/workspace_navigation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connections_list_view_notifier.g.dart';

typedef ConnectionsListViewState = ({
  String searchQuery,
  ConnectionFilter filter,
  ConnectionFilter kind,
  bool oauthOnly,
});

/// Retains list choices across route replacement, independently per workspace.
@Riverpod(keepAlive: true)
class ConnectionsListViewNotifier extends _$ConnectionsListViewNotifier {
  @override
  ConnectionsListViewState build(
    String workspaceId,
    ConnectionDestination view,
  ) => (searchQuery: '', filter: .all, kind: .all, oauthOnly: false);

  void setSearchQuery(String value) {
    state = (
      searchQuery: value,
      filter: state.filter,
      kind: state.kind,
      oauthOnly: state.oauthOnly,
    );
  }

  void setKind(ConnectionFilter value) {
    state = (
      searchQuery: state.searchQuery,
      filter: state.filter,
      kind: value,
      oauthOnly: state.oauthOnly,
    );
  }

  void setOauthOnly({required bool value}) {
    state = (
      searchQuery: state.searchQuery,
      filter: state.filter,
      kind: state.kind,
      oauthOnly: value,
    );
  }

  void setFilter(ConnectionFilter value) {
    state = (
      searchQuery: state.searchQuery,
      filter: value,
      kind: state.kind,
      oauthOnly: state.oauthOnly,
    );
  }
}
