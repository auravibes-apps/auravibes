// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/domain/entities/agent_tool_entity.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:riverpod/src/providers/provider.dart';

class ListAgentToolOverridesUsecase {
  const ListAgentToolOverridesUsecase(this._repository);

  final AgentToolsRepositoryContract _repository;

  Future<List<AgentToolOverrideEntity>> call(String agentId) {
    return _repository.getAgentTools(agentId);
  }
}

final ProviderFamily<ListAgentToolOverridesUsecase, String>
listAgentToolOverridesUsecaseProvider =
    Provider.family<ListAgentToolOverridesUsecase, String>((ref, workspaceId) {
      return ListAgentToolOverridesUsecase(
        ref.watch(agentToolsRepositoryProvider(workspaceId)),
      );
    });
