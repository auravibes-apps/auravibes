// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_app/features/agents/agent_adapters/cloud_agent_repository.dart';
import 'package:auravibes_app/features/agents/agent_adapters/cloud_agent_tools_repository.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_resource_store.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod/src/providers/provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'agent_repository_providers.g.dart';

@Riverpod(keepAlive: true)
AgentsRepository agentsRepository(Ref ref) {
  return AgentsRepository(ref.watch(appDatabaseProvider));
}

final ProviderFamily<AgentRepository, String> agentRepositoryProvider =
    Provider.family<AgentRepository, String>((ref, workspaceId) {
      final session = ref
          .watch(workspaceSessionForRouteProvider(workspaceId))
          .requireValue;
      if (session.cloud == null) {
        return ref.watch(agentsRepositoryProvider);
      }
      final gateway = ref.watch(
        cloudWorkspaceStateGatewayProvider(session).future,
      );
      final store = CloudWorkspaceResourceStore.deferred(gateway);

      return CloudAgentRepository.fromStore(
        workspaceId: session.workspace.localWorkspaceId,
        store: store,
        gateway: gateway,
      );
    });

@riverpod
AgentToolsRepositoryContract agentToolsRepository(Ref ref, String workspaceId) {
  final session = ref
      .watch(workspaceSessionForRouteProvider(workspaceId))
      .requireValue;
  if (session.cloud != null) {
    final store = CloudWorkspaceResourceStore.deferred(
      ref.watch(cloudWorkspaceStateGatewayProvider(session).future),
    );

    return CloudAgentToolsRepository.fromStore(store: store);
  }

  return AgentToolsRepository(ref.watch(appDatabaseProvider));
}

// ignore: specify_nonobvious_property_types - Riverpod family type is verbose.
final agentsProvider = StreamProvider.family<List<AgentEntity>, String>(
  (ref, workspaceId) => ref
      .watch(agentRepositoryProvider(workspaceId))
      .watchAgentsByWorkspace(workspaceId),
);
