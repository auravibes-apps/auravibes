import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:riverpod/riverpod.dart';

class ListAgentsUsecase {
  const ListAgentsUsecase(this._repository);

  final AgentsRepository _repository;

  Stream<List<AgentEntity>> call(String workspaceId) {
    return _repository.watchAgentsByWorkspace(workspaceId);
  }
}

final listAgentsUsecaseProvider = Provider<ListAgentsUsecase>((ref) {
  return ListAgentsUsecase(ref.watch(agentsRepositoryProvider));
});

// ignore: specify_nonobvious_property_types - Riverpod family type is verbose.
final agentsProvider = StreamProvider.family<List<AgentEntity>, String>((
  ref,
  workspaceId,
) {
  return ref.watch(listAgentsUsecaseProvider).call(workspaceId);
});
