import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/service_connections/models/mcp_connection_test_status.dart';

export 'package:auravibes_app/features/service_connections/models/mcp_connection_test_status.dart';

typedef McpConnectionTestResult = ({
  McpConnectionTestStatus status,
  DateTime testedAt,
  McpTransportType? transport,
  int toolCount,
  int durationMilliseconds,
  String? errorDetails,
});
