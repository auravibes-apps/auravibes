// ignore_for_file: implementation_imports
import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/features/agents/agent_adapters/agent_repository.dart';
import 'package:auravibes_app/features/agents/agent_adapters/cloud_agent_repository.dart';
import 'package:auravibes_app/features/agents/agent_adapters/cloud_agent_tools_repository.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
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

      return CloudAgentRepository(
        patch: ({required requestId, required operations}) async {
          final cloud = await gateway;
          if (cloud == null) {
            throw StateError('Cloud workspace gateway unavailable');
          }

          return await cloud.patch(
            requestId: requestId,
            operations: operations,
          );
        },
        workspaceId: session.workspace.localWorkspaceId,
        read: () async {
          final cloud = await gateway;
          if (cloud == null) return const [];
          final response = await cloud.read(
            pages: [
              WorkspaceResourcePageRequest(
                resourceKind: WorkspaceResourceKind.agent,
                limit: 100,
              ),
              WorkspaceResourcePageRequest(
                resourceKind: WorkspaceResourceKind.agentAssociation,
                limit: 100,
              ),
            ],
          );

          return response.pages.expand((page) => page.resources).toList();
        },
      );
    });

@riverpod
AgentToolsRepositoryContract agentToolsRepository(Ref ref, String workspaceId) {
  final session = ref
      .watch(workspaceSessionForRouteProvider(workspaceId))
      .requireValue;
  if (session.cloud != null) {
    return CloudAgentToolsRepository(
      patch: ({required requestId, required operations}) async {
        final cloud = await ref.read(
          cloudWorkspaceStateGatewayProvider(session).future,
        );
        if (cloud == null) {
          throw StateError('Cloud workspace gateway unavailable');
        }

        return await cloud.patch(requestId: requestId, operations: operations);
      },
      read: () async {
        final cloud = await ref.read(
          cloudWorkspaceStateGatewayProvider(session).future,
        );
        if (cloud == null) return const [];
        final response = await cloud.read(
          pages: [
            WorkspaceResourcePageRequest(
              resourceKind: .agentAssociation,
              limit: 100,
            ),
          ],
        );

        return response.pages.single.resources;
      },
    );
  }

  return AgentToolsRepository(ref.watch(appDatabaseProvider));
}
