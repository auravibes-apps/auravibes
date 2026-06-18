// Required: Existing thresholds and limits use numeric values.
// Required: Existing argument values intentionally repeat.
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/utils/string_extensions.dart';

/// Parses a tool's composite ID and provides display-friendly formatting.
///
/// Tool composite IDs follow these formats:
/// - MCP tools: `mcp_<mcp_id>_<slug_name>_<tool_identifier>`
/// - Built-in tools: `built_in_<table_id>_<tool_identifier>`
/// - Native tools: `native_<table_id>_<tool_identifier>`
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
    final mcpTool = _parseMcpTool(compositeId);
    if (mcpTool != null) return mcpTool;

    final builtInTool = _parseBuiltInTool(compositeId);
    if (builtInTool != null) return builtInTool;

    final nativeTool = _parseNativeTool(compositeId);
    if (nativeTool != null) return nativeTool;

    return ParsedToolId.unknown(rawName: compositeId);
  }

  static ParsedToolId? _parseMcpTool(String compositeId) {
    final match = RegExp(r'^mcp_([^_]+)_([^_]+)_(.+)$').firstMatch(
      compositeId,
    );
    if (match == null) return null;

    final mcpId = match.group(1);
    final slug = match.group(2);
    final tool = match.group(3);
    if (mcpId == null || slug == null || tool == null) return null;
    if (mcpId.isEmpty || slug.isEmpty || tool.isEmpty) return null;

    return ParsedToolId.mcp(
      mcpServerId: mcpId,
      slugName: slug,
      toolIdentifier: tool,
    );
  }

  static ParsedToolId? _parseBuiltInTool(String compositeId) {
    return _parseTableTool(
      compositeId,
      'built_in',
      ParsedToolId.builtIn,
    );
  }

  static ParsedToolId? _parseNativeTool(String compositeId) {
    return _parseTableTool(
      compositeId,
      'native',
      ParsedToolId.native,
    );
  }

  static ParsedToolId? _parseTableTool(
    String value,
    String prefix,
    ParsedToolId Function({
      required String tableId,
      required String toolIdentifier,
    })
    create,
  ) {
    final match = RegExp(
      '^${RegExp.escape(prefix)}'
      r'_([^_]+)_(.+)$',
    ).firstMatch(value);
    if (match == null) return null;

    final tableId = match.group(1);
    final toolIdentifier = match.group(2);
    if (tableId == null || toolIdentifier == null) return null;
    if (tableId.isEmpty || toolIdentifier.isEmpty) return null;

    return create(tableId: tableId, toolIdentifier: toolIdentifier);
  }

  static ({String source, String skillSlug, String toolSlug})?
  parseSkillToolName(String compositeId) {
    return switch (compositeId.split('__')) {
      ['skill', final source, final skillSlug, final toolSlug]
          when (source == 'user' || source == 'app') &&
              skillSlug.isNotEmpty &&
              toolSlug.isNotEmpty =>
        (source: source, skillSlug: skillSlug, toolSlug: toolSlug),
      _ => null,
    };
  }

  static String? formatSkillDisplayName(String compositeId) {
    final parsed = parseSkillToolName(compositeId);
    if (parsed == null) return null;

    return '${parsed.skillSlug.toHumanReadable()}: '
        '${parsed.toolSlug.toHumanReadable()}';
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
      native: (tableId, toolIdentifier) {
        return toolIdentifier.toHumanReadable();
      },
      unknown: (rawName) {
        return formatSkillDisplayName(rawName) ?? rawName.toHumanReadable();
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

  /// Creates a parsed native tool ID.
  const factory ParsedToolId.native({
    required String tableId,
    required String toolIdentifier,
  }) = NativeParsedToolId;

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
    required T Function(String tableId, String toolIdentifier) native,
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
    required T Function(String tableId, String toolIdentifier) native,
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
    required T Function(String tableId, String toolIdentifier) native,
    required T Function(String rawName) unknown,
  }) => builtIn(tableId, toolIdentifier);
}

/// Parsed native tool ID.
final class NativeParsedToolId extends ParsedToolId {
  const NativeParsedToolId({
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
    required T Function(String tableId, String toolIdentifier) native,
    required T Function(String rawName) unknown,
  }) => native(tableId, toolIdentifier);
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
    required T Function(String tableId, String toolIdentifier) native,
    required T Function(String rawName) unknown,
  }) => unknown(rawName);
}
