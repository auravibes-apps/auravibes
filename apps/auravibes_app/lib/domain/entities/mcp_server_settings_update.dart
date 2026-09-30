import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';

class const McpServerSettingsUpdate({
  required final String serverId,
  required final String name,
  required final String url,
  required final McpTransportType transport,
  required final McpServerAuthMode authMode,
  required final McpServerSecretChange secretChange,
  required final String? secret,
  final int? expectedRevision,
  final int? expectedSecretRevision,
}) {
  McpServerSettingsUpdate withExpectedRevisions(
    int? revision,
    int? secretRevision,
  ) => McpServerSettingsUpdate(
    serverId: serverId,
    name: name,
    url: url,
    transport: transport,
    authMode: authMode,
    secretChange: secretChange,
    secret: secret,
    expectedRevision: revision,
    expectedSecretRevision: secretRevision,
  );
}

enum McpServerAuthMode { none, bearerToken, httpHeaders, oauth }

enum McpServerSecretChange { preserve, replace, clear }
