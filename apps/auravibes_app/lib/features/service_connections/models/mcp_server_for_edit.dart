import 'package:auravibes_app/domain/entities/mcp_server_settings_update.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';

export 'package:auravibes_app/domain/entities/mcp_server_settings_update.dart';

typedef McpServerForEdit = ({
  String id,
  String name,
  String url,
  McpTransportType transport,
  McpServerAuthMode authMode,
  bool hasSecret,
  int? revision,
  int? secretRevision,
});
