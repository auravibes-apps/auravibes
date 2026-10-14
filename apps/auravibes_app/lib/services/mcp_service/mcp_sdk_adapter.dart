import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

abstract final class McpSdkAdapter {
  static McpToolResult toolResult(mcp.CallToolResult result) => McpToolResult(
    content: result.content.map(_contentFromSdk).toList(),
    structuredContent: result.structuredContent,
    isError: result.isError,
  );

  static McpContent _contentFromSdk(mcp.ContentBlock content) =>
      switch (content) {
        final mcp.TextContent value => _textContent(value),
        final mcp.ImageContent value => _imageContent(value),
        final mcp.AudioContent value => _audioContent(value),
        final mcp.EmbeddedResource value => _resourceContent(value),
        final mcp.ResourceLink value => _resourceLinkContent(value),
        final mcp.UnknownContentBlock value => throw UnsupportedError(
          'Unsupported MCP content: ${value.runtimeType}',
        ),
      };
}

McpTextContent _textContent(mcp.TextContent content) => McpTextContent(
  content.text,
  annotations: _annotationsFromSdk(content.annotations),
);

McpBinaryContent _imageContent(mcp.ImageContent content) => McpBinaryContent(
  type: 'image',
  mimeType: content.mimeType,
  data: content.data,
  annotations: _annotationsFromSdk(content.annotations),
);

McpBinaryContent _audioContent(mcp.AudioContent content) => McpBinaryContent(
  type: 'audio',
  mimeType: content.mimeType,
  data: content.data,
  annotations: _annotationsFromSdk(content.annotations),
);

McpResourceContent _resourceContent(mcp.EmbeddedResource content) {
  final resource = content.resource;

  return McpResourceContent(
    uri: resource.uri,
    text: resource.text,
    blob: resource.blob,
    mimeType: resource.mimeType,
    annotations: _annotationsFromSdk(content.annotations),
  );
}

McpResourceContent _resourceLinkContent(mcp.ResourceLink content) =>
    McpResourceContent(
      uri: content.uri,
      mimeType: content.mimeType,
      name: content.name,
      description: content.description,
      isLink: true,
      annotations: _annotationsFromSdk(content.annotations),
      meta: content.meta,
    );

Map<String, Object?>? _annotationsFromSdk(mcp.Annotations? annotations) =>
    annotations?.toJson();
