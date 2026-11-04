// Required: Existing code repeats lookups where extraction adds noise.
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef _MoveQueuedDraft = void Function(String draftId, int offset);

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
      onClear: _createClearCallback(notifier, conversationId),
      onRemove: _createRemoveCallback(notifier, conversationId),
      onMove: _createMoveCallback(notifier, conversationId),
      onEditDraft: _createEditDraftCallback(
        onEditDraft,
        notifier,
        conversationId,
      ),
    );
  }
}

VoidCallback _createClearCallback(
  ConversationSendQueue notifier,
  String conversationId,
) =>
    () => notifier.clear(conversationId);

void Function(String draftId) _createRemoveCallback(
  ConversationSendQueue notifier,
  String conversationId,
) =>
    (draftId) =>
        notifier.remove(conversationId: conversationId, draftId: draftId);

_MoveQueuedDraft _createMoveCallback(
  ConversationSendQueue notifier,
  String conversationId,
) =>
    (draftId, offset) => notifier.move(
      conversationId: conversationId,
      draftId: draftId,
      offset: offset,
    );

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
  required final _MoveQueuedDraft onMove,
  required final ValueChanged<ConversationQueuedDraft>? onEditDraft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: context.auraTheme.fromSpacing(.md),
    ),
    child: _QueuedMessagesColumn(
      queuedDrafts: queuedDrafts,
      onClear: onClear,
      onRemove: onRemove,
      onMove: onMove,
      onEditDraft: onEditDraft,
    ),
  );
}

class const _QueuedMessagesColumn({
  required final List<ConversationQueuedDraft> queuedDrafts,
  required final VoidCallback onClear,
  required final void Function(String draftId) onRemove,
  required final _MoveQueuedDraft onMove,
  required final ValueChanged<ConversationQueuedDraft>? onEditDraft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      _QueuedMessagesHeader(count: queuedDrafts.length, onClear: onClear),
      const AuraDivider(),
      _QueuedDraftList(
        queuedDrafts: queuedDrafts,
        onRemove: onRemove,
        onMove: onMove,
        onEditDraft: onEditDraft,
      ),
    ],
  );
}

class const _QueuedMessagesHeader({
  required final int count,
  required final VoidCallback onClear,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      ExcludeSemantics(
        child: AuraBadge.count(count: count, variant: .neutral, size: .small),
      ),
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
  required final _MoveQueuedDraft onMove,
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
          onMove: onMove,
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
  required final _MoveQueuedDraft onMove,
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
        onMove: onMove,
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
  required final _MoveQueuedDraft onMove,
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
      onMove: onMove,
      onEditDraft: onEditDraft,
    ),
  );
}

class const _QueuedDraftTextRow({
  required final ConversationQueuedDraft draft,
  required final bool canMoveUp,
  required final bool canMoveDown,
  required final void Function(String draftId) onRemove,
  required final _MoveQueuedDraft onMove,
  required final ValueChanged<ConversationQueuedDraft>? onEditDraft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _QueuedDraftText(content: draft.content),
      const AuraSizedBox(width: .xs),
      _QueuedDraftActions(
        draft: draft,
        canMoveUp: canMoveUp,
        canMoveDown: canMoveDown,
        onRemove: onRemove,
        onMove: onMove,
        onEditDraft: onEditDraft,
      ),
    ],
  );
}

class const _QueuedDraftActions({
  required final ConversationQueuedDraft draft,
  required final bool canMoveUp,
  required final bool canMoveDown,
  required final void Function(String draftId) onRemove,
  required final _MoveQueuedDraft onMove,
  required final ValueChanged<ConversationQueuedDraft>? onEditDraft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        _QueuedDraftEditAction(draft: draft, onEditDraft: onEditDraft),
        _QueuedDraftActionsMenu(
          draftId: draft.id,
          canMoveUp: canMoveUp,
          canMoveDown: canMoveDown,
          onMove: onMove,
        ),
        const AuraSizedBox(width: .xs),
        _QueuedDraftRemoveButton(draftId: draft.id, onRemove: onRemove),
      ],
    );
  }
}

class const _QueuedDraftEditAction({
  required final ConversationQueuedDraft draft,
  required final ValueChanged<ConversationQueuedDraft>? onEditDraft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onEditDraft = this.onEditDraft;
    if (onEditDraft == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: .min,
      children: [
        _QueuedDraftEditButton(draft: draft, onEdit: onEditDraft),
        const AuraSizedBox(width: .xs),
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
  required final _MoveQueuedDraft onMove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraPopupMenuButton(
    items: _queuedDraftMoveItems(draftId, canMoveUp, canMoveDown, onMove),
    identifier: 'queued-prompt-$draftId-actions',
    tooltip: _queuedItemActionsKey.tr(),
  );
}

List<AuraPopupMenuItem> _queuedDraftMoveItems(
  String draftId,
  bool canMoveUp,
  bool canMoveDown,
  _MoveQueuedDraft onMove,
) => [
  _queuedDraftMoveItem(_queuedDraftMoveUpItem(draftId, canMoveUp, onMove)),
  _queuedDraftMoveItem(_queuedDraftMoveDownItem(draftId, canMoveDown, onMove)),
];

typedef _QueuedDraftMoveMenuItem = ({
  String draftId,
  String direction,
  String title,
  IconData icon,
  bool canMove,
  int offset,
  _MoveQueuedDraft onMove,
});

_QueuedDraftMoveMenuItem _queuedDraftMoveUpItem(
  String draftId,
  bool canMove,
  _MoveQueuedDraft onMove,
) => (
  draftId: draftId,
  direction: 'up',
  title: _queuedMoveUpKey.tr(),
  icon: Icons.arrow_upward,
  canMove: canMove,
  offset: -1,
  onMove: onMove,
);

_QueuedDraftMoveMenuItem _queuedDraftMoveDownItem(
  String draftId,
  bool canMove,
  _MoveQueuedDraft onMove,
) => (
  draftId: draftId,
  direction: 'down',
  title: _queuedMoveDownKey.tr(),
  icon: Icons.arrow_downward,
  canMove: canMove,
  offset: 1,
  onMove: onMove,
);

AuraPopupMenuItem _queuedDraftMoveItem(_QueuedDraftMoveMenuItem item) =>
    AuraPopupMenuItem(
      title: Text(item.title),
      onTap: item.canMove ? () => item.onMove(item.draftId, item.offset) : null,
      leading: AuraIcon(item.icon, size: .small),
      identifier: 'queued-prompt-${item.draftId}-move-${item.direction}',
    );

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
