// ignore_for_file: implementation_imports
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:riverpod/src/providers/provider.dart';

class DeleteAgentUsecase {
  const DeleteAgentUsecase(this._repository);

  final AgentRepository _repository;

  Future<bool> call(String agentId) => _repository.deleteAgent(agentId);
}

final ProviderFamily<DeleteAgentUsecase, String> deleteAgentUsecaseProvider =
    Provider.family<DeleteAgentUsecase, String>((
      ref,
      workspaceId,
    ) {
      return DeleteAgentUsecase(
        ref.watch(agentRepositoryProvider(workspaceId)),
      );
    });
