import 'package:auravibes_app/router/workspace_navigation.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_navigation_notifier.g.dart';

typedef WorkspaceNavigationState = ({
  AgentDestination agents,
  ConnectionDestination connections,
});

/// Retains safe list categories across listener gaps for each workspace.
@Riverpod(keepAlive: true)
class WorkspaceNavigationNotifier extends _$WorkspaceNavigationNotifier {
  @override
  WorkspaceNavigationState build(String workspaceId) =>
      (agents: .agents, connections: .overview);

  void remember(Uri uri) {
    if (!_belongsToWorkspace(uri)) return;
    _rememberWorkspacePath(WorkspaceNavigation.path(uri), uri);
  }

  String agentsLocation() => switch (state.agents) {
    .agents => AgentsRoute(workspaceId: workspaceId).location,
    .skills => SkillsRoute(workspaceId: workspaceId).location,
  };

  String connectionsLocation() {
    final destination = state.connections;
    if (destination == .tools) {
      return ToolsRoute(workspaceId: workspaceId).location;
    }

    return ServiceConnectionsRoute(
      workspaceId: workspaceId,
      view: destination == .overview ? null : destination.name,
    ).location;
  }

  bool _belongsToWorkspace(Uri uri) =>
      uri.pathSegments.length >= 2 && uri.pathSegments[1] == workspaceId;

  void _rememberWorkspacePath(List<String> path, Uri uri) {
    switch (path) {
      case ['agents']:
        _rememberAgents(.agents);
      case ['skills']:
        _rememberAgents(.skills);
      case ['service-connections']:
        _rememberConnections(
          WorkspaceNavigation.connectionView(uri.queryParameters['view']),
        );
      case ['tools']:
        _rememberConnections(.tools);
    }
  }

  void _rememberAgents(AgentDestination agents) {
    state = (agents: agents, connections: state.connections);
  }

  void _rememberConnections(ConnectionDestination connections) {
    state = (agents: state.agents, connections: connections);
  }
}
