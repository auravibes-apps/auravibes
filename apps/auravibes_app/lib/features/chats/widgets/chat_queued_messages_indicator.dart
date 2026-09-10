// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const ChatQueuedMessagesIndicator({
  required final String conversationId,
  required final List<ConversationQueuedDraft> queuedDrafts,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (queuedDrafts.isEmpty) return const SizedBox.shrink();

    final notifier = ref.read(conversationSendQueueProvider.notifier);

    return _QueuedMessagesLayout(
      queuedDrafts: queuedDrafts,
      onClear: () => notifier.clear(conversationId),
      onRemove: (draftId) =>
          notifier.remove(conversationId: conversationId, draftId: draftId),
    );
  }
}

class const _QueuedMessagesLayout({
  required final List<ConversationQueuedDraft> queuedDrafts,
  required final VoidCallback onClear,
  required final void Function(String draftId) onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: context.auraTheme.fromSpacing(.md),
    ),
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        _QueuedMessagesHeader(count: queuedDrafts.length, onClear: onClear),
        const AuraDivider(),
        _QueuedDraftList(queuedDrafts: queuedDrafts, onRemove: onRemove),
      ],
    ),
  );
}

class const _QueuedMessagesHeader({
  required final int count,
  required final VoidCallback onClear,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      AuraBadge.count(count: count, variant: .neutral, size: .small),
      const AuraSizedBox(width: .sm),
      AuraText(
        child: Text(
          LocaleKeys.chats_screens_chat_conversation_queued_messages_count
              .plural(count),
        ),
        style: .caption,
      ),
      const Spacer(),
      _QueuedClearButton(onClear: onClear),
    ],
  );
}

class const _QueuedClearButton({required final VoidCallback onClear})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onClear,
    child: Text(
      LocaleKeys.chats_screens_chat_conversation_queued_clear_all.tr(),
    ),
    variant: .text,
    size: .small,
  );
}

class const _QueuedDraftList({
  required final List<ConversationQueuedDraft> queuedDrafts,
  required final void Function(String draftId) onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      for (final (index, draft) in queuedDrafts.indexed)
        _QueuedDraftRow(
          draft: draft,
          showDivider: index < queuedDrafts.length - 1,
          onRemove: onRemove,
        ),
    ],
  );
}

class const _QueuedDraftRow({
  required final ConversationQueuedDraft draft,
  required final bool showDivider,
  required final void Function(String draftId) onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      _QueuedDraftContent(draft: draft, onRemove: onRemove),
      if (showDivider) const AuraDivider(),
    ],
  );
}

class const _QueuedDraftContent({
  required final ConversationQueuedDraft draft,
  required final void Function(String draftId) onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: context.auraTheme.fromSpacing(.xs)),
    child: _QueuedDraftTextRow(draft: draft, onRemove: onRemove),
  );
}

class const _QueuedDraftTextRow({
  required final ConversationQueuedDraft draft,
  required final void Function(String draftId) onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: AuraText(
          child: Text(draft.content, overflow: .ellipsis, maxLines: 1),
          style: .caption,
        ),
      ),
      const AuraSizedBox(width: .xs),
      _QueuedDraftRemoveButton(draftId: draft.id, onRemove: onRemove),
    ],
  );
}

class const _QueuedDraftRemoveButton({
  required final String draftId,
  required final void Function(String draftId) onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.close,
    onPressed: () => onRemove(draftId),
    size: .large,
    tooltip: LocaleKeys.common_remove.tr(),
  );
}
