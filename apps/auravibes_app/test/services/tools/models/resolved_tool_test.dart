// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResolvedToolType', () {
    test('enum has three values', () {
      expect(ResolvedToolType.values.length, 3);
      expect(ResolvedToolType.values, contains(ResolvedToolType.builtIn));
      expect(ResolvedToolType.values, contains(ResolvedToolType.mcp));
      expect(ResolvedToolType.values, contains(ResolvedToolType.native));
    });
  });

  group('ResolvedTool.builtIn', () {
    test('creates built-in resolved tool', () {
      final tool = ResolvedTool.builtIn(
        tableId: 'tool_1',
        toolIdentifier: 'calculator',
        tooltype: UserToolType.calculator,
      );
      expect(tool.type, ResolvedToolType.builtIn);
      expect(tool.tableId, 'tool_1');
      expect(tool.toolIdentifier, 'calculator');
      expect(tool.builtInTool, UserToolType.calculator);
      expect(tool.mcpServerId, isNull);
      expect(tool.nativeTool, isNull);
    });

    test('isBuiltIn is true', () {
      final tool = ResolvedTool.builtIn(
        tableId: 'tool_1',
        toolIdentifier: 'calculator',
        tooltype: UserToolType.calculator,
      );
      expect(tool.isBuiltIn, isTrue);
      expect(tool.isMcp, isFalse);
      expect(tool.isNative, isFalse);
    });
  });

  group('ResolvedTool.mcp', () {
    test('creates MCP resolved tool', () {
      final tool = ResolvedTool.mcp(
        tableId: 'tool_2',
        toolIdentifier: 'read_file',
        mcpServerId: 'server_1',
      );
      expect(tool.type, ResolvedToolType.mcp);
      expect(tool.tableId, 'tool_2');
      expect(tool.toolIdentifier, 'read_file');
      expect(tool.mcpServerId, 'server_1');
      expect(tool.builtInTool, isNull);
      expect(tool.nativeTool, isNull);
    });

    test('isMcp is true', () {
      final tool = ResolvedTool.mcp(
        tableId: 'tool_2',
        toolIdentifier: 'read_file',
        mcpServerId: 'server_1',
      );
      expect(tool.isMcp, isTrue);
      expect(tool.isBuiltIn, isFalse);
      expect(tool.isNative, isFalse);
    });
  });

  group('ResolvedTool.native', () {
    test('creates native resolved tool', () {
      final tool = ResolvedTool.native(
        tableId: 'tool_3',
        nativeToolType: NativeToolType.url,
      );
      expect(tool.type, ResolvedToolType.native);
      expect(tool.tableId, 'tool_3');
      expect(tool.toolIdentifier, 'url');
      expect(tool.nativeTool, NativeToolType.url);
      expect(tool.builtInTool, isNull);
      expect(tool.mcpServerId, isNull);
    });

    test('isNative is true', () {
      final tool = ResolvedTool.native(
        tableId: 'tool_3',
        nativeToolType: NativeToolType.url,
      );
      expect(tool.isNative, isTrue);
      expect(tool.isBuiltIn, isFalse);
      expect(tool.isMcp, isFalse);
    });
  });
}
