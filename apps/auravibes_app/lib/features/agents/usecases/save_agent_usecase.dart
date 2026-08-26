// ignore_for_file: implementation_imports
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:riverpod/src/providers/provider.dart';

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

final ProviderFamily<SaveAgentUsecase, String> saveAgentUsecaseProvider =
    Provider.family<SaveAgentUsecase, String>((ref, workspaceId) {
      return SaveAgentUsecase(ref.watch(agentRepositoryProvider(workspaceId)));
    });
