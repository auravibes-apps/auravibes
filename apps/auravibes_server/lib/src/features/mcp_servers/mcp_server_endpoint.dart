import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../accounts/authenticated_account_resolver.dart';
import '../sync/stream/sync_wakeups.dart';
import 'mcp_server_probe.dart';
import 'mcp_server_repository.dart';
import 'mcp_server_use_cases.dart';

class McpServerEndpoint extends Endpoint {
  Future<CreateMcpServerResult> create(
    Session session,
    CreateMcpServerRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    final result = await McpServerUseCases(
      McpServerRepository(),
      McpServerProbe(),
    ).create(session, userId: account.userId, request: request);
    await SyncWakeups.publishWorkspace(session, request.workspaceId);
    return result;
  }

  Future<void> delete(
    Session session,
    DeleteMcpServerRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    await McpServerUseCases(
      McpServerRepository(),
      McpServerProbe(),
    ).delete(session, userId: account.userId, request: request);
    await SyncWakeups.publishWorkspace(session, request.workspaceId);
  }

  Future<DiscoverMcpServerResult> discoverAndCheck(
    Session session,
    DiscoverMcpServerRequest request,
  ) async {
    final account = await const AuthenticatedAccountResolver()(session);
    return McpServerUseCases(
      McpServerRepository(),
      McpServerProbe(),
    ).discoverAndCheck(session, userId: account.userId, request: request);
  }
}
