import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolNameFormatter.formatDisplayName', () {
    test('formats MCP display name with server name override', () {
      final parsed = ToolNameFormatter.parse('mcp_42_s_read_file');

      expect(
        ToolNameFormatter.formatDisplayName(
          parsed,
          mcpServerName: 'My Server',
        ),
        'My Server: Read File',
      );
    });

    test('formats MCP display name without override using slug', () {
      final parsed = ToolNameFormatter.parse('mcp_42_my-server_read_file');

      expect(
        ToolNameFormatter.formatDisplayName(parsed),
        'My Server: Read File',
      );
    });

    test('formats built-in and native display names', () {
      final builtIn = ToolNameFormatter.parse('built_in_456_url_tool');
      final native = ToolNameFormatter.parse('native_789_my_tool');

      expect(ToolNameFormatter.formatDisplayName(builtIn), 'Url Tool');
      expect(ToolNameFormatter.formatDisplayName(native), 'My Tool');
    });

    test('formats unknown display name', () {
      expect(
        ToolNameFormatter.formatDisplayName(null, rawName: 'raw_name'),
        'Raw Name',
      );
    });

    test('formats skill display name', () {
      final parsed = ToolNameFormatter.parse(
        'skill__user__research_tools__search_web',
      );

      expect(
        ToolNameFormatter.formatDisplayName(parsed),
        'Research Tools: Search Web',
      );
    });
  });
}
