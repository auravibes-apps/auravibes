import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/service_connections/models/mcp_catalog_installation.dart';
import 'package:auravibes_app/notifiers/mcp_connection_status.dart';

class const InstallMcpCatalogEntryUseCase({
  required final Future<McpConnectionVerification> Function(
    McpServerFormToCreate,
    String,
  )
  prepare,
  required final Future<void> Function(McpServerFormToCreate, String, String)
  commit,
}) {
  Future<McpConnectionVerification> verify(McpCatalogInstallation request) =>
      prepare(request.toForm(), request.workspaceId);

  Future<void> install(McpCatalogInstallation request, String verificationId) =>
      commit(request.toForm(), request.workspaceId, verificationId);
}
