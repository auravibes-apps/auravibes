import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/domain/entities/agent_tool_entity.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

class ListAgentToolOverridesUsecase {
  const ListAgentToolOverridesUsecase(this._repository);

  final AgentToolsRepositoryContract _repository;

  Future<List<AgentToolOverrideEntity>> call(String agentId) {
    return _repository.getAgentTools(agentId);
  }
}

@Dependencies([agentToolsRepository])
final listAgentToolOverridesUsecaseProvider =
    Provider<ListAgentToolOverridesUsecase>(
      (ref) {
        return ListAgentToolOverridesUsecase(
          ref.watch(agentToolsRepositoryProvider),
        );
      },
      dependencies: [agentToolsRepositoryProvider],
    );
