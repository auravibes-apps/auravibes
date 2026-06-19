import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolNameFormatter.parse', () {
    group('MCP tools', () {
      test('parses valid mcp_ prefix', () {
        final result = ToolNameFormatter.parse('mcp_42_my-server_read_file');
        expect(result, isA<McpParsedToolId>());
        final mcp = result as McpParsedToolId;
        expect(mcp.mcpServerId, '42');
        expect(mcp.slugName, 'my-server');
        expect(mcp.toolIdentifier, 'read_file');
      });

      test('parses mcp with single-char id', () {
        final result = ToolNameFormatter.parse('mcp_1_slug_tool');
        expect(result, isA<McpParsedToolId>());
        final mcp = result as McpParsedToolId;
        expect(mcp.mcpServerId, '1');
        expect(mcp.slugName, 'slug');
        expect(mcp.toolIdentifier, 'tool');
      });

      test('falls back to unknown for mcp_ with only one separator', () {
        final result = ToolNameFormatter.parse('mcp_42_noseparator');
        expect(result, isA<UnknownParsedToolId>());
        final unknown = result as UnknownParsedToolId;
        expect(unknown.rawName, 'mcp_42_noseparator');
      });
    });

    group('Built-in tools', () {
      test('parses valid built_in_ prefix', () {
        final result = ToolNameFormatter.parse('built_in_tool_456_calculator');
        expect(result, isA<BuiltInParsedToolId>());
        final builtIn = result as BuiltInParsedToolId;
        expect(builtIn.tableId, 'tool');
        expect(builtIn.toolIdentifier, '456_calculator');
      });

      test('falls back to unknown for incomplete built_in_ format', () {
        final result = ToolNameFormatter.parse('built_in_only');
        expect(result, isA<UnknownParsedToolId>());
      });
    });

    group('Native tools', () {
      test('parses valid native_ prefix', () {
        final result = ToolNameFormatter.parse('native_tool_789_url_tool');
        expect(result, isA<NativeParsedToolId>());
        final native = result as NativeParsedToolId;
        expect(native.tableId, 'tool');
        expect(native.toolIdentifier, '789_url_tool');
      });

      test('falls back to unknown for incomplete native_ format', () {
        final result = ToolNameFormatter.parse('native_only');
        expect(result, isA<UnknownParsedToolId>());
      });
    });

    group('Unknown format', () {
      test('returns unknown for unrecognized prefix', () {
        final result = ToolNameFormatter.parse('random_string');
        expect(result, isA<UnknownParsedToolId>());
        final unknown = result as UnknownParsedToolId;
        expect(unknown.rawName, 'random_string');
      });

      test('returns unknown for empty string', () {
        final result = ToolNameFormatter.parse('');
        expect(result, isA<UnknownParsedToolId>());
      });
    });

    group('mcpServerId getter', () {
      test('returns serverId for MCP tools', () {
        final result = ToolNameFormatter.parse('mcp_42_s_tool');
        expect(result.mcpServerId, '42');
      });

      test('returns null for built-in tools', () {
        final result = ToolNameFormatter.parse('built_in_456_calculator');
        expect(result.mcpServerId, isNull);
      });

      test('returns null for native tools', () {
        final result = ToolNameFormatter.parse('native_789_url_tool');
        expect(result.mcpServerId, isNull);
      });

      test('returns null for unknown', () {
        final result = ToolNameFormatter.parse('random');
        expect(result.mcpServerId, isNull);
      });
    });
  });

  group('ToolNameFormatter.formatDisplayName', () {
    test('formats MCP display name with server name override', () {
      final parsed = ToolNameFormatter.parse('mcp_42_s_read_file');
      final result = ToolNameFormatter.formatDisplayName(
        parsed,
        mcpServerName: 'My Server',
      );
      expect(result, 'My Server: Read File');
    });

    test('formats MCP display name without override uses slug', () {
      final parsed = ToolNameFormatter.parse('mcp_42_my-server_read_file');
      final result = ToolNameFormatter.formatDisplayName(parsed);
      expect(result, 'My Server: Read File');
    });

    test('formats built-in display name', () {
      final parsed = ToolNameFormatter.parse('built_in_456_url_tool');
      final result = ToolNameFormatter.formatDisplayName(parsed);
      expect(result, 'Url Tool');
    });

    test('formats native display name', () {
      final parsed = ToolNameFormatter.parse('native_789_my_tool');
      final result = ToolNameFormatter.formatDisplayName(parsed);
      expect(result, 'My Tool');
    });

    test('formats unknown display name', () {
      final parsed = ToolNameFormatter.parse('raw_name');
      final result = ToolNameFormatter.formatDisplayName(parsed);
      expect(result, 'Raw Name');
    });
  });
}
