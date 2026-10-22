part of 'service_connection_operations_provider.dart';

class const ServiceConnectionOperations({
  required final Future<void> Function({
    required String workspaceId,
    required String connectorId,
    required String name,
    required String apiKey,
  })
  createConnectorConnection,
  required final Future<GenericServiceConnectionForEdit?> Function(String id)
  getGenericForEdit,
  required final Future<void> Function(
    GenericServiceConnectionForEdit connection,
    GenericServiceConnectionUpdate update,
  )
  updateGeneric,
  final Future<McpServerForEdit?> Function(String id)? getMcpForEdit,
  final Future<void> Function(
    McpServerForEdit server,
    McpServerSettingsUpdate update,
  )?
  updateMcp,
});
