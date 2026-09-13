import 'dart:async';
import 'dart:collection';

import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/agent_list_query.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_list_notifier.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

const _workspaceId = 'workspace-1';

void main() {
  test('debounces search and ignores a stale result', () async {
    final stale = Completer<AgentListPage>();
    final current = Completer<AgentListPage>();
    final repository = _FakeAgentRepository([
      _page([_agent('initial')]),
      stale.future,
      current.future,
    ]);
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(agentListProvider(_workspaceId), (
      _,
      _,
    ) {
      final _ = repository;
    });
    addTearDown(subscription.close);
    final _ = await container.read(agentListProvider(_workspaceId).future);
    final notifier = container.read(agentListProvider(_workspaceId).notifier)
      ..setSearch('first');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(repository.queries, hasLength(1));
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(repository.queries.last.search, 'first');

    notifier.setStatus(.enabled);
    current.complete(_page([_agent('current')]));
    await _flush();
    stale.complete(_page([_agent('stale')]));
    await _flush();

    final state = container.read(agentListProvider(_workspaceId)).requireValue;
    expect(state.agents.single.id, 'current');
    expect(repository.queries.last.status, AgentListStatus.enabled);
    expect(repository.queries.last.cursor, isNull);
  });

  test('deduplicates load more and retries without dropping rows', () async {
    final failedPage = Completer<AgentListPage>();
    final repository = _FakeAgentRepository([
      _page([_agent('first')], nextCursor: 'cursor-1'),
      failedPage.future,
      _page([_agent('first'), _agent('second')]),
    ]);
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(agentListProvider(_workspaceId), (
      _,
      _,
    ) {
      final _ = repository;
    });
    addTearDown(subscription.close);
    final _ = await container.read(agentListProvider(_workspaceId).future);
    final notifier = container.read(agentListProvider(_workspaceId).notifier);

    final firstLoad = notifier.loadMore();
    final duplicateLoad = notifier.loadMore();
    expect(repository.queries, hasLength(2));
    failedPage.completeError(StateError('offline'));
    final _ = await Future.wait([firstLoad, duplicateLoad]);

    var state = container.read(agentListProvider(_workspaceId)).requireValue;
    expect(state.agents.single.id, 'first');
    expect(state.loadMoreFailed, isTrue);

    await notifier.retry();

    state = container.read(agentListProvider(_workspaceId)).requireValue;
    expect(state.agents.map((agent) => agent.id), ['first', 'second']);
    expect(state.loadMoreFailed, isFalse);
    expect(repository.queries.last.cursor, 'cursor-1');
  });
}

ProviderContainer _container(AgentRepository repository) => ProviderContainer(
  overrides: [agentRepositoryProvider.overrideWith((_, _) => repository)],
);

Future<void> _flush() async {
  await Future<void>.delayed(.zero);
  await Future<void>.delayed(.zero);
}

AgentListPage _page(List<AgentListItem> agents, {String? nextCursor}) =>
    AgentListPage(agents: agents, nextCursor: nextCursor);

AgentListItem _agent(String id) => AgentListItem(
  id: id,
  name: id,
  description: '',
  isEnabled: true,
  visibility: .both,
  skillCount: 0,
);

class _FakeAgentRepository(Iterable<FutureOr<AgentListPage>> responses)
    implements AgentRepository {
  final queries = <AgentListQuery>[];
  final Queue<FutureOr<AgentListPage>> _responses = .of(responses);

  @override
  Future<AgentListPage> listAgents(AgentListQuery query) {
    queries.add(query);

    return Future.value(_responses.removeFirst());
  }

  @override
  Future<AgentEntity> createAgent(String workspaceId, AgentToCreate agent) =>
      throw UnimplementedError();

  @override
  Future<bool> deleteAgent(String agentId) => throw UnimplementedError();

  @override
  Future<AgentEntity?> getAgentById(String agentId) =>
      throw UnimplementedError();

  @override
  Future<List<AgentEntity>> getAgentsByWorkspace(String workspaceId) =>
      throw UnimplementedError();

  @override
  Future<AgentEntity> updateAgent(String agentId, AgentToUpdate agent) =>
      throw UnimplementedError();

  @override
  Stream<List<AgentEntity>> watchAgentsByWorkspace(String workspaceId) =>
      throw UnimplementedError();
}
