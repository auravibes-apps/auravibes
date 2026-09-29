import 'dart:async';

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

  CompactionCheckpointHistoryKey get _historyKey =>
      (workspaceId: widget.workspaceId, conversationId: widget.conversationId);

  @override
  Widget build(BuildContext _) => AuraColumn(
    children: [
      _CompactionCheckpointHistoryToggle(onPressed: _toggleHistory),
      if (_errorKey case final error?) TextLocale(error),
      if (_expanded)
        _CompactionCheckpointHistorySection(
          historyKey: _historyKey,
          isRestoring: _restoring,
          onRestore: _restore,
        ),
    ],
    crossAxisAlignment: .stretch,
  );

  void _toggleHistory() => setState(() => _expanded = !_expanded);

  void _restore(String checkpointId) => unawaited(_restoreAsync(checkpointId));

  Future<void> _restoreAsync(String checkpointId) async {
    setState(() {
      _restoring = true;
      _errorKey = null;
    });
    try {
      await _restoreAndInvalidate(checkpointId);
    } on Exception catch (error) {
      _setRestoreError(error);
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _restoreAndInvalidate(String checkpointId) async {
    await ref
        .read(restoreCompactionCheckpointUsecaseProvider)
        .call(
          workspaceId: widget.workspaceId,
          conversationId: widget.conversationId,
          checkpointMessageId: checkpointId,
        );
    if (!mounted) return;
    ref.invalidate(
      compactionCheckpointHistoryProvider((
        workspaceId: widget.workspaceId,
        conversationId: widget.conversationId,
      )),
    );
  }

  void _setRestoreError(Exception error) {
    if (!mounted) return;
    final errorKey = switch (error) {
      CompactionException(:final localeKey) => localeKey,
      _ => LocaleKeys.compaction_errors_checkpoint_restore_unavailable,
    };
    setState(() => _errorKey = errorKey);
  }
}

class const _CompactionCheckpointHistoryToggle({
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale(LocaleKeys.compaction_compacted_history_action),
    variant: .text,
  );
}

class const _CompactionCheckpointHistorySection({
  required final CompactionCheckpointHistoryKey historyKey,
  required final bool isRestoring,
  required final ValueChanged<String> onRestore,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext _, WidgetRef ref) =>
      _CompactionCheckpointHistoryContent(
        history: ref.watch(compactionCheckpointHistoryProvider(historyKey)),
        isRestoring: isRestoring,
        onRestore: onRestore,
      );
}

class const _CompactionCheckpointHistoryContent({
  required final AsyncValue<CompactionCheckpointHistory> history,
  required final bool isRestoring,
  required final ValueChanged<String> onRestore,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (history) {
    AsyncData(:final value) when value.summaries.isEmpty => const TextLocale(
      LocaleKeys.compaction_compacted_history_empty,
    ),
    AsyncData(:final value) => _CompactionCheckpointHistoryEntries(
      history: value,
      isRestoring: isRestoring,
      onRestore: onRestore,
    ),
    AsyncError() => const TextLocale(
      LocaleKeys.compaction_compacted_history_unavailable,
    ),
    AsyncLoading() => const TextLocale(
      LocaleKeys.compaction_compacted_history_loading,
    ),
  };
}

class const _CompactionCheckpointHistoryEntries({
  required final CompactionCheckpointHistory history,
  required final bool isRestoring,
  required final ValueChanged<String> onRestore,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      for (final message in history.summaries)
        _CompactionCheckpointEntry(
          message: message,
          isActive: message.id == history.activeCheckpointId,
          isRestoring: isRestoring,
          onRestore: () => onRestore(message.id),
        ),
    ],
    crossAxisAlignment: .stretch,
  );
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

    return AuraContainer(
      child: AuraColumn(
        children: [
          _CompactionCheckpointCreatedAt(createdAt: message.createdAt),
          _CompactionCheckpointRangeRow(metadata: metadata),
          _CompactionCheckpointModelRow(metadata: metadata),
          _CompactionCheckpointActions(
            isActive: isActive,
            isRestoring: isRestoring,
            onRestore: onRestore,
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

class const _CompactionCheckpointCreatedAt({required final DateTime createdAt})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(
      RelativeTimeFormatter.format(
        createdAt,
        locale: Localizations.localeOf(context),
      ),
    ),
  );
}

String _checkpointJoinedValue(
  String? first,
  String? second,
  String separator,
) => first == null || second == null
    ? LocaleKeys.compaction_compacted_details_unknown.tr()
    : '$first$separator$second';

class const _CompactionCheckpointRangeRow({
  required final MessageMetadataEntity? metadata,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => _CompactionCheckpointDetailRow(
    label: LocaleKeys.compaction_compacted_details_range.tr(),
    value: _checkpointJoinedValue(
      metadata?.compactedFromMessageId,
      metadata?.compactedThroughMessageId,
      ' to ',
    ),
  );
}

class const _CompactionCheckpointModelRow({
  required final MessageMetadataEntity? metadata,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => _CompactionCheckpointDetailRow(
    label: LocaleKeys.compaction_compacted_details_model.tr(),
    value: _checkpointJoinedValue(
      metadata?.compactionProviderId,
      metadata?.compactionModelId,
      '/',
    ),
  );
}

class const _CompactionCheckpointDetailRow({
  required final String label,
  required final String value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraText(child: Text('$label: $value'));
}

class const _CompactionCheckpointActions({
  required final bool isActive,
  required final bool isRestoring,
  required final VoidCallback onRestore,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => switch ((
    isActive: isActive,
    isRestoring: isRestoring,
  )) {
    (isActive: true, isRestoring: _) => const TextLocale(
      LocaleKeys.compaction_compacted_history_active,
    ),
    (isActive: false, isRestoring: true) => const SizedBox.shrink(),
    (isActive: false, isRestoring: false) => AuraButton(
      onPressed: onRestore,
      child: const TextLocale(LocaleKeys.compaction_compacted_history_restore),
      size: .small,
    ),
  };
}
