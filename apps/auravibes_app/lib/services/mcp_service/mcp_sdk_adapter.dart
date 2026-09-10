import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

abstract final class McpSdkAdapter {
  static McpToolResult toolResult(mcp.CallToolResult result) => McpToolResult(
    content: result.content.map(_contentFromSdk).toList(),
    structuredContent: result.structuredContent,
    isError: result.isError,
  );

  static McpContent _contentFromSdk(mcp.Content content) => switch (content) {
    mcp.TextContent value => _textContent(value),
    mcp.ImageContent value => _imageContent(value),
    mcp.AudioContent value => _audioContent(value),
    mcp.ResourceContent value => _resourceContent(value),
    mcp.ResourceLinkContent value => _resourceLinkContent(value),
    _ => throw UnsupportedError(
      'Unsupported MCP content: ${content.runtimeType}',
    ),
  };
}

McpTextContent _textContent(mcp.TextContent content) =>
    McpTextContent(content.text, annotations: content.annotations);

McpBinaryContent _imageContent(mcp.ImageContent content) => McpBinaryContent(
  type: 'image',
  mimeType: content.mimeType,
  data: content.data,
  url: content.url,
  annotations: content.annotations,
);

McpBinaryContent _audioContent(mcp.AudioContent content) => McpBinaryContent(
  type: 'audio',
  mimeType: content.mimeType,
  data: content.data,
  annotations: content.annotations,
);

McpResourceContent _resourceContent(mcp.ResourceContent content) =>
    McpResourceContent(
      uri: content.uri,
      text: content.text,
      blob: content.blob,
      mimeType: content.mimeType,
      annotations: content.annotations,
    );

McpResourceContent _resourceLinkContent(mcp.ResourceLinkContent content) =>
    McpResourceContent(
      uri: content.uri,
      mimeType: content.mimeType,
      name: content.name,
      description: content.description,
      isLink: true,
      annotations: content.annotations,
      meta: content.meta,
    );
