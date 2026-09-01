// ignore_for_file: implementation_imports
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod/src/providers/provider.dart';

class const ListAgentsUsecase(final AgentRepository _repository) {
  Stream<List<AgentEntity>> call(String workspaceId) {
    return _repository.watchAgentsByWorkspace(workspaceId);
  }
}

final ProviderFamily<ListAgentsUsecase, String> listAgentsUsecaseProvider =
    Provider.family<ListAgentsUsecase, String>(
      (ref, workspaceId) =>
          ListAgentsUsecase(ref.watch(agentRepositoryProvider(workspaceId))),
    );

// ignore: specify_nonobvious_property_types - Riverpod family type is verbose.
final agentsProvider = StreamProvider.family<List<AgentEntity>, String>(
  (ref, workspaceId) =>
      ref.watch(listAgentsUsecaseProvider(workspaceId)).call(workspaceId),
);
