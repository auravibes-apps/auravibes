import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/usecases/run_sub_agent_tool_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('AppSubAgentCatalog', () {
    test('lists all enabled agents with types', () async {
      final repository = _MockAgentsRepository();
      final now = DateTime(2026);
      when(
        () => repository.getAgentsByWorkspace('workspace-1'),
      ).thenAnswer(
        (_) async => [
          _agent(
            id: 'main',
            now: now,
            visibility: AgentVisibility.chatSelector,
          ),
          _agent(
            id: 'sub',
            now: now,
            visibility: AgentVisibility.subAgentList,
          ),
          _agent(id: 'both', now: now, visibility: AgentVisibility.both),
          _agent(
            id: 'off',
            now: now,
            visibility: AgentVisibility.both,
            isEnabled: false,
          ),
        ],
      );

      final agents = await AppSubAgentCatalog(
        repository,
      ).listSubAgents('workspace-1');

      expect(agents.map((agent) => agent.id), ['main', 'sub', 'both']);
      expect(agents.map((agent) => agent.types), [
        ['main'],
        ['sub_agent'],
        ['main', 'sub_agent'],
      ]);
    });
  });
}

AgentEntity _agent({
  required String id,
  required DateTime now,
  required AgentVisibility visibility,
  bool isEnabled = true,
}) {
  return AgentEntity(
    id: id,
    workspaceId: 'workspace-1',
    name: id,
    content: 'content',
    skills: const [],
    createdAt: now,
    updatedAt: now,
    description: '$id description',
    isEnabled: isEnabled,
    visibility: visibility,
  );
}

class _MockAgentsRepository extends Mock implements AgentsRepository {}
