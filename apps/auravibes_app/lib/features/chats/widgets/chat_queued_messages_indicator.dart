// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ChatQueuedMessagesIndicator({
  required final String conversationId,
  required final List<ConversationQueuedDraft> queuedDrafts,
  final ValueChanged<ChatDraft>? onEditDraft,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (queuedDrafts.isEmpty) return const SizedBox.shrink();

    final notifier = ref.read(conversationSendQueueProvider.notifier);
    final onEditDraft = this.onEditDraft;

    return _QueuedMessagesLayout(
      queuedDrafts: queuedDrafts,
      onClear: () => notifier.clear(conversationId),
      onRemove: (draftId) =>
          notifier.remove(conversationId: conversationId, draftId: draftId),
      onEditDraft: onEditDraft == null
          ? null
          : (draft) {
              onEditDraft(draft.draft);
              notifier.remove(
                conversationId: conversationId,
                draftId: draft.id,
              );
            },
    );
  }
}

class const _QueuedMessagesLayout({
  required final List<ConversationQueuedDraft> queuedDrafts,
  required final VoidCallback onClear,
  required final void Function(String draftId) onRemove,
  required final ValueChanged<ConversationQueuedDraft>? onEditDraft,
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
        _QueuedDraftList(
          queuedDrafts: queuedDrafts,
          onRemove: onRemove,
          onEditDraft: onEditDraft,
        ),
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
  required final ValueChanged<ConversationQueuedDraft>? onEditDraft,
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
          onEditDraft: onEditDraft,
        ),
    ],
  );
}

class const _QueuedDraftRow({
  required final ConversationQueuedDraft draft,
  required final bool showDivider,
  required final void Function(String draftId) onRemove,
  required final ValueChanged<ConversationQueuedDraft>? onEditDraft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      _QueuedDraftContent(
        draft: draft,
        onRemove: onRemove,
        onEditDraft: onEditDraft,
      ),
      if (showDivider) const AuraDivider(),
    ],
  );
}

class const _QueuedDraftContent({
  required final ConversationQueuedDraft draft,
  required final void Function(String draftId) onRemove,
  required final ValueChanged<ConversationQueuedDraft>? onEditDraft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: context.auraTheme.fromSpacing(.xs)),
    child: _QueuedDraftTextRow(
      draft: draft,
      onRemove: onRemove,
      onEditDraft: onEditDraft,
    ),
  );
}

class const _QueuedDraftTextRow({
  required final ConversationQueuedDraft draft,
  required final void Function(String draftId) onRemove,
  required final ValueChanged<ConversationQueuedDraft>? onEditDraft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onEditDraft = this.onEditDraft;

    return Row(
      children: [
        Expanded(
          child: AuraText(
            child: Text(draft.content, overflow: .ellipsis, maxLines: 1),
            style: .caption,
          ),
        ),
        if (onEditDraft != null) ...[
          const AuraSizedBox(width: .xs),
          _QueuedDraftEditButton(draft: draft, onEdit: onEditDraft),
        ],
        const AuraSizedBox(width: .xs),
        _QueuedDraftRemoveButton(draftId: draft.id, onRemove: onRemove),
      ],
    );
  }
}

class const _QueuedDraftEditButton({
  required final ConversationQueuedDraft draft,
  required final ValueChanged<ConversationQueuedDraft> onEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.edit_outlined,
    onPressed: () => onEdit(draft),
    size: .large,
    tooltip: LocaleKeys.common_edit.tr(),
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
