import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:riverpod/riverpod.dart';

class ListAgentsUsecase {
  const ListAgentsUsecase(this._repository);

  final AgentRepository _repository;

  Stream<List<AgentEntity>> call(String workspaceId) {
    return _repository.watchAgentsByWorkspace(workspaceId);
  }
}

final listAgentsUsecaseProvider = Provider<ListAgentsUsecase>(
  (ref) => ListAgentsUsecase(ref.watch(agentRepositoryProvider)),
  dependencies: [agentRepositoryProvider],
);

// ignore: specify_nonobvious_property_types - Riverpod family type is verbose.
final agentsProvider = StreamProvider.family<List<AgentEntity>, String>(
  (ref, workspaceId) => ref.watch(listAgentsUsecaseProvider).call(workspaceId),
  dependencies: [listAgentsUsecaseProvider],
);
