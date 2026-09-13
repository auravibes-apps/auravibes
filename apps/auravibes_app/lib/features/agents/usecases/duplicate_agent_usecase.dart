import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

class const DuplicateAgentUsecase(final AgentRepository _repository) {
  Future<AgentEntity> call(String agentId) =>
      _repository.duplicateAgent(agentId);
}

final ProviderFamily<DuplicateAgentUsecase, String>
duplicateAgentUsecaseProvider = Provider.family<DuplicateAgentUsecase, String>(
  (ref, workspaceId) =>
      DuplicateAgentUsecase(ref.watch(agentRepositoryProvider(workspaceId))),
);
