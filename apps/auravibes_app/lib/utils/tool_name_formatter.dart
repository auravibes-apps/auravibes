// Required: Existing thresholds and limits use numeric values.
// Required: Existing argument values intentionally repeat.
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

/// Parses a tool's composite ID and provides display-friendly formatting.
///
/// Tool composite IDs follow these formats:
/// - MCP tools: `mcp_<mcp_id>_<slug_name>_<tool_identifier>`
/// - Built-in tools: `built_in_<table_id>_<tool_identifier>`
/// - Native tools: `native_<table_id>_<tool_identifier>`
///
/// Note: Tool names must match pattern ^[a-zA-Z0-9_-]{1,128}$
/// so we use underscores as separators instead of colons.
class const ToolNameFormatter._() {
  /// Parses a composite tool ID into its components.
  ///
  /// Returns an [AgentResolvedToolName] with the parsed components,
  /// or a fallback if the format is unrecognized.
  static AgentResolvedToolName? parse(String compositeId) =>
      const AgentToolNameResolver().resolve(compositeId);

  static ({String source, String skillSlug, String toolSlug})?
  parseSkillToolName(String compositeId) => switch (parse(compositeId)) {
    AgentResolvedToolName(
      isSkill: true,
      skillSlug: final skillSlug?,
      :final kind,
      :final toolIdentifier,
    ) =>
      (
        source: kind == AgentResolvedToolKind.skillNative ? 'app' : 'user',
        skillSlug: skillSlug,
        toolSlug: toolIdentifier,
      ),
    _ => null,
  };

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
    AgentResolvedToolName? parsedId, {
    String rawName = '',
    String? mcpServerName,
  }) {
    if (parsedId == null) return rawName.toHumanReadable();

    return _formatResolvedName(parsedId, mcpServerName);
  }

  static String _formatResolvedName(
    AgentResolvedToolName parsedId,
    String? mcpServerName,
  ) {
    final toolIdentifier = parsedId.toolIdentifier;
    final kind = parsedId.kind;

    if (kind == AgentResolvedToolKind.mcp) {
      return _formatMcpName(
        toolIdentifier,
        _mcpServerName(parsedId, mcpServerName),
      );
    }
    if (kind == AgentResolvedToolKind.skillTemplate ||
        kind == AgentResolvedToolKind.skillNative) {
      return _formatSkillNameFromParsed(parsedId, toolIdentifier);
    }

    return _formatToolName(toolIdentifier);
  }

  static String _mcpServerName(
    AgentResolvedToolName parsedId,
    String? mcpServerName,
  ) => mcpServerName ?? parsedId.mcpSlug!.toHumanReadable();

  static String _formatSkillNameFromParsed(
    AgentResolvedToolName parsedId,
    String toolIdentifier,
  ) => _formatSkillName(parsedId.skillSlug!, toolIdentifier);

  static String _formatMcpName(String toolIdentifier, String serverName) =>
      '$serverName: ${_formatToolName(toolIdentifier)}';

  static String _formatSkillName(String skillSlug, String toolIdentifier) =>
      '${skillSlug.toHumanReadable()}: ${_formatToolName(toolIdentifier)}';

  static String _formatToolName(String toolIdentifier) =>
      toolIdentifier.toHumanReadable();
}
