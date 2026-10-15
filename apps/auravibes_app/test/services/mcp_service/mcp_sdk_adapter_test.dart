import 'package:auravibes_app/services/mcp_service/mcp_sdk_adapter.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

void main() {
  test('maps every SDK result variant', () {
    final result = McpSdkAdapter.toolResult(
      .new(
        content: [
          mcp.TextContent(annotations: .new(priority: 0.7), text: 'text'),
          mcp.ImageContent(
            annotations: .new(priority: 0.7),
            data: 'AA==',
            mimeType: 'image/png',
          ),
          mcp.AudioContent(data: 'AQ==', mimeType: 'audio/wav'),
          mcp.EmbeddedResource(
            resource: mcp.TextResourceContents(
              text: 'resource',
              uri: 'file:///a',
            ),
          ),
          mcp.ResourceLink(
            meta: {'x': true},
            name: 'Example',
            uri: 'https://example.test',
          ),
        ],
        isError: true,
        structuredContent: {'ok': true},
      ),
    );

    final [text, image, _, resource, resourceLink] = result.content;
    final typedText = text as McpTextContent;
    final typedImage = image as McpBinaryContent;
    final typedResource = resource as McpResourceContent;
    final typedResourceLink = resourceLink as McpResourceContent;

    expect(result.content, [
      isA<McpTextContent>(),
      isA<McpBinaryContent>(),
      isA<McpBinaryContent>(),
      isA<McpResourceContent>(),
      isA<McpResourceContent>(),
    ]);
    expect(typedText.annotations, {'priority': 0.7});
    expect(typedImage.data, 'AA==');
    expect(typedImage.mimeType, 'image/png');
    expect(typedImage.url, isNull);
    expect(typedResource.uri, 'file:///a');
    expect(typedResource.text, 'resource');
    expect(typedResource.isLink, isFalse);
    expect(typedResourceLink.uri, 'https://example.test');
    expect(typedResourceLink.name, 'Example');
    expect(typedResourceLink.isLink, isTrue);
    expect(typedResourceLink.meta, {'x': true});
    expect(result.structuredContent, {'ok': true});
    expect(result.isError, isTrue);
  });

  test('preserves array structured content', () {
    final result = McpSdkAdapter.toolResult(
      .new(
        content: [mcp.TextContent(text: 'ok')],
        structuredContent: ['ok', 2],
      ),
    );

    expect(result.structuredContent, ['ok', 2]);
  });

  test('throws on unknown SDK content block', () {
    expect(
      () => McpSdkAdapter.toolResult(
        .new(
          content: [
            mcp.UnknownContentBlock.fromJson({'type': 'future'}),
          ],
        ),
      ),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          'Unsupported MCP content: UnknownContentBlock',
        ),
      ),
    );
  });

  test('maps blob-backed embedded resources', () {
    final result = McpSdkAdapter.toolResult(
      .new(
        content: [
          mcp.EmbeddedResource(
            resource: mcp.BlobResourceContents(
              blob: 'AQID',
              mimeType: 'application/octet-stream',
              uri: 'file:///blob',
            ),
          ),
        ],
      ),
    );

    final resource = result.content.single as McpResourceContent;
    expect(resource.uri, 'file:///blob');
    expect(resource.blob, 'AQID');
    expect(resource.mimeType, 'application/octet-stream');
    expect(resource.text, isNull);
    expect(resource.isLink, isFalse);
  });
}
