import 'package:auravibes_app/features/workspaces/notifiers/workspace_navigation_notifier.dart';
import 'package:auravibes_app/router/workspace_navigation.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test(
    'direct list entries have no More parent, editors keep their owning list',
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
        'skill-credential-definitions',
        'cloud-accounts',
        'manage-workspaces',
      ]) {
        final matches = router.configuration.findMatch(
          .parse('/workspaces/A/more/$list'),
        );
        expect(paths(matches.matches), [
          '/workspaces/:workspaceId',
          'more/$list',
        ]);
      }
      final editor = router.configuration.findMatch(
        .parse('/workspaces/A/more/skills/skill-A/resources/resource-B'),
      );
      expect(paths(editor.matches), [
        '/workspaces/:workspaceId',
        'more/skills',
        ':skillId/resources/:resourceId',
      ]);
    },
  );

  test('classifies destinations separately from conversations', () {
    final paths = {
      'chat/new': WorkspaceDestination.chats,
      'chats': WorkspaceDestination.chats,
      'chats/chat-a/sub-agents/child': WorkspaceDestination.chats,
      'more/agents/a': WorkspaceDestination.agentsAndSkills,
      'more/skills/a/resources/b': WorkspaceDestination.agentsAndSkills,
      'more/service-connections/new?credentialDefinitionId=type'
              '&appSkillId=skill':
          WorkspaceDestination.connections,
      'more/skill-credential-definitions/type':
          WorkspaceDestination.connections,
      'more/models': WorkspaceDestination.connections,
      'more/tools': WorkspaceDestination.connections,
      'settings': WorkspaceDestination.appSettings,
      'more/cloud-accounts/login': WorkspaceDestination.cloudAccounts,
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
        'more/cloud-accounts',
        'more/cloud-accounts/add',
        'more/cloud-accounts/login',
        'more/cloud-accounts/register',
        'more/cloud-accounts/forgot-password',
      ]) {
        expect(
          WorkspaceNavigation.isAppScoped(.parse('/workspaces/A/$route')),
          isTrue,
        );
      }
      for (final route in [
        'workspace-settings',
        'settings/editor',
        'more/cloud-accounts/arbitrary',
        'more/cloud-accounts/login/editor',
        'more/agents/new',
        'more/manage-workspaces',
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
      ..remember(.parse('/workspaces/A/more/skills?search=secret'))
      ..remember(.parse('/workspaces/A/more/skills/skill-a'))
      ..remember(
        .parse(
          '/workspaces/A/more/service-connections?view=providers'
          '&appSkillId=skill-a',
        ),
      )
      ..remember(
        .parse(
          '/workspaces/A/more/service-connections/connection-a?view=credentials',
        ),
      )
      ..remember(.parse('/workspaces/B/more/tools'));
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
    a.remember(.parse('/workspaces/A/more/tools'));
    expect(a.connectionsLocation(), ToolsRoute(workspaceId: 'A').location);
    a.remember(.parse('/workspaces/A/more/skill-credential-definitions'));
    expect(a.connectionsLocation(), ToolsRoute(workspaceId: 'A').location);
    a.remember(.parse('/workspaces/A/more/service-connections?view=unsafe'));
    expect(
      a.connectionsLocation(),
      ServiceConnectionsRoute(workspaceId: 'A').location,
    );
  });

  test('old URLs and allowlisted connection view remain typed', () {
    expect(AgentsRoute(workspaceId: 'A').location, '/workspaces/A/more/agents');
    expect(SkillsRoute(workspaceId: 'A').location, '/workspaces/A/more/skills');
    expect(MoreRoute(workspaceId: 'A').location, '/workspaces/A/more');
    expect(
      WorkspaceSettingsRoute(workspaceId: 'A').location,
      '/workspaces/A/workspace-settings',
    );
    expect(
      WorkspaceManagementRoute(workspaceId: 'A', view: 'connect').location,
      '/workspaces/A/more/manage-workspaces?view=connect',
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
