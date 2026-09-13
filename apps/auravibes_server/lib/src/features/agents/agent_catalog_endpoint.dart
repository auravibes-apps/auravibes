import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import '../workspace_state/repositories/workspace_state_repository.dart';
import 'agent_catalog_repository.dart';
import 'agent_catalog_use_cases.dart';

class AgentCatalogEndpoint extends Endpoint {
  AgentCatalogUseCases get _useCases => AgentCatalogUseCases(
    AgentCatalogRepository(),
    WorkspaceStateRepository(),
  );

  Future<AgentCatalogPage> list(
    Session session,
    ListAgentsRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.list(session, userId: account.userId, request: request);
  }

  Future<List<WorkspaceResource>> getResources(
    Session session,
    GetAgentResourcesRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return _useCases.getResources(
      session,
      userId: account.userId,
      request: request,
    );
  }
}
