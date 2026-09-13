import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/agent_list_query.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/agents/screens/agents_screen.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

const _workspaceId = 'workspace-1';

void main() {
  testWidgets('debounces server-backed search and shows no results', (
    tester,
  ) async {
    final agents = [
      _agent('research', 'Research Agent', 'Use for source gathering'),
      _agent('release', 'Release Agent', 'Use for launch planning'),
    ];
    final repository = _FakeAgentRepository((query) async {
      final search = query.search.trim().toLowerCase();
      if (search.isEmpty) return AgentListPage(agents: agents);

      return AgentListPage(
        agents: agents
            .where(
              (agent) =>
                  agent.name.toLowerCase().contains(search) ||
                  agent.description.toLowerCase().contains(search),
            )
            .toList(),
      );
    });
    await _pumpSubject(tester, repository);

    expect(find.byType(AuraDropdownSelector<String>), findsNWidgets(2));
    expect(find.text('Research Agent'), findsOneWidget);
    expect(find.text('Release Agent'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'launch');
    await tester.pump(const Duration(milliseconds: 299));
    expect(repository.queries, hasLength(1));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(find.text('Release Agent'), findsOneWidget);
    expect(find.text('Research Agent'), findsNothing);

    await tester.enterText(find.byType(EditableText), 'missing');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.text('No agents match these filters'), findsOneWidget);
  });

  testWidgets('shows more pages without replacing loaded agents', (
    tester,
  ) async {
    final repository = _FakeAgentRepository(
      (query) async => query.cursor == null
          ? AgentListPage(
              agents: [_agent('first', 'First Agent', '')],
              nextCursor: 'cursor-1',
            )
          : AgentListPage(agents: [_agent('second', 'Second Agent', '')]),
    );
    await _pumpSubject(tester, repository);

    expect(find.text('First Agent'), findsOneWidget);
    expect(find.text('Show more'), findsOneWidget);

    await tester.tap(find.text('Show more'));
    await tester.pump();
    await tester.pump();

    expect(find.text('First Agent'), findsOneWidget);
    expect(find.text('Second Agent'), findsOneWidget);
    expect(find.text('Show more'), findsNothing);
  });

  testWidgets('preserves the original empty workspace state', (tester) async {
    await _pumpSubject(
      tester,
      _FakeAgentRepository((_) async => const AgentListPage(agents: [])),
    );

    expect(find.text('No agents'), findsOneWidget);
    expect(find.text('Create agent'), findsWidgets);
    expect(find.byType(AuraInput), findsNothing);
  });

  testWidgets('duplicates from the menu, refreshes, and localizes failures', (
    tester,
  ) async {
    final source = _agent('agent-1', 'Helper', 'Use for helper work');
    final agents = <AgentListItem>[source];
    var duplicateCalls = 0;
    final repository = _FakeAgentRepository(
      (_) async => .new(agents: List.of(agents)),
      onDuplicate: (agentId) async {
        expect(agentId, source.id);
        if (duplicateCalls++ == 0) {
          final copy = _agent('agent-copy', 'Helper Copy', source.description);
          agents.add(copy);

          return _entity(copy);
        }
        throw StateError('missing');
      },
    );
    await _pumpSubject(tester, repository);

    await tester.tap(find.byIcon(Icons.more_vert));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate agent'));
    final _ = await tester.pumpAndSettle();

    expect(duplicateCalls, 1);
    expect(repository.queries, hasLength(2));
    expect(find.text('Helper Copy'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate agent'));
    final _ = await tester.pumpAndSettle();

    expect(duplicateCalls, 2);
    expect(find.text('Unable to duplicate agent'), findsOneWidget);
  });
}

Future<void> _pumpSubject(
  WidgetTester tester,
  AgentRepository repository,
) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      TestableApp(
        child: Theme(
          data: .new(extensions: [AuraTheme.light]),
          child: const AgentsScreen(workspaceId: _workspaceId),
        ),
        overrides: [agentRepositoryProvider.overrideWith((_, _) => repository)],
        workspaceId: _workspaceId,
      ),
    );
  });
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

AgentListItem _agent(String id, String name, String description) =>
    AgentListItem(
      id: id,
      name: name,
      description: description,
      isEnabled: true,
      visibility: .both,
      skillCount: 0,
    );

AgentEntity _entity(AgentListItem agent) => AgentEntity(
  id: agent.id,
  workspaceId: _workspaceId,
  name: agent.name,
  content: 'Prompt',
  skills: const [],
  createdAt: .utc(2026),
  updatedAt: .utc(2026),
  description: agent.description,
  isEnabled: agent.isEnabled,
  visibility: agent.visibility,
);

class _FakeAgentRepository implements AgentRepository {
  new(this._onList, {this._onDuplicate});

  final queries = <AgentListQuery>[];
  final Future<AgentListPage> Function(AgentListQuery query) _onList;
  final Future<AgentEntity> Function(String agentId)? _onDuplicate;

  @override
  Future<AgentListPage> listAgents(AgentListQuery query) {
    queries.add(query);

    return _onList(query);
  }

  @override
  Future<AgentEntity> createAgent(String workspaceId, AgentToCreate agent) =>
      throw UnimplementedError();

  @override
  Future<AgentEntity> duplicateAgent(String agentId) =>
      _onDuplicate?.call(agentId) ?? (throw UnimplementedError());

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
