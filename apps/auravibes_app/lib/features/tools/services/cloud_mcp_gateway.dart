import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';

class const CloudMcpGateway(final CloudWorkspaceStateGateway _stateGateway) {
  Future<VerifyMcpServerResult> verifyMcpServer(
    ({
      String requestId,
      String url,
      String transport,
      bool useHttp2,
      String? bearerToken,
    })
    request,
  ) => CloudAppErrors.guardCall(
    .mcp,
    () => _stateGateway.client.mcpServer.verify(_verifyRequest(request)),
  );

  Future<CreateMcpServerResult> createMcpServer(
    ({
      String requestId,
      String name,
      String url,
      String transport,
      bool useHttp2,
      String? description,
      String? bearerToken,
      String? verificationReceipt,
    })
    request,
  ) => CloudAppErrors.guardCall(
    .mcp,
    () =>
        _stateGateway.client.mcpServer.create(_createMcpServerRequest(request)),
  );

  Future<void> deleteMcpServer({required String mcpServerId}) =>
      CloudAppErrors.guardCall(
        .mcp,
        () => _stateGateway.client.mcpServer.delete(
          .new(
            workspaceId: _stateGateway.workspace.cloudWorkspaceId,
            mcpServerId: mcpServerId,
          ),
        ),
      );

  Future<DiscoverMcpServerResult> discoverMcpServer({
    required String mcpServerId,
  }) => CloudAppErrors.guardCall(
    .mcp,
    () => _stateGateway.client.mcpServer.discoverAndCheck(
      .new(
        workspaceId: _stateGateway.workspace.cloudWorkspaceId,
        mcpServerId: mcpServerId,
      ),
    ),
  );

  CreateMcpServerRequest _createMcpServerRequest(
    ({
      String requestId,
      String name,
      String url,
      String transport,
      bool useHttp2,
      String? description,
      String? bearerToken,
      String? verificationReceipt,
    })
    request,
  ) => CreateMcpServerRequest(
    workspaceId: _stateGateway.workspace.cloudWorkspaceId,
    requestId: request.requestId,
    name: request.name,
    url: request.url,
    transport: request.transport,
    useHttp2: request.useHttp2,
    description: request.description,
    bearerToken: request.bearerToken,
    verificationReceipt: request.verificationReceipt,
  );

  VerifyMcpServerRequest _verifyRequest(
    ({
      String requestId,
      String url,
      String transport,
      bool useHttp2,
      String? bearerToken,
    })
    request,
  ) => VerifyMcpServerRequest(
    workspaceId: _stateGateway.workspace.cloudWorkspaceId,
    requestId: request.requestId,
    url: request.url,
    transport: request.transport,
    useHttp2: request.useHttp2,
    bearerToken: request.bearerToken,
  );
}
