import 'package:auravibes_app/router/workspace_navigation.dart' as routes;
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_navigation_notifier.g.dart';

typedef WorkspaceNavigationState = ({
  routes.AgentDestination agents,
  routes.ConnectionDestination connections,
});

/// Retains safe list categories across listener gaps for each workspace.
@Riverpod(keepAlive: true)
class WorkspaceNavigationNotifier extends _$WorkspaceNavigationNotifier {
  @override
  WorkspaceNavigationState build(String workspaceId) =>
      (agents: .agents, connections: .overview);

  void remember(Uri uri) {
    if (uri.pathSegments.length < 2 || uri.pathSegments[1] != workspaceId) {
      return;
    }
    final path = routes.WorkspaceNavigation.path(uri);
    switch (path) {
      case ['more', 'agents']:
        state = (agents: .agents, connections: state.connections);
      case ['more', 'skills']:
        state = (agents: .skills, connections: state.connections);
      case ['more', 'service-connections']:
        state = (
          agents: state.agents,
          connections: routes.WorkspaceNavigation.connectionView(
            uri.queryParameters['view'],
          ),
        );
      case ['more', 'tools']:
        state = (agents: state.agents, connections: .tools);
    }
  }

  String agentsLocation() => switch (state.agents) {
    .agents => AgentsRoute(workspaceId: workspaceId).location,
    .skills => SkillsRoute(workspaceId: workspaceId).location,
  };

  String connectionsLocation() {
    if (state.connections == .tools) {
      return ToolsRoute(workspaceId: workspaceId).location;
    }

    return ServiceConnectionsRoute(
      workspaceId: workspaceId,
      view: state.connections == .overview ? null : state.connections.name,
    ).location;
  }
}
