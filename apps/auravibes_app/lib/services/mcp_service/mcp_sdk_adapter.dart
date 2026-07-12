import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

McpToolResult mcpToolResultFromSdk(mcp.CallToolResult result) => McpToolResult(
  content: result.content.map(_contentFromSdk).toList(),
  structuredContent: result.structuredContent,
  isStreaming: result.isStreaming,
  isError: result.isError,
);

McpContent _contentFromSdk(mcp.Content content) => switch (content) {
  mcp.TextContent(:final text, :final annotations) => McpTextContent(
    text,
    annotations: annotations,
  ),
  mcp.ImageContent(
    :final mimeType,
    :final data,
    :final url,
    :final annotations,
  ) =>
    McpBinaryContent(
      type: 'image',
      mimeType: mimeType,
      data: data,
      url: url,
      annotations: annotations,
    ),
  mcp.AudioContent(:final mimeType, :final data, :final annotations) =>
    McpBinaryContent(
      type: 'audio',
      mimeType: mimeType,
      data: data,
      annotations: annotations,
    ),
  mcp.ResourceContent(
    :final uri,
    :final text,
    :final blob,
    :final mimeType,
    :final annotations,
  ) =>
    McpResourceContent(
      uri: uri,
      text: text,
      blob: blob,
      mimeType: mimeType,
      annotations: annotations,
    ),
  mcp.ResourceLinkContent(
    :final uri,
    :final name,
    :final description,
    :final mimeType,
    :final annotations,
    :final meta,
  ) =>
    McpResourceContent(
      uri: uri,
      mimeType: mimeType,
      name: name,
      description: description,
      isLink: true,
      annotations: annotations,
      meta: meta,
    ),
  _ => throw UnsupportedError(
    'Unsupported MCP content: ${content.runtimeType}',
  ),
};
