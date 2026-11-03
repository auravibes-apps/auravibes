import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const _mcpAnnotationLabels = <String, ({String trueLabel, String falseLabel})>{
  'readOnlyHint': (
    trueLabel: LocaleKeys.mcp_tool_annotations_read_only,
    falseLabel: LocaleKeys.mcp_tool_annotations_not_read_only,
  ),
  'destructiveHint': (
    trueLabel: LocaleKeys.mcp_tool_annotations_may_change_data,
    falseLabel: LocaleKeys.mcp_tool_annotations_no_destructive_changes_reported,
  ),
  'idempotentHint': (
    trueLabel: LocaleKeys.mcp_tool_annotations_repeat_may_be_safe,
    falseLabel:
        LocaleKeys.mcp_tool_annotations_repeat_may_have_different_effects,
  ),
  'openWorldHint': (
    trueLabel: LocaleKeys.mcp_tool_annotations_may_access_external_services,
    falseLabel: LocaleKeys.mcp_tool_annotations_external_access_not_reported,
  ),
};

/// Shows MCP server annotations as informational, non-authoritative hints.
class const McpToolAnnotationHints({
  required final Map<String, Object?>? annotations,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final labels = [
      for (final entry in _mcpAnnotationLabels.entries)
        if (annotations?[entry.key] case final bool hint)
          hint ? entry.value.trueLabel : entry.value.falseLabel,
    ];
    if (labels.isEmpty) return const SizedBox.shrink();

    final spacing = context.auraTheme.fromSpacing(.xs);
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final label in labels)
          AuraBadge.text(
            child: TextLocale(label),
            variant: .info,
            size: .small,
            semanticLabel: label.tr(),
          ),
      ],
    );
  }
}
