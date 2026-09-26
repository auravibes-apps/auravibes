import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/providers/compaction_checkpoint_history_provider.dart';
import 'package:auravibes_app/features/chats/usecases/restore_compaction_checkpoint_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const CompactionCheckpointHistoryDialog({
  required final String workspaceId,
  required final String conversationId,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<CompactionCheckpointHistoryDialog> createState() =>
      _CompactionCheckpointHistoryDialogState();
}

class _CompactionCheckpointHistoryDialogState
    extends ConsumerState<CompactionCheckpointHistoryDialog> {
  bool _expanded = false;
  bool _restoring = false;
  String? _errorKey;

  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraButton(
        onPressed: () => setState(() => _expanded = !_expanded),
        child: const TextLocale(LocaleKeys.compaction_compacted_history_action),
        variant: .text,
      ),
      if (_errorKey case final error?) TextLocale(error),
      if (_expanded)
        switch (ref.watch(
          compactionCheckpointHistoryProvider((
            workspaceId: widget.workspaceId,
            conversationId: widget.conversationId,
          )),
        )) {
          AsyncData(:final value) when value.summaries.isEmpty =>
            const TextLocale(LocaleKeys.compaction_compacted_history_empty),
          AsyncData(:final value) => AuraColumn(
            children: [
              for (final message in value.summaries)
                _CompactionCheckpointEntry(
                  message: message,
                  isActive: message.id == value.activeCheckpointId,
                  isRestoring: _restoring,
                  onRestore: () => _restore(message.id),
                ),
            ],
            crossAxisAlignment: .stretch,
          ),
          AsyncError() => const TextLocale(
            LocaleKeys.compaction_compacted_history_unavailable,
          ),
          AsyncLoading() => const TextLocale(
            LocaleKeys.compaction_compacted_history_loading,
          ),
        },
    ],
    crossAxisAlignment: .stretch,
  );

  Future<void> _restore(String checkpointId) async {
    setState(() {
      _restoring = true;
      _errorKey = null;
    });
    try {
      await ref
          .read(restoreCompactionCheckpointUsecaseProvider)
          .call(
            workspaceId: widget.workspaceId,
            conversationId: widget.conversationId,
            checkpointMessageId: checkpointId,
          );
      ref.invalidate(
        compactionCheckpointHistoryProvider((
          workspaceId: widget.workspaceId,
          conversationId: widget.conversationId,
        )),
      );
    } on CompactionException catch (error) {
      if (mounted) setState(() => _errorKey = error.localeKey);
    } on Exception {
      if (mounted) {
        setState(
          () => _errorKey =
              LocaleKeys.compaction_errors_checkpoint_restore_unavailable,
        );
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }
}

class const _CompactionCheckpointEntry({
  required final MessageEntity message,
  required final bool isActive,
  required final bool isRestoring,
  required final VoidCallback onRestore,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final metadata = message.metadata;
    final provider = metadata?.compactionProviderId;
    final model = metadata?.compactionModelId;
    final from = metadata?.compactedFromMessageId;
    final through = metadata?.compactedThroughMessageId;
    final range = from == null || through == null
        ? LocaleKeys.compaction_compacted_details_unknown.tr()
        : '$from to $through';
    final modelName = provider == null || model == null
        ? LocaleKeys.compaction_compacted_details_unknown.tr()
        : '$provider/$model';

    final rangeLabel = LocaleKeys.compaction_compacted_details_range.tr();
    final modelLabel = LocaleKeys.compaction_compacted_details_model.tr();

    return AuraContainer(
      child: AuraColumn(
        children: [
          AuraText(
            child: Text(RelativeTimeFormatter.format(message.createdAt)),
          ),
          AuraText(child: Text('$rangeLabel: $range')),
          AuraText(child: Text('$modelLabel: $modelName')),
          if (isActive)
            const TextLocale(LocaleKeys.compaction_compacted_history_active),
          if (!isActive && !isRestoring)
            AuraButton(
              onPressed: onRestore,
              child: const TextLocale(
                LocaleKeys.compaction_compacted_history_restore,
              ),
              size: .small,
            ),
        ],
        crossAxisAlignment: .start,
      ),
      padding: .small,
      margin: .small,
      variant: .surfaceVariant,
    );
  }
}
