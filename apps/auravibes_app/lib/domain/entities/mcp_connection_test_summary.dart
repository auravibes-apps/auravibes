import 'dart:convert';

import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';

/// Normalized MCP self-test fields safe to persist with server configuration.
class const McpConnectionTestSummary({
  required final String status,
  required final DateTime testedAt,
  required final McpTransportType transport,
  required final int toolCount,
  required final int durationMilliseconds,
}) {
  String toJson() => jsonEncode({
    'status': status,
    'testedAt': testedAt.toUtc().toIso8601String(),
    'transport': transport.toJson(),
    'toolCount': toolCount,
    'durationMilliseconds': durationMilliseconds,
  });

  static McpConnectionTestSummary? fromJson(String? raw) {
    if (raw == null) return null;
    try {
      return _decodeSummary(jsonDecode(raw));
    } on Object {
      return null;
    }
  }
}

typedef _McpTestSummaryFields = ({
  String status,
  DateTime testedAt,
  McpTransportType transport,
  int toolCount,
  int durationMilliseconds,
});

McpConnectionTestSummary? _decodeSummary(Object? value) {
  final fields = _decodeSummaryFields(value);
  if (fields == null) return null;

  return McpConnectionTestSummary(
    status: fields.status,
    testedAt: fields.testedAt,
    transport: fields.transport,
    toolCount: fields.toolCount,
    durationMilliseconds: fields.durationMilliseconds,
  );
}

_McpTestSummaryFields? _decodeSummaryFields(Object? value) {
  if (value is! Map<String, dynamic>) return null;

  return _decodeSummaryMap(value);
}

_McpTestSummaryFields? _decodeSummaryMap(Map<String, dynamic> value) {
  final identity = _summaryIdentity(value);
  if (identity == null) return null;

  final transport = _summaryTransport(value['transport']);
  if (transport == null) return null;
  final metrics = _summaryMetrics(value);
  if (metrics == null) return null;

  return (
    status: identity.status,
    testedAt: identity.testedAt,
    transport: transport,
    toolCount: metrics.toolCount,
    durationMilliseconds: metrics.durationMilliseconds,
  );
}

({String status, DateTime testedAt})? _summaryIdentity(
  Map<String, dynamic> value,
) {
  final status = _summaryStatus(value['status']);
  final testedAt = _summaryTestedAt(value['testedAt']);
  if (status == null || testedAt == null) return null;

  return (status: status, testedAt: testedAt);
}

({int toolCount, int durationMilliseconds})? _summaryMetrics(
  Map<String, dynamic> value,
) {
  final toolCount = _nonNegativeInteger(value['toolCount']);
  final durationMilliseconds = _nonNegativeInteger(
    value['durationMilliseconds'],
  );
  if (toolCount == null || durationMilliseconds == null) return null;

  return (toolCount: toolCount, durationMilliseconds: durationMilliseconds);
}

String? _summaryStatus(Object? value) =>
    value is String && _statuses.contains(value) ? value : null;

DateTime? _summaryTestedAt(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

McpTransportType? _summaryTransport(Object? value) =>
    value is Map ? .fromJson(Map<String, dynamic>.from(value)) : null;

int? _nonNegativeInteger(Object? value) =>
    value is int && value >= 0 ? value : null;

const _statuses = {
  'success',
  'authentication',
  'network',
  'protocol',
  'unknown',
};
