import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/service_connections/models/connection_filter.dart';
import 'package:auravibes_app/features/service_connections/notifiers/connections_list_view_notifier.dart';
import 'package:auravibes_app/features/skills/models/skill_sort.dart';
import 'package:auravibes_app/features/skills/notifiers/skills_list_view_notifier.dart';
import 'package:auravibes_app/features/tools/models/tools_sort.dart';
import 'package:auravibes_app/features/tools/notifiers/tools_list_view_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('skills retain choices across visits and isolate workspaces', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = skillsListViewProvider('A');
    final subscription = container.listen(
      provider,
      (_, next) => expect(next, isNotNull),
    );
    container.read(provider.notifier)
      ..setSearchQuery('summary')
      ..setSourceFilter(.user)
      ..setEnabledFilter(value: false)
      ..setSort(.enabled);
    subscription.close();
    await container.pump();
    expect(container.read(provider), (
      searchQuery: 'summary',
      sourceFilter: SkillSource.user,
      enabledFilter: false,
      sort: SkillSort.enabled,
    ));
    expect(container.read(skillsListViewProvider('B')), (
      searchQuery: '',
      sourceFilter: null,
      enabledFilter: null,
      sort: SkillSort.name,
    ));
  });

  test(
    'tools retain search and sort across listener gaps and isolate workspaces',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = toolsListViewProvider('A');
      final subscription = container.listen(
        provider,
        (_, next) => expect(next, isNotNull),
      );
      container.read(provider.notifier)
        ..setSearchQuery('files')
        ..setSort(.enabled);
      subscription.close();
      await container.pump();
      expect(container.read(provider), (
        searchQuery: 'files',
        sort: ToolsSort.enabled,
      ));
      expect(container.read(toolsListViewProvider('B')), (
        searchQuery: '',
        sort: ToolsSort.name,
      ));
    },
  );

  test('connection choices belong to the workspace and local view', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = connectionsListViewProvider('A', .services);
    final subscription = container.listen(
      provider,
      (_, next) => expect(next, isNotNull),
    );
    container.read(provider.notifier)
      ..setSearchQuery('notion')
      ..setFilter(.needsAuth)
      ..setKind(.mcpServers)
      ..setOauthOnly(value: true);
    subscription.close();
    await container.pump();
    expect(container.read(provider), (
      searchQuery: 'notion',
      filter: ConnectionFilter.needsAuth,
      kind: ConnectionFilter.mcpServers,
      oauthOnly: true,
    ));
    expect(container.read(connectionsListViewProvider('B', .services)), (
      searchQuery: '',
      filter: ConnectionFilter.all,
      kind: ConnectionFilter.all,
      oauthOnly: false,
    ));
    expect(container.read(connectionsListViewProvider('A', .overview)), (
      searchQuery: '',
      filter: ConnectionFilter.all,
      kind: ConnectionFilter.all,
      oauthOnly: false,
    ));
  });
}
