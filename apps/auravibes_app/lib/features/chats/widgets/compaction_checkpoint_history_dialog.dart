import 'dart:async';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/exceptions/compaction_exception.dart';
import 'package:auravibes_app/features/chats/agent_adapters/message_transcript_snapshot_mapper.dart';
import 'package:auravibes_app/features/chats/providers/compaction_checkpoint_history_provider.dart';
import 'package:auravibes_app/features/chats/usecases/restore_compaction_checkpoint_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/select_prompt_messages_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef _PreviewCheckpointRestore = void Function(
  MessageEntity checkpoint,
  CompactionCheckpointHistory history,
);

typedef _CheckpointRestorePreview = ({
  MessageEntity activeCheckpoint,
  int conversationRevision,
  MessageEntity checkpoint,
  List<MessageEntity> replayMessages,
  List<MessageEntity> transcriptMessages,
});

const _targetCheckpointLabelKey =
    'compaction.compacted.history_preview_target_checkpoint';
const _sameCheckpointSummaryKey =
    'compaction.compacted.history_preview_summary_same';
const _differentCheckpointSummaryKey =
    'compaction.compacted.history_preview_summaries_different';

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

  void _restore(
    MessageEntity checkpoint,
    CompactionCheckpointHistory history,
  ) => unawaited(_previewRestore(checkpoint, history));

  Future<void> _previewRestore(
    MessageEntity checkpoint,
    CompactionCheckpointHistory history,
  ) async {
    if (_restoring) return;
    setState(() {
      _restoring = true;
      _errorKey = null;
    });
    try {
      await _showPreviewAndRestore(checkpoint, history);
    } on Exception catch (error) {
      _setRestoreError(error);
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _showPreviewAndRestore(
    MessageEntity checkpoint,
    CompactionCheckpointHistory history,
  ) async {
    final preview = _checkpointRestorePreview(checkpoint, history);
    if (preview == null) {
      _setStalePreviewError();

      return;
    }
    final confirmed = await _confirmPreview(preview);
    if (!mounted || !confirmed) return;
    await _restorePreview(preview);
  }

  Future<bool> _confirmPreview(_CheckpointRestorePreview preview) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => _CheckpointRestorePreviewDialog(preview: preview),
      ) ??
      false;

  Future<void> _restorePreview(_CheckpointRestorePreview preview) async {
    await ref.read(restoreCompactionCheckpointUsecaseProvider).call((
      workspaceId: widget.workspaceId,
      conversationId: widget.conversationId,
      checkpointMessageId: preview.checkpoint.id,
      expectedConversationRevision: preview.conversationRevision,
      expectedMessages: preview.transcriptMessages,
    ));
    if (!mounted) return;
    ref.invalidate(compactionCheckpointHistoryProvider(_historyKey));
  }

  void _setStalePreviewError() {
    if (!mounted) return;
    setState(
      () => _errorKey = LocaleKeys.compaction_errors_checkpoint_restore_stale,
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

_CheckpointRestorePreview? _checkpointRestorePreview(
  MessageEntity checkpoint,
  CompactionCheckpointHistory history,
) {
  final activeCheckpoint = history.summaries
      .where((summary) => summary.id == history.activeCheckpointId)
      .firstOrNull;
  if (activeCheckpoint == null) return null;

  final transcriptMessages = SelectPromptMessagesUsecase.promptEligibleMessages(
    history.messages,
  );
  final selectedMessages = _selectedCheckpointMessages(
    checkpoint.id,
    transcriptMessages,
  );
  if (selectedMessages == null) return null;

  return (
    activeCheckpoint: activeCheckpoint,
    conversationRevision: history.conversationRevision,
    checkpoint: checkpoint,
    replayMessages: List<MessageEntity>.unmodifiable(selectedMessages.skip(1)),
    transcriptMessages: List<MessageEntity>.unmodifiable(history.messages),
  );
}

List<MessageEntity>? _selectedCheckpointMessages(
  String checkpointId,
  List<MessageEntity> transcriptMessages,
) {
  final selectedIds = _selectedCheckpointIds(checkpointId, transcriptMessages);
  final orderedMessages = _messagesInSelectionOrder(
    selectedIds,
    transcriptMessages,
  );

  return orderedMessages?.firstOrNull?.id == checkpointId
      ? orderedMessages
      : null;
}

List<String> _selectedCheckpointIds(
  String checkpointId,
  List<MessageEntity> transcriptMessages,
) => selectAgentPromptHistory(
  MessageTranscriptSnapshotMapper.toAgentContextSnapshot(transcriptMessages),
  activeCompactionCheckpointId: checkpointId,
).messageIds;

List<MessageEntity>? _messagesInSelectionOrder(
  List<String> selectedIds,
  List<MessageEntity> transcriptMessages,
) {
  final messagesById = {
    for (final message in transcriptMessages) message.id: message,
  };
  final selectedMessages = selectedIds.map((id) => messagesById[id]).toList();
  if (selectedMessages.any((message) => message == null)) return null;

  return selectedMessages.whereType<MessageEntity>().toList();
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
  required final _PreviewCheckpointRestore onRestore,
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
  required final _PreviewCheckpointRestore onRestore,
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
  required final _PreviewCheckpointRestore onRestore,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      for (final message in history.summaries)
        _CompactionCheckpointEntry(
          message: message,
          isActive: message.id == history.activeCheckpointId,
          isRestoring: isRestoring,
          onRestore: () => onRestore(message, history),
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
  Widget build(BuildContext _) {
    final from = metadata?.compactedFromMessageId;
    final through = metadata?.compactedThroughMessageId;

    return _CompactionCheckpointDetailRow(
      label: LocaleKeys.compaction_compacted_details_range.tr(),
      value: _rangeValue(from, through),
    );
  }

  static String _rangeValue(String? from, String? through) {
    if (from == null || through == null) {
      return LocaleKeys.compaction_compacted_details_unknown.tr();
    }
    final separator = LocaleKeys.compaction_compacted_details_range_separator
        .tr();

    return '$from $separator $through';
  }
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

class const _CheckpointRestorePreviewDialog({
  required final _CheckpointRestorePreview preview,
}) extends StatefulWidget {
  @override
  State<_CheckpointRestorePreviewDialog> createState() =>
      _CheckpointRestorePreviewDialogState();
}

class _CheckpointRestorePreviewDialogState
    extends State<_CheckpointRestorePreviewDialog> {
  var _responded = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const TextLocale(
      LocaleKeys.compaction_compacted_history_preview_title,
    ),
    content: _CheckpointRestorePreviewContent(preview: widget.preview),
    actions: [
      TextButton(
        onPressed: () => _respond(false),
        child: const TextLocale(
          LocaleKeys.compaction_compacted_history_preview_cancel,
        ),
      ),
      TextButton(
        onPressed: () => _respond(true),
        child: const TextLocale(
          LocaleKeys.compaction_compacted_history_preview_confirm,
        ),
      ),
    ],
    scrollable: true,
  );

  void _respond(bool confirmed) {
    if (_responded) return;
    _responded = true;
    Navigator.of(context).pop(confirmed);
  }
}

class const _CheckpointRestorePreviewContent({
  required final _CheckpointRestorePreview preview,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => SizedBox(
    width: 560,
    child: SingleChildScrollView(
      child: _CheckpointRestorePreviewDetails(preview: preview),
    ),
  );
}

class const _CheckpointRestorePreviewDetails({
  required final _CheckpointRestorePreview preview,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    final activeCheckpoint = preview.activeCheckpoint;
    final targetCheckpoint = preview.checkpoint;
    final summariesMatch = activeCheckpoint.content == targetCheckpoint.content;

    return AuraColumn(
      children: [
        _CheckpointPreviewSection(
          checkpoint: activeCheckpoint,
          headingKey: LocaleKeys.compaction_compacted_history_active,
          isActive: true,
          summaryMatchesActive: true,
        ),
        _CheckpointPreviewSection(
          checkpoint: targetCheckpoint,
          headingKey: _targetCheckpointLabelKey,
          isActive: false,
          summaryMatchesActive: summariesMatch,
        ),
        _CheckpointReplayPlan(preview: preview),
      ],
      crossAxisAlignment: .stretch,
    );
  }
}

class const _CheckpointPreviewSection({
  required final MessageEntity checkpoint,
  required final String headingKey,
  required final bool isActive,
  required final bool summaryMatchesActive,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraColumn(
    children: [
      TextLocale(headingKey, style: .new(fontWeight: FontWeight.bold)),
      _CheckpointPreviewMetadata(checkpoint: checkpoint),
      _CheckpointPreviewSummary(
        checkpoint: checkpoint,
        isActive: isActive,
        summaryMatchesActive: summaryMatchesActive,
      ),
    ],
    crossAxisAlignment: .stretch,
  );
}

class const _CheckpointPreviewMetadata({
  required final MessageEntity checkpoint,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    final metadata = checkpoint.metadata;
    final createdAt = metadata?.compactionCreatedAt ?? checkpoint.createdAt;

    return AuraColumn(
      children: [
        _CheckpointPreviewTimestamp(createdAt: createdAt),
        _CompactionCheckpointRangeRow(metadata: metadata),
        _CompactionCheckpointModelRow(metadata: metadata),
      ],
      crossAxisAlignment: .stretch,
    );
  }
}

class const _CheckpointPreviewTimestamp({required final DateTime createdAt})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final timestamp = DateFormat.yMMMd(locale.toString())
        .add_jm()
        .format(createdAt.toLocal());

    return TextLocale(
      LocaleKeys.compaction_compacted_history_preview_created,
      args: [timestamp],
    );
  }
}

class const _CheckpointPreviewSummary({
  required final MessageEntity checkpoint,
  required final bool isActive,
  required final bool summaryMatchesActive,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraColumn(
    children: [
      const TextLocale(
        LocaleKeys.compaction_compacted_history_preview_summary,
        style: .new(fontWeight: FontWeight.bold),
      ),
      if (!isActive)
        TextLocale(
          summaryMatchesActive
              ? _sameCheckpointSummaryKey
              : _differentCheckpointSummaryKey,
        ),
      if (isActive || !summaryMatchesActive)
        AuraSelectableText(checkpoint.content, style: .bodySmall),
    ],
    crossAxisAlignment: .stretch,
  );
}

class const _CheckpointReplayPlan({
  required final _CheckpointRestorePreview preview,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraColumn(
    children: [
      _CheckpointReplayBoundary(checkpoint: preview.checkpoint),
      _CheckpointReplayCount(count: preview.replayMessages.length),
      _CheckpointReplayMessages(messages: preview.replayMessages),
    ],
    crossAxisAlignment: .stretch,
  );
}

class const _CheckpointReplayBoundary({required final MessageEntity checkpoint})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    final boundary =
        checkpoint.metadata?.compactedThroughMessageId ??
        LocaleKeys.compaction_compacted_details_unknown.tr();

    return TextLocale(
      LocaleKeys.compaction_compacted_history_preview_replay_boundary,
      args: [boundary],
    );
  }
}

class const _CheckpointReplayCount({required final int count})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraColumn(
    children: [
      TextLocale(
        LocaleKeys.compaction_compacted_history_preview_replay_count,
        args: [count.toString()],
      ),
      if (count == 0)
        const TextLocale(
          LocaleKeys.compaction_compacted_history_preview_replay_empty,
        ),
    ],
    crossAxisAlignment: .stretch,
  );
}

class const _CheckpointReplayMessages({
  required final List<MessageEntity> messages,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraColumn(
    children: [
      for (final message in messages)
        _CheckpointReplayMessage(message: message),
    ],
    crossAxisAlignment: .stretch,
  );
}

class const _CheckpointReplayMessage({required final MessageEntity message})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Semantics(
    child: _CheckpointReplayMessageCard(message: message),
    container: true,
  );
}

class const _CheckpointReplayMessageCard({required final MessageEntity message})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraContainer(
    child: _CheckpointReplayMessageContent(message: message),
    padding: .small,
    margin: .small,
    variant: .surfaceVariant,
  );
}

class const _CheckpointReplayMessageContent({
  required final MessageEntity message,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraColumn(
    children: [
      _CheckpointReplayMessageHeading(message: message),
      _CheckpointReplayMessageBody(content: message.content),
      _CheckpointReplayAttachments(attachments: message.attachments),
      _CheckpointReplayToolCalls(
        toolCalls: message.metadata?.toolCalls ?? const [],
      ),
    ],
    crossAxisAlignment: .start,
  );
}

class const _CheckpointReplayMessageBody({required final String content})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => content.isEmpty
      ? const SizedBox.shrink()
      : AuraSelectableText(content, style: .bodySmall);
}

class const _CheckpointReplayMessageHeading({
  required final MessageEntity message,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    final roleLabel =
        (message.isUser
                ? LocaleKeys.compaction_compacted_history_preview_role_user
                : switch (message.messageType) {
                    .system =>
                      LocaleKeys
                          .compaction_compacted_history_preview_role_system,
                    _ =>
                      LocaleKeys
                          .compaction_compacted_history_preview_role_assistant,
                  })
            .tr();

    return TextLocale(
      LocaleKeys.compaction_compacted_history_preview_message_heading,
      args: [roleLabel, message.id],
    );
  }
}

class const _CheckpointReplayAttachments({
  required final List<MessageAttachmentEntity> attachments,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => attachments.isEmpty
      ? const SizedBox.shrink()
      : AuraColumn(
          children: [
            for (final attachment in attachments)
              TextLocale(
                LocaleKeys.compaction_compacted_history_preview_attachment,
                args: [attachment.displayName],
              ),
          ],
          crossAxisAlignment: .start,
        );
}

class const _CheckpointReplayToolCalls({
  required final List<MessageToolCallEntity> toolCalls,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => toolCalls.isEmpty
      ? const SizedBox.shrink()
      : AuraColumn(
          children: [
            for (final toolCall in toolCalls)
              _CheckpointReplayToolCall(toolCall: toolCall),
          ],
          crossAxisAlignment: .start,
        );
}

class const _CheckpointReplayToolCall({
  required final MessageToolCallEntity toolCall,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final result = toolCall.getResponseForAI();

    return AuraColumn(
      children: [
        TextLocale(
          LocaleKeys.compaction_compacted_history_preview_tool_call,
          args: [toolCall.name],
        ),
        if (toolCall.argumentsRaw.isNotEmpty)
          TextLocale(
            LocaleKeys.compaction_compacted_history_preview_tool_arguments,
            args: [toolCall.argumentsRaw],
          ),
        if (result.isNotEmpty)
          TextLocale(
            LocaleKeys.compaction_compacted_history_preview_tool_result,
            args: [result],
          ),
      ],
      crossAxisAlignment: .start,
    );
  }
}
