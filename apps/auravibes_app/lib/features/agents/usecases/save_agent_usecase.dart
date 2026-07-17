import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:riverpod/riverpod.dart';

class SaveAgentUsecase {
  const SaveAgentUsecase(this._repository);

  final AgentRepository _repository;

  Future<AgentEntity> create(String workspaceId, AgentToCreate agent) {
    return _repository.createAgent(workspaceId, agent);
  }

  Future<AgentEntity> update(String agentId, AgentToUpdate agent) {
    return _repository.updateAgent(agentId, agent);
  }
}

final saveAgentUsecaseProvider = Provider<SaveAgentUsecase>((ref) {
  return SaveAgentUsecase(ref.watch(agentRepositoryProvider));
});
