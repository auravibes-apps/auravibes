import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:riverpod/riverpod.dart';

class DeleteAgentUsecase {
  const DeleteAgentUsecase(this._repository);

  final AgentsRepository _repository;

  Future<bool> call(String agentId) => _repository.deleteAgent(agentId);
}

final deleteAgentUsecaseProvider = Provider<DeleteAgentUsecase>((ref) {
  return DeleteAgentUsecase(ref.watch(agentsRepositoryProvider));
});
