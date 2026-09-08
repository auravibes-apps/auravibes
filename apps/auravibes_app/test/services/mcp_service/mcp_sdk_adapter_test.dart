import 'package:auravibes_app/services/mcp_service/mcp_sdk_adapter.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

void main() {
  test('maps every SDK result variant', () {
    final result = McpSdkAdapter.toolResult(
      const mcp.CallToolResult(
        [
          mcp.TextContent(text: 'text'),
          mcp.ImageContent(data: 'AA==', mimeType: 'image/png'),
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
    expect(result.content, [
      isA<McpTextContent>(),
      isA<McpBinaryContent>(),
      isA<McpBinaryContent>(),
      isA<McpResourceContent>(),
      isA<McpResourceContent>(),
    ]);
    expect(result.structuredContent, {'ok': true});
    expect(result.isError, isTrue);
  });

  test('drops SDK legacy streaming hint', () {
    final result = McpSdkAdapter.toolResult(
      const mcp.CallToolResult(
        [mcp.TextContent(text: 'legacy')],
        // ignore: deprecated_member_use - Verifies the legacy SDK hint is dropped.
        isStreaming: true,
      ),
    );

    expect(result.isStreaming, isFalse);
  });
}
