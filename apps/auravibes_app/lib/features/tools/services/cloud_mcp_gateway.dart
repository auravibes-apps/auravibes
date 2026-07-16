import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class CloudMcpGateway {
  const CloudMcpGateway(this._stateGateway);

  final CloudWorkspaceStateGateway _stateGateway;

  Future<CreateMcpServerResult> createMcpServer({
    required String requestId,
    required String name,
    required String url,
    required String transport,
    required bool useHttp2,
    required String? description,
    required String? bearerToken,
  }) => guardCloudCall(
    .mcp,
    () => _stateGateway.client.mcpServer.create(
      CreateMcpServerRequest(
        workspaceId: _stateGateway.workspace.cloudWorkspaceId,
        requestId: requestId,
        name: name,
        url: url,
        transport: transport,
        useHttp2: useHttp2,
        description: description,
        bearerToken: bearerToken,
      ),
    ),
  );

  Future<void> deleteMcpServer({required String mcpServerId}) => guardCloudCall(
    .mcp,
    () => _stateGateway.client.mcpServer.delete(
      DeleteMcpServerRequest(
        workspaceId: _stateGateway.workspace.cloudWorkspaceId,
        mcpServerId: mcpServerId,
      ),
    ),
  );

  Future<DiscoverMcpServerResult> discoverMcpServer({
    required String mcpServerId,
  }) => guardCloudCall(
    .mcp,
    () => _stateGateway.client.mcpServer.discoverAndCheck(
      DiscoverMcpServerRequest(
        workspaceId: _stateGateway.workspace.cloudWorkspaceId,
        mcpServerId: mcpServerId,
      ),
    ),
  );
}
