import 'package:auravibes_app/services/mcp_service/mcp_app_tool_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the declared UI resource from MCP tool metadata', () {
    final metadata = McpAppToolMetadata.parse({
      'ui': {'resourceUri': 'ui://weather/forecast'},
    });

    expect(metadata.resourceUri, 'ui://weather/forecast');
    expect(McpAppToolMetadata.isVisibleToApp(metadata), isTrue);
    expect(McpAppToolMetadata.isVisibleToModel(metadata), isTrue);
  });

  test('reads the legacy UI resource metadata key', () {
    final metadata = McpAppToolMetadata.parse({
      'ui/resourceUri': 'ui://weather/forecast',
    });

    expect(metadata.resourceUri, 'ui://weather/forecast');
  });

  test('keeps app-only tools out of model tool specs', () {
    final metadata = McpAppToolMetadata.parse({
      'ui': {
        'resourceUri': 'ui://weather/forecast',
        'visibility': ['app'],
      },
    });

    expect(McpAppToolMetadata.isVisibleToApp(metadata), isTrue);
    expect(McpAppToolMetadata.isVisibleToModel(metadata), isFalse);
  });

  test('rejects malformed visibility and non-ui resource URIs', () {
    final metadata = McpAppToolMetadata.parse({
      'ui': {'resourceUri': 'https://example.com/app', 'visibility': 'app'},
    });

    expect(metadata.resourceUri, isNull);
    expect(McpAppToolMetadata.isVisibleToApp(metadata), isFalse);
    expect(McpAppToolMetadata.isVisibleToModel(metadata), isFalse);
  });
}
