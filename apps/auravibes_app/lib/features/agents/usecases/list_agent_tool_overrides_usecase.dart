import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/domain/entities/agent_tool_entity.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:riverpod/riverpod.dart';

class ListAgentToolOverridesUsecase {
  const ListAgentToolOverridesUsecase(this._repository);

  final AgentToolsRepository _repository;

  Future<List<AgentToolOverrideEntity>> call(String agentId) {
    return _repository.getAgentTools(agentId);
  }
}

final listAgentToolOverridesUsecaseProvider =
    Provider<ListAgentToolOverridesUsecase>((ref) {
      return ListAgentToolOverridesUsecase(
        ref.watch(agentToolsRepositoryProvider),
      );
    });
