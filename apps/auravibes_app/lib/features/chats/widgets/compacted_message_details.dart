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

class const CompactedMessageDetails({
  required final MessageEntity message,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AuraColumn(
        children: [
          const _CompactedDetailsTitle(),
          _CompactedDetailsMetadata(metadata: message.metadata),
          _CompactedDetailsContent(content: message.content),
        ],
        crossAxisAlignment: .start,
      ),
    );
  }
}

class const _CompactedDetailsTitle() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const TextLocale(
    LocaleKeys.compaction_compacted_details_title,
    style: .new(fontSize: 18, fontWeight: FontWeight.bold),
  );
}

class const _CompactedDetailsMetadata({
  required final MessageMetadataEntity? metadata,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        const AuraSizedBox(height: .md),
        _CompactionOriginRow(value: _compactionOriginLabel(metadata)),
        if (metadata case final metadata?
            when metadata.compactedFromMessageId != null &&
                metadata.compactedThroughMessageId != null)
          _CompactionRangeRow(metadata: metadata),
        _CompactionCreatedRow(metadata: metadata),
        _CompactionMessagesRow(metadata: metadata),
      ],
      crossAxisAlignment: .start,
    );
  }
}

String _compactionOriginLabel(MessageMetadataEntity? metadata) =>
    switch (metadata?.compactionKind) {
      .manual => LocaleKeys.compaction_compacted_manual_origin.tr(),
      .auto => LocaleKeys.compaction_compacted_auto_origin.tr(),
      _ => LocaleKeys.compaction_compacted_widget_label.tr(),
    };

class const _CompactionOriginRow({required final String value})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _DetailRow(
    label: LocaleKeys.compaction_compacted_details_origin.tr(),
    value: value,
  );
}

class const _CompactionRangeRow({required final MessageMetadataEntity metadata})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _DetailRow(
    label: LocaleKeys.compaction_compacted_details_range.tr(),
    value:
        '${metadata.compactedFromMessageId} -> '
        '${metadata.compactedThroughMessageId}',
  );
}

class const _CompactionCreatedRow({
  required final MessageMetadataEntity? metadata,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _DetailRow(
    label: LocaleKeys.compaction_compacted_details_created.tr(),
    value: switch (metadata?.compactionCreatedAt) {
      final createdAt? => RelativeTimeFormatter.format(createdAt),
      _ => '',
    },
  );
}

class const _CompactionMessagesRow({
  required final MessageMetadataEntity? metadata,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _DetailRow(
    label: LocaleKeys.compaction_compacted_details_messages.tr(),
    value: '${metadata?.compactedMessageIds.length ?? 0}',
  );
}

class const _CompactedDetailsContent({required final String content})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    return AuraColumn(
      children: [
        const AuraSizedBox(height: .md),
        _CompactedContentLabel(color: auraColors.onSurfaceVariant),
        const AuraSizedBox(height: .xs),
        AuraSelectableText(content, style: .bodySmall),
      ],
      crossAxisAlignment: .start,
    );
  }
}

class const _CompactedContentLabel({required final Color color})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextLocale(
    LocaleKeys.compaction_compacted_details_content_label,
    style: .new(
      color: color,
      fontSize: context.auraTheme.typography.fontSizeSm,
      fontWeight: FontWeight.bold,
    ),
  );
}

class const _DetailRow({
  required final String label,
  required final String value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.auraTheme.fromSpacing(.xs)),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          _DetailLabel(label: label),
          _DetailValue(value: value),
        ],
      ),
    );
  }
}

class const _DetailLabel({required final String label})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 120,
    child: Text(
      label,
      style: .new(
        color: context.auraColors.onSurfaceVariant,
        fontSize: context.auraTheme.typography.fontSizeSm,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class const _DetailValue({required final String value})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    child: Text(
      value,
      style: .new(fontSize: context.auraTheme.typography.fontSizeSm),
    ),
  );
}
