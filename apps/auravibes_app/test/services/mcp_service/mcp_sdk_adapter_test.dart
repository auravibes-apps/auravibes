import 'package:auravibes_app/services/mcp_service/mcp_sdk_adapter.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

void main() {
  test('maps every SDK result variant', () {
    final result = McpSdkAdapter.toolResult(
      mcp.CallToolResult(
        content: [
          mcp.TextContent(
            text: 'text',
            annotations: mcp.Annotations(priority: 0.7),
          ),
          mcp.ImageContent(
            data: 'AA==',
            mimeType: 'image/png',
            annotations: mcp.Annotations(priority: 0.7),
          ),
          mcp.AudioContent(data: 'AQ==', mimeType: 'audio/wav'),
          mcp.ResourceContent(uri: 'file:///a', text: 'resource'),
          mcp.ResourceLinkContent(
            uri: 'https://example.test',
            name: 'Example',
            meta: {'x': true},
          ),
        ],
        structuredContent: {'ok': true},
        isError: true,
      ),
    );

    final text = result.content[0] as McpTextContent;
    final image = result.content[1] as McpBinaryContent;

    expect(result.content, [
      isA<McpTextContent>(),
      isA<McpBinaryContent>(),
      isA<McpBinaryContent>(),
      isA<McpResourceContent>(),
      isA<McpResourceContent>(),
    ]);
    expect(text.annotations, {'priority': 0.7});
    expect(image.data, 'AA==');
    expect(image.mimeType, 'image/png');
    expect(image.url, isNull);
    expect(result.structuredContent, {'ok': true});
    expect(result.isError, isTrue);
  });

  test('preserves array structured content', () {
    final result = McpSdkAdapter.toolResult(
      mcp.CallToolResult(
        content: [mcp.TextContent(text: 'ok')],
        structuredContent: ['ok', 2],
      ),
    );

    expect(result.structuredContent, ['ok', 2]);
  });
}
