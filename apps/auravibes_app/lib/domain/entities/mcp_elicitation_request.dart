import 'package:auravibes_app/domain/entities/mcp_elicitation_mode.dart';

export 'package:auravibes_app/domain/entities/mcp_elicitation_mode.dart'
    show McpElicitationAction, McpElicitationMode;

final class const McpElicitationRequest({
  required final String serverName,
  required final String message,
  required final McpElicitationMode mode,
  final Map<String, Object?>? requestedSchema,
  final String? url,
}) {
  Uri? parseExternalUri() {
    final value = url;
    if (value == null) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }

    return uri;
  }
}

final class const McpElicitationResponse({
  required final McpElicitationAction action,
  final Map<String, Object?>? content,
});

typedef McpElicitationHandler = Future<McpElicitationResponse> Function(
  McpElicitationRequest request,
);

typedef McpElicitationRequester = Future<McpElicitationResponse> Function(
  String conversationId,
  McpElicitationRequest request,
);
