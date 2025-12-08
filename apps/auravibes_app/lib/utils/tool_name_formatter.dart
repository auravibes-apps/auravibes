import 'package:auravibes_app/utils/string_extensions.dart';

/// Parses a tool's composite ID and provides display-friendly formatting.
///
/// Tool composite IDs follow these formats:
/// - MCP tools: `mcp::<mcp_id>::<slug_name>::<tool_identifier>`
/// - Built-in tools: `built_in::<table_id>::<tool_identifier>`
class ToolNameFormatter {
  const ToolNameFormatter._();

  /// Parses a composite tool ID into its components.
  ///
  /// Returns a [ParsedToolId] with the parsed components,
  /// or a fallback if the format is unrecognized.
  static ParsedToolId parse(String compositeId) {
    // Try parsing as MCP tool
    if (compositeId.startsWith('mcp::')) {
      final withoutPrefix = compositeId.substring(5);
      final parts = withoutPrefix.split('::');
      if (parts.length == 3) {
        return ParsedToolId.mcp(
          mcpServerId: parts[0],
          slugName: parts[1],
          toolIdentifier: parts[2],
        );
      }
    }

    // Try parsing as built-in tool
    if (compositeId.startsWith('built_in::')) {
      final withoutPrefix = compositeId.substring(10);
      final parts = withoutPrefix.split('::');
      if (parts.length == 2) {
        return ParsedToolId.builtIn(
          tableId: parts[0],
          toolIdentifier: parts[1],
        );
      }
    }

    // Fallback for unknown format
    return ParsedToolId.unknown(rawName: compositeId);
  }

  /// Formats a tool display name using the parsed ID and optional server name.
  ///
  /// For MCP tools, uses the format: `<serverName>: <Tool Name>`
  /// For built-in tools, just shows: `<Tool Name>`
  ///
  /// [parsedId] The parsed tool ID components.
  /// [mcpServerName] Optional original server name (overrides slug).
  static String formatDisplayName(
    ParsedToolId parsedId, {
    String? mcpServerName,
  }) {
    return parsedId.when(
      mcp: (mcpServerId, slugName, toolIdentifier) {
        final serverDisplayName = mcpServerName ?? slugName.toHumanReadable();
        final toolDisplayName = toolIdentifier.toHumanReadable();
        return '$serverDisplayName: $toolDisplayName';
      },
      builtIn: (tableId, toolIdentifier) {
        return toolIdentifier.toHumanReadable();
      },
      unknown: (rawName) {
        // Best effort: try to make it readable
        return rawName.toHumanReadable();
      },
    );
  }
}

/// Represents a parsed composite tool ID.
sealed class ParsedToolId {
  const ParsedToolId._();

  /// Creates a parsed MCP tool ID.
  const factory ParsedToolId.mcp({
    required String mcpServerId,
    required String slugName,
    required String toolIdentifier,
  }) = McpParsedToolId;

  /// Creates a parsed built-in tool ID.
  const factory ParsedToolId.builtIn({
    required String tableId,
    required String toolIdentifier,
  }) = BuiltInParsedToolId;

  /// Creates a fallback for unknown format.
  const factory ParsedToolId.unknown({
    required String rawName,
  }) = UnknownParsedToolId;

  /// Pattern matches on the parsed tool ID type.
  T when<T>({
    required T Function(
      String mcpServerId,
      String slugName,
      String toolIdentifier,
    )
    mcp,
    required T Function(String tableId, String toolIdentifier) builtIn,
    required T Function(String rawName) unknown,
  });

  /// Returns the MCP server ID if this is an MCP tool, null otherwise.
  String? get mcpServerId;
}

/// Parsed MCP tool ID.
final class McpParsedToolId extends ParsedToolId {
  const McpParsedToolId({
    required this.mcpServerId,
    required this.slugName,
    required this.toolIdentifier,
  }) : super._();

  @override
  final String mcpServerId;

  /// The slugified server name.
  final String slugName;

  /// The original tool name from the MCP server.
  final String toolIdentifier;

  @override
  T when<T>({
    required T Function(
      String mcpServerId,
      String slugName,
      String toolIdentifier,
    )
    mcp,
    required T Function(String tableId, String toolIdentifier) builtIn,
    required T Function(String rawName) unknown,
  }) => mcp(mcpServerId, slugName, toolIdentifier);
}

/// Parsed built-in tool ID.
final class BuiltInParsedToolId extends ParsedToolId {
  const BuiltInParsedToolId({
    required this.tableId,
    required this.toolIdentifier,
  }) : super._();

  /// The database ID of the workspace tool.
  final String tableId;

  /// The tool type identifier.
  final String toolIdentifier;

  @override
  String? get mcpServerId => null;

  @override
  T when<T>({
    required T Function(
      String mcpServerId,
      String slugName,
      String toolIdentifier,
    )
    mcp,
    required T Function(String tableId, String toolIdentifier) builtIn,
    required T Function(String rawName) unknown,
  }) => builtIn(tableId, toolIdentifier);
}

/// Fallback for unknown tool ID format.
final class UnknownParsedToolId extends ParsedToolId {
  const UnknownParsedToolId({required this.rawName}) : super._();

  /// The original raw name that couldn't be parsed.
  final String rawName;

  @override
  String? get mcpServerId => null;

  @override
  T when<T>({
    required T Function(
      String mcpServerId,
      String slugName,
      String toolIdentifier,
    )
    mcp,
    required T Function(String tableId, String toolIdentifier) builtIn,
    required T Function(String rawName) unknown,
  }) => unknown(rawName);
}
