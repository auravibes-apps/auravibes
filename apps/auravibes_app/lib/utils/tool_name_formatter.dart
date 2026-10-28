// Required: Existing thresholds and limits use numeric values.
// Required: Existing argument values intentionally repeat.
// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:easy_localization/easy_localization.dart';

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
      _skillToolParts(kind, skillSlug, toolIdentifier),
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
    if (isWorkspaceToolName(rawName)) {
      return _ResolvedToolNameFormatter.formatWorkspaceToolName(rawName);
    }
    if (parsedId == null) return rawName.toHumanReadable();

    return _ResolvedToolNameFormatter.format(parsedId, mcpServerName);
  }

  static ({String source, String skillSlug, String toolSlug}) _skillToolParts(
    AgentResolvedToolKind kind,
    String skillSlug,
    String toolIdentifier,
  ) => (
    source: kind == AgentResolvedToolKind.skillNative ? 'app_native' : 'user',
    skillSlug: skillSlug,
    toolSlug: toolIdentifier,
  );
}

abstract final class _ResolvedToolNameFormatter {
  static String formatWorkspaceToolName(String toolIdentifier) =>
      _formatToolName(toolIdentifier);

  static String format(AgentResolvedToolName parsedId, String? mcpServerName) {
    final toolIdentifier = parsedId.toolIdentifier;
    final kind = parsedId.kind;

    if (kind == AgentResolvedToolKind.mcp) {
      return _formatMcpName(
        toolIdentifier,
        _mcpServerName(parsedId, mcpServerName),
      );
    }
    if (_isSkill(kind)) {
      return _formatSkillNameFromParsed(parsedId, toolIdentifier);
    }

    return _formatToolName(toolIdentifier);
  }

  static bool _isSkill(AgentResolvedToolKind kind) =>
      kind == AgentResolvedToolKind.skillNative;

  static String _mcpServerName(
    AgentResolvedToolName parsedId,
    String? mcpServerName,
  ) {
    final mcpSlug = parsedId.mcpSlug;
    if (mcpSlug == null) return parsedId.toolIdentifier.toHumanReadable();

    return mcpServerName ?? mcpSlug.toHumanReadable();
  }

  static String _formatSkillNameFromParsed(
    AgentResolvedToolName parsedId,
    String toolIdentifier,
  ) {
    final skillSlug = parsedId.skillSlug;
    if (skillSlug == null) return _formatToolName(toolIdentifier);

    return _formatSkillName(skillSlug, toolIdentifier);
  }

  static String _formatMcpName(String toolIdentifier, String serverName) =>
      '$serverName: ${_formatToolName(toolIdentifier)}';

  static String _formatSkillName(String skillSlug, String toolIdentifier) =>
      '${skillSlug.toHumanReadable()}: ${_formatToolName(toolIdentifier)}';

  static String _formatToolName(
    String toolIdentifier,
  ) => switch (toolIdentifier) {
    'workspace_read_directory' =>
      LocaleKeys.workspace_tool_names_read_directory.tr(),
    'workspace_read_item' =>
      LocaleKeys.workspace_tool_names_open_file_or_view.tr(),
    'workspace_read_table' => LocaleKeys.workspace_tool_names_read_table.tr(),
    'workspace_create_folder' =>
      LocaleKeys.workspace_tool_names_create_folder.tr(),
    'workspace_rename_folder' =>
      LocaleKeys.workspace_tool_names_rename_folder.tr(),
    'workspace_create_table' =>
      LocaleKeys.workspace_tool_names_create_table.tr(),
    'workspace_rename_table' =>
      LocaleKeys.workspace_tool_names_rename_table.tr(),
    'workspace_add_row' => LocaleKeys.workspace_tool_names_add_row.tr(),
    'workspace_update_record' =>
      LocaleKeys.workspace_tool_names_update_row.tr(),
    'workspace_save_column' => LocaleKeys.workspace_tool_names_edit_column.tr(),
    'workspace_create_view' => LocaleKeys.workspace_tool_names_create_view.tr(),
    'workspace_save_view' => LocaleKeys.workspace_tool_names_edit_view.tr(),
    _ => toolIdentifier.toHumanReadable(),
  };
}
