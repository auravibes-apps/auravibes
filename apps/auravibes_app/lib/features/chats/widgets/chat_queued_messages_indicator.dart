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

    return _QueuedMessagesContent(
      conversationId: conversationId,
      queuedDrafts: queuedDrafts,
      onEditDraft: onEditDraft,
    );
  }
}

class const _QueuedMessagesContent({
  required final String conversationId,
  required final List<ConversationQueuedDraft> queuedDrafts,
  required final ValueChanged<ChatDraft>? onEditDraft,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(conversationSendQueueProvider.notifier);

    return _QueuedMessagesLayout(
      queuedDrafts: queuedDrafts,
      onClear: () => notifier.clear(conversationId),
      onRemove: (draftId) =>
          notifier.remove(conversationId: conversationId, draftId: draftId),
      onMoveUp: (draftId) =>
          notifier.moveUp(conversationId: conversationId, draftId: draftId),
      onMoveDown: (draftId) => notifier.moveDown(
        conversationId: conversationId,
        draftId: draftId,
      ),
      onEditDraft: _createEditDraftCallback(
        onEditDraft,
        notifier,
        conversationId,
      ),
    );
  }
}

ValueChanged<ConversationQueuedDraft>? _createEditDraftCallback(
  ValueChanged<ChatDraft>? onEditDraft,
  ConversationSendQueue notifier,
  String conversationId,
) {
  if (onEditDraft == null) return null;

  return (draft) {
    onEditDraft(draft.draft);
    final _ = notifier.take(conversationId: conversationId, draftId: draft.id);
  };
}

class const _QueuedMessagesLayout({
  required final List<ConversationQueuedDraft> queuedDrafts,
  required final VoidCallback onClear,
  required final void Function(String draftId) onRemove,
  required final void Function(String draftId) onMoveUp,
  required final void Function(String draftId) onMoveDown,
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
          onMoveUp: onMoveUp,
          onMoveDown: onMoveDown,
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
  required final void Function(String draftId) onMoveUp,
  required final void Function(String draftId) onMoveDown,
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
          canMoveUp: index > 0,
          canMoveDown: index < queuedDrafts.length - 1,
          onRemove: onRemove,
          onMoveUp: onMoveUp,
          onMoveDown: onMoveDown,
          onEditDraft: onEditDraft,
        ),
    ],
  );
}

class const _QueuedDraftRow({
  required final ConversationQueuedDraft draft,
  required final bool showDivider,
  required final bool canMoveUp,
  required final bool canMoveDown,
  required final void Function(String draftId) onRemove,
  required final void Function(String draftId) onMoveUp,
  required final void Function(String draftId) onMoveDown,
  required final ValueChanged<ConversationQueuedDraft>? onEditDraft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      _QueuedDraftContent(
        draft: draft,
        canMoveUp: canMoveUp,
        canMoveDown: canMoveDown,
        onRemove: onRemove,
        onMoveUp: onMoveUp,
        onMoveDown: onMoveDown,
        onEditDraft: onEditDraft,
      ),
      if (showDivider) const AuraDivider(),
    ],
  );
}

class const _QueuedDraftContent({
  required final ConversationQueuedDraft draft,
  required final bool canMoveUp,
  required final bool canMoveDown,
  required final void Function(String draftId) onRemove,
  required final void Function(String draftId) onMoveUp,
  required final void Function(String draftId) onMoveDown,
  required final ValueChanged<ConversationQueuedDraft>? onEditDraft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: context.auraTheme.fromSpacing(.xs)),
    child: _QueuedDraftTextRow(
      draft: draft,
      canMoveUp: canMoveUp,
      canMoveDown: canMoveDown,
      onRemove: onRemove,
      onMoveUp: onMoveUp,
      onMoveDown: onMoveDown,
      onEditDraft: onEditDraft,
    ),
  );
}

class const _QueuedDraftTextRow({
  required final ConversationQueuedDraft draft,
  required final bool canMoveUp,
  required final bool canMoveDown,
  required final void Function(String draftId) onRemove,
  required final void Function(String draftId) onMoveUp,
  required final void Function(String draftId) onMoveDown,
  required final ValueChanged<ConversationQueuedDraft>? onEditDraft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onEditDraft = this.onEditDraft;

    return Row(
      children: [
        _QueuedDraftText(content: draft.content),
        if (onEditDraft != null) ...[
          const AuraSizedBox(width: .xs),
          _QueuedDraftEditButton(draft: draft, onEdit: onEditDraft),
        ],
        const AuraSizedBox(width: .xs),
        _QueuedDraftActionsMenu(
          draftId: draft.id,
          canMoveUp: canMoveUp,
          canMoveDown: canMoveDown,
          onMoveUp: onMoveUp,
          onMoveDown: onMoveDown,
        ),
        const AuraSizedBox(width: .xs),
        _QueuedDraftRemoveButton(draftId: draft.id, onRemove: onRemove),
      ],
    );
  }
}

const _queuedItemActionsKey =
    'chats_screens.chat_conversation.queued_item_actions';
const _queuedMoveUpKey = 'chats_screens.chat_conversation.queued_move_up';
const _queuedMoveDownKey = 'chats_screens.chat_conversation.queued_move_down';

class const _QueuedDraftActionsMenu({
  required final String draftId,
  required final bool canMoveUp,
  required final bool canMoveDown,
  required final void Function(String draftId) onMoveUp,
  required final void Function(String draftId) onMoveDown,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPopupMenuButton(
    icon: Icons.more_vert,
    tooltip: _queuedItemActionsKey.tr(),
    identifier: 'queued-prompt-$draftId-actions',
    items: [
      AuraPopupMenuItem(
        title: Text(_queuedMoveUpKey.tr()),
        leading: const AuraIcon(Icons.arrow_upward, size: .small),
        onTap: canMoveUp ? () => onMoveUp(draftId) : null,
        identifier: 'queued-prompt-$draftId-move-up',
      ),
      AuraPopupMenuItem(
        title: Text(_queuedMoveDownKey.tr()),
        leading: const AuraIcon(Icons.arrow_downward, size: .small),
        onTap: canMoveDown ? () => onMoveDown(draftId) : null,
        identifier: 'queued-prompt-$draftId-move-down',
      ),
    ],
  );
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

class const _QueuedDraftText({required final String content})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    child: AuraText(
      child: Text(content, overflow: .ellipsis, maxLines: 1),
      style: .caption,
    ),
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
