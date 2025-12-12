import 'package:auravibes_app/utils/string_extensions.dart';

/// Parses a tool's composite ID and provides display-friendly formatting.
///
/// Tool composite IDs follow these formats:
/// - MCP tools: `mcp_<mcp_id>_<slug_name>_<tool_identifier>`
/// - Built-in tools: `built_in_<table_id>_<tool_identifier>`
///
/// Note: Tool names must match pattern ^[a-zA-Z0-9_-]{1,128}$
/// so we use underscores as separators instead of colons.
class ToolNameFormatter {
  const ToolNameFormatter._();

  /// Parses a composite tool ID into its components.
  ///
  /// Returns a [ParsedToolId] with the parsed components,
  /// or a fallback if the format is unrecognized.
  static ParsedToolId parse(String compositeId) {
    // Try parsing as MCP tool (format: mcp_<id>_<slug>_<tool>)
    if (compositeId.startsWith('mcp_')) {
      final withoutPrefix = compositeId.substring(4);
      // Split by underscore, but we need exactly 3 parts after prefix
      // Since slug and tool can contain underscores, we need to be careful
      // Format: <id>_<slug>_<tool> where id is numeric
      final firstUnderscoreIdx = withoutPrefix.indexOf('_');
      if (firstUnderscoreIdx > 0) {
        final mcpId = withoutPrefix.substring(0, firstUnderscoreIdx);
        final rest = withoutPrefix.substring(firstUnderscoreIdx + 1);
        final secondUnderscoreIdx = rest.indexOf('_');
        if (secondUnderscoreIdx > 0) {
          final slug = rest.substring(0, secondUnderscoreIdx);
          final tool = rest.substring(secondUnderscoreIdx + 1);
          if (mcpId.isNotEmpty && slug.isNotEmpty && tool.isNotEmpty) {
            return ParsedToolId.mcp(
              mcpServerId: mcpId,
              slugName: slug,
              toolIdentifier: tool,
            );
          }
        }
      }
    }

    // Try parsing as built-in tool (format: built_in_<table_id>_<tool>)
    if (compositeId.startsWith('built_in_')) {
      final withoutPrefix = compositeId.substring(9);
      // Split to get table_id and tool_identifier
      final firstUnderscoreIdx = withoutPrefix.indexOf('_');
      if (firstUnderscoreIdx > 0) {
        final tableId = withoutPrefix.substring(0, firstUnderscoreIdx);
        final toolIdentifier = withoutPrefix.substring(firstUnderscoreIdx + 1);
        if (tableId.isNotEmpty && toolIdentifier.isNotEmpty) {
          return ParsedToolId.builtIn(
            tableId: tableId,
            toolIdentifier: toolIdentifier,
          );
        }
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
