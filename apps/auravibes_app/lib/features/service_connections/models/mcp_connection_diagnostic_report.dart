import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/service_connections/models/mcp_connection_test_result.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';

typedef McpDiagnosticLabels = ({
  String transport,
  String category,
  String attemptedAt,
  String appVersion,
  String summary,
  String unavailable,
});

class const McpConnectionDiagnosticReport({
  required final McpTransportType? transport,
  required final McpConnectionTestStatus status,
  required final DateTime? attemptedAt,
}) {
  factory fromTest(McpConnectionTestResult result) =>
      McpConnectionDiagnosticReport(
        transport: result.transport,
        status: result.status,
        attemptedAt: result.testedAt,
      );

  factory fromStored(ServiceConnectionListItem connection) =>
      McpConnectionDiagnosticReport(
        transport: connection.transport,
        status: connection.displayStatus == .needsReauth
            ? .authentication
            : .unknown,
        attemptedAt: null,
      );

  String format({
    required String appVersion,
    required String localizedSummary,
    required McpDiagnosticLabels labels,
  }) {
    final time = attemptedAt?.toUtc().toIso8601String() ?? labels.unavailable;

    return [
      '${labels.transport}: ${_transportName(labels.unavailable)}',
      '${labels.category}: ${status.name}',
      '${labels.attemptedAt}: $time',
      '${labels.appVersion}: $appVersion',
      '${labels.summary}: $localizedSummary',
    ].join('\n');
  }

  String _transportName(String unavailable) => switch (transport) {
    McpTransportTypeSSE() => 'sse',
    McpTransportTypeStreamableHttp() => 'streamableHttp',
    null => unavailable,
  };
}
