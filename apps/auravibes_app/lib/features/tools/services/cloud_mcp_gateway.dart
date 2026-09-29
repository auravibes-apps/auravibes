import 'dart:convert';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_workspace_state_gateway.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:uuid/v7.dart';

class const CloudMcpGateway(final CloudWorkspaceStateGateway _stateGateway) {
  Future<VerifyMcpServerResult> verifyCatalogMcpServer(
    McpServerFormToCreate server,
  ) => CloudAppErrors.guardCall(
    .mcp,
    () => _stateGateway.client.mcpServer.verify(
      VerifyMcpServerRequest(
        workspaceId: _stateGateway.workspace.cloudWorkspaceId,
        requestId: const UuidV7().generate(),
        url: server.url.trim(),
        transport: server.transport.toJson()['type']! as String,
        useHttp2: false,
        bearerToken: server.bearerToken,
        httpHeadersJson: server.httpHeaders == null
            ? null
            : jsonEncode(server.httpHeaders),
      ),
    ),
  );

  Future<CreateMcpServerResult> createCatalogMcpServer(
    McpServerFormToCreate server, {
    required String requestId,
    required String verificationReceipt,
  }) => CloudAppErrors.guardCall(
    .mcp,
    () => _stateGateway.client.mcpServer.create(
      CreateMcpServerRequest(
        workspaceId: _stateGateway.workspace.cloudWorkspaceId,
        requestId: requestId,
        name: server.name.trim(),
        url: server.url.trim(),
        transport: server.transport.toJson()['type']! as String,
        useHttp2: false,
        description: server.description?.trim(),
        bearerToken: server.bearerToken,
        httpHeadersJson: server.httpHeaders == null
            ? null
            : jsonEncode(server.httpHeaders),
        catalogListingId: _snapshotField(server, 'id'),
        catalogOptionKey: _snapshotOptionKey(server),
        verificationReceipt: verificationReceipt,
      ),
    ),
  );

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

String? _snapshotField(McpServerFormToCreate server, String key) {
  final raw = server.catalogSnapshotJson;
  if (raw == null) return null;
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return decoded[key] as String?;
}

String? _snapshotOptionKey(McpServerFormToCreate server) {
  final raw = server.catalogSnapshotJson;
  if (raw == null) return null;
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return (decoded['option'] as Map<String, dynamic>)['key'] as String?;
}
