// Required: Existing thresholds and limits use numeric values.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CompactedMessageDetails extends StatelessWidget {
  const CompactedMessageDetails({required this.message, super.key});

  final MessageEntity message;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final metadata = message.metadata;
    final kind = metadata?.compactionKind;
    final originLabel = switch (kind) {
      CompactionKind.manual =>
        LocaleKeys.compaction_compacted_manual_origin.tr(),
      CompactionKind.auto => LocaleKeys.compaction_compacted_auto_origin.tr(),
      _ => LocaleKeys.compaction_compacted_widget_label.tr(),
    };

    return SingleChildScrollView(
      child: AuraColumn(
        children: [
          const TextLocale(
            LocaleKeys.compaction_compacted_details_title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const AuraSizedBox(height: .md),
          _DetailRow(
            label: LocaleKeys.compaction_compacted_details_origin.tr(),
            value: originLabel,
          ),
          if (metadata case final metadata?
              when metadata.compactedFromMessageId != null &&
                  metadata.compactedThroughMessageId != null)
            _DetailRow(
              label: LocaleKeys.compaction_compacted_details_range.tr(),
              value:
                  '${metadata.compactedFromMessageId} -> '
                  '${metadata.compactedThroughMessageId}',
            ),
          _DetailRow(
            label: LocaleKeys.compaction_compacted_details_created.tr(),
            value: switch (metadata?.compactionCreatedAt) {
              final createdAt? => formatRelativeTime(createdAt),
              _ => '',
            },
          ),
          _DetailRow(
            label: LocaleKeys.compaction_compacted_details_messages.tr(),
            value: '${metadata?.compactedMessageIds.length ?? 0}',
          ),
          const AuraSizedBox(height: .md),
          TextLocale(
            LocaleKeys.compaction_compacted_details_content_label,
            style: TextStyle(
              color: auraColors.onSurfaceVariant,
              fontSize: context.auraTheme.typography.fontSizeSm,
              fontWeight: FontWeight.bold,
            ),
          ),
          const AuraSizedBox(height: .xs),
          SelectableText(
            message.content,
            style: TextStyle(
              fontSize: context.auraTheme.typography.fontSizeSm,
              fontFamily: context.auraTheme.typography.monoFontFamily,
            ),
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: context.auraTheme.fromSpacing(.xs),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: context.auraColors.onSurfaceVariant,
                fontSize: context.auraTheme.typography.fontSizeSm,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: context.auraTheme.typography.fontSizeSm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
