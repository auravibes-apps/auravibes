import 'dart:convert';

import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Display-only metadata supplied by an MCP server.
class McpToolDisplayMetadata {
  const McpToolDisplayMetadata({this.title, this.annotations});

  final String? title;
  final Map<String, Object?>? annotations;

  factory McpToolDisplayMetadata.fromWorkspaceTool(WorkspaceToolEntity tool) =>
      McpToolDisplayMetadata(
        title: McpDiscoveryPolicy.displayTitle(tool.title),
        annotations: _annotationsFromJson(tool.annotationsJson),
      );
}

Map<String, Object?>? _annotationsFromJson(String? encoded) {
  if (encoded == null) return null;
  try {
    return McpDiscoveryPolicy.supportedAnnotations(jsonDecode(encoded));
  } on FormatException {
    return null;
  }
}
