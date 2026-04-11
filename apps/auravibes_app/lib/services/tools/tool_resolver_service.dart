import 'package:auravibes_app/notifiers/mcp_connection_notifier.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/services/tools/native_tool_entity.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';

class _BuiltInToolIdComponents {
  const _BuiltInToolIdComponents({
    required this.tableId,
    required this.toolIdentifier,
  });

  final String tableId;
  final String toolIdentifier;
}

class _NativeToolIdComponents {
  const _NativeToolIdComponents({
    required this.tableId,
    required this.toolIdentifier,
  });

  final String tableId;
  final String toolIdentifier;
}

class ToolResolverService {
  // ============================================================
  // Helper: Tool resolution
  // ============================================================

  /// Resolves a composite tool name to its implementation.
  ///
  /// Composite tool name formats:
  /// - Built-in: `built_in_<table_id>_<tool_identifier>`
  /// - MCP: `mcp_<mcp_id>_<slug_name>_<tool_identifier>`
  /// - Native: `native_<table_id>_<tool_identifier>`
  ///
  /// Note: Tool names must match pattern ^[a-zA-Z0-9_-]{1,128}$
  /// so we use underscores as separators instead of colons.
  ///
  /// Returns the resolved tool and null failureStatus, or null tool with
  /// failureStatus.

  ResolvedTool? resolveTool(String compositeToolName) {
    final components = McpToolIdComponents.fromComposite(
      compositeToolName,
    );
    if (components != null) {
      return ResolvedTool.mcp(
        tableId: components.mcpServerId, // MCP server ID serves as table ID
        toolIdentifier: components.toolIdentifier,
        mcpServerId: components.mcpServerId,
      );
    }

    final builtInTool = _parseBuiltInToolId(compositeToolName);

    if (builtInTool != null) {
      final toolType = UserToolType.fromValue(builtInTool.toolIdentifier);
      if (toolType != null) {
        return ResolvedTool.builtIn(
          tableId: builtInTool.tableId,
          toolIdentifier: builtInTool.toolIdentifier,
          tooltype: toolType,
        );
      }
    }

    final nativeTool = _parseNativeToolId(compositeToolName);
    if (nativeTool != null) {
      final toolType = NativeToolType.fromValue(nativeTool.toolIdentifier);
      if (toolType != null) {
        return ResolvedTool.native(
          tableId: nativeTool.tableId,
          toolIdentifier: nativeTool.toolIdentifier,
          nativeToolType: toolType,
        );
      }
    }

    return null;
  }

  /// Parses a built-in tool composite ID.
  ///
  /// Format: `built_in_<table_id>_<tool_identifier>`
  /// Returns null if the format is invalid.
  ///
  /// Note: Tool names must match pattern ^[a-zA-Z0-9_-]{1,128}$
  /// so we use underscores as separators instead of colons.
  static _BuiltInToolIdComponents? _parseBuiltInToolId(String compositeId) {
    if (!compositeId.startsWith('built_in_')) {
      return null;
    }

    // Remove 'built_in_' prefix
    final withoutPrefix = compositeId.substring(9);

    // Parse format: <table_id>_<tool_identifier>
    final firstUnderscoreIdx = withoutPrefix.indexOf('_');
    if (firstUnderscoreIdx <= 0) {
      return null;
    }

    final tableId = withoutPrefix.substring(0, firstUnderscoreIdx);
    final toolIdentifier = withoutPrefix.substring(firstUnderscoreIdx + 1);

    if (tableId.isEmpty || toolIdentifier.isEmpty) {
      return null;
    }

    return _BuiltInToolIdComponents(
      tableId: tableId,
      toolIdentifier: toolIdentifier,
    );
  }

  static _NativeToolIdComponents? _parseNativeToolId(String compositeId) {
    if (!compositeId.startsWith('native_')) {
      return null;
    }

    final withoutPrefix = compositeId.substring(7);
    final firstUnderscoreIdx = withoutPrefix.indexOf('_');
    if (firstUnderscoreIdx <= 0) {
      return null;
    }

    final tableId = withoutPrefix.substring(0, firstUnderscoreIdx);
    final toolIdentifier = withoutPrefix.substring(firstUnderscoreIdx + 1);

    if (tableId.isEmpty || toolIdentifier.isEmpty) {
      return null;
    }

    return _NativeToolIdComponents(
      tableId: tableId,
      toolIdentifier: toolIdentifier,
    );
  }
}
