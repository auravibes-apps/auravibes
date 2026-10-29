import 'package:auravibes_app/features/workspaces/notifiers/workspace_navigation_notifier.dart';
import 'package:auravibes_app/router/workspace_navigation.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test(
    'direct list entries have no more prefix, editors keep their owning list',
    () {
      final router = GoRouter(routes: $appRoutes);
      addTearDown(router.dispose);
      List<String> paths(List<RouteMatchBase> matches) => [
        for (final match in matches)
          if (match is ShellRouteMatch)
            ...paths(match.matches)
          else if (match is RouteMatch)
            match.route.path,
      ];
      for (final list in [
        'agents',
        'skills',
        'tools',
        'service-connections',
        'more/workflows',
        'cloud-accounts',
        'items',
        'manage-workspaces',
      ]) {
        final matches = router.configuration.findMatch(
          .parse('/workspaces/A/$list'),
        );
        expect(paths(matches.matches), ['/workspaces/:workspaceId', list]);
      }
      final editor = router.configuration.findMatch(
        .parse('/workspaces/A/skills/skill-A/resources/resource-B'),
      );
      expect(paths(editor.matches), [
        '/workspaces/:workspaceId',
        'skills',
        ':skillId/resources/:resourceId',
      ]);
    },
  );

  test('classifies destinations separately from conversations', () {
    final paths = {
      'chat/new': WorkspaceDestination.chats,
      'chats': WorkspaceDestination.chats,
      'chats/chat-a/sub-agents/child': WorkspaceDestination.chats,
      'agents/a': WorkspaceDestination.agentsAndSkills,
      'skills/a/resources/b': WorkspaceDestination.agentsAndSkills,
      'service-connections/new?type=connector&connectorId=jina':
          WorkspaceDestination.connections,
      'models': WorkspaceDestination.connections,
      'tools': WorkspaceDestination.connections,
      'more/workflows': WorkspaceDestination.workflows,
      'settings': WorkspaceDestination.appSettings,
      'cloud-accounts/login': WorkspaceDestination.cloudAccounts,
      'items': WorkspaceDestination.items,
    };
    for (final entry in paths.entries) {
      expect(
        WorkspaceNavigation.classify(.parse('/workspaces/A/${entry.key}')),
        entry.value,
        reason: entry.key,
      );
    }
    expect(
      WorkspaceNavigation.classify(.parse('/workspaces/A/workspace-settings')),
      isNull,
    );
    expect(
      WorkspaceNavigation.isConversation(
        .parse('/workspaces/A/chats/newish-id'),
      ),
      isTrue,
    );
    expect(
      WorkspaceNavigation.isConversation(.parse('/workspaces/A/chats')),
      isFalse,
    );
  });

  test(
    'app scope admits only exact appearance and account recovery routes',
    () {
      for (final route in [
        'settings',
        'cloud-accounts',
        'cloud-accounts/add',
        'cloud-accounts/login',
        'cloud-accounts/register',
        'cloud-accounts/forgot-password',
      ]) {
        expect(
          WorkspaceNavigation.isAppScoped(.parse('/workspaces/A/$route')),
          isTrue,
        );
      }
      for (final route in [
        'workspace-settings',
        'settings/editor',
        'cloud-accounts/arbitrary',
        'cloud-accounts/login/editor',
        'agents/new',
        'manage-workspaces',
      ]) {
        expect(
          WorkspaceNavigation.isAppScoped(.parse('/workspaces/A/$route')),
          isFalse,
        );
      }
      expect(
        WorkspaceNavigation.isAppScoped(
          .parse('https://example.com/workspaces/A/settings'),
        ),
        isFalse,
      );
    },
  );

  test('remembers safe lists per workspace without entity or query IDs', () {
    final container = ProviderContainer.test();
    final a = container.read(workspaceNavigationProvider('A').notifier);
    final b = container.read(workspaceNavigationProvider('B').notifier);
    a
      ..remember(.parse('/workspaces/A/skills?search=secret'))
      ..remember(.parse('/workspaces/A/skills/skill-a'))
      ..remember(
        .parse(
          '/workspaces/A/service-connections?view=providers'
          '&appSkillId=skill-a',
        ),
      )
      ..remember(
        .parse(
          '/workspaces/A/service-connections/connection-a?view=credentials',
        ),
      )
      ..remember(.parse('/workspaces/B/tools'));
    expect(a.agentsLocation(), SkillsRoute(workspaceId: 'A').location);
    expect(
      a.connectionsLocation(),
      ServiceConnectionsRoute(workspaceId: 'A', view: 'providers').location,
    );
    expect(b.agentsLocation(), AgentsRoute(workspaceId: 'B').location);
    expect(
      b.connectionsLocation(),
      ServiceConnectionsRoute(workspaceId: 'B').location,
    );
    a.remember(.parse('/workspaces/A/tools'));
    expect(a.connectionsLocation(), ToolsRoute(workspaceId: 'A').location);
    a.remember(.parse('/workspaces/A/service-connections?view=connectors'));
    expect(
      a.connectionsLocation(),
      ServiceConnectionsRoute(workspaceId: 'A', view: 'connectors').location,
    );
    a.remember(.parse('/workspaces/A/service-connections?view=unsafe'));
    expect(
      a.connectionsLocation(),
      ServiceConnectionsRoute(workspaceId: 'A').location,
    );
  });

  test('canonical URLs and allowlisted connection view remain typed', () {
    expect(AgentsRoute(workspaceId: 'A').location, '/workspaces/A/agents');
    expect(SkillsRoute(workspaceId: 'A').location, '/workspaces/A/skills');
    expect(
      WorkspaceSettingsRoute(workspaceId: 'A').location,
      '/workspaces/A/workspace-settings',
    );
    expect(
      WorkspaceManagementRoute(workspaceId: 'A', view: 'connect').location,
      '/workspaces/A/manage-workspaces?view=connect',
    );
    for (final view in ['providers', 'services', 'credentials']) {
      expect(
        ServiceConnectionsRoute(workspaceId: 'A', view: view).destination.name,
        view,
      );
    }
    expect(
      ServiceConnectionsRoute(workspaceId: 'A', view: 'unknown').destination,
      ConnectionDestination.overview,
    );
  });
}
