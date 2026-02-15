import 'package:auravibes_app/providers/mcp_connection_controller.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';

/// Parsed components of a built-in tool composite ID.
///
/// The composite ID format is: `built_in_<table_id>_<tool_identifier>`
class _BuiltInToolIdComponents {
  const _BuiltInToolIdComponents({
    required this.tableId,
    required this.toolIdentifier,
  });

  /// The database table ID for permission checks
  final String tableId;

  /// The tool identifier (e.g., "calculator")
  final String toolIdentifier;
}

class ToolResolverUtil {
  // ============================================================
  // Helper: Tool resolution
  // ============================================================

  /// Resolves a composite tool name to its implementation.
  ///
  /// Composite tool name formats:
  /// - Built-in: `built_in_<table_id>_<tool_identifier>`
  /// - MCP: `mcp_<mcp_id>_<slug_name>_<tool_identifier>`
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

    final buildtInTool = _parseBuiltInToolId(compositeToolName);

    if (buildtInTool != null) {
      final toolType = UserToolType.fromValue(buildtInTool.toolIdentifier);
      if (toolType != null) {
        return ResolvedTool.builtIn(
          tableId: buildtInTool.tableId,
          toolIdentifier: buildtInTool.toolIdentifier,
          tooltype: toolType,
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
}
