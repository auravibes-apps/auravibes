import 'package:auravibes_app/features/chats/notifiers/conversation_send_queue_notifier.dart';
import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatQueuedMessagesIndicator extends ConsumerStatefulWidget {
  const ChatQueuedMessagesIndicator({
    required this.queuedDrafts,
    super.key,
  });

  final List<ConversationQueuedDraft> queuedDrafts;

  @override
  ConsumerState<ChatQueuedMessagesIndicator> createState() =>
      _ChatQueuedMessagesIndicatorState();
}

class _ChatQueuedMessagesIndicatorState
    extends ConsumerState<ChatQueuedMessagesIndicator> {
  @override
  Widget build(BuildContext context) {
    if (widget.queuedDrafts.isEmpty) {
      return const SizedBox.shrink();
    }

    final conversationId = ref.read(conversationSelectedProvider);
    final notifier = ref.read(conversationSendQueueProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AuraBadge.count(
                count: widget.queuedDrafts.length,
                variant: AuraBadgeVariant.neutral,
                size: AuraBadgeSize.small,
              ),
              SizedBox(width: context.auraTheme.spacing.sm),
              AuraText(
                style: AuraTextStyle.caption,
                child: Text(
                  LocaleKeys
                      .chats_screens_chat_conversation_queued_messages_count
                      .plural(widget.queuedDrafts.length),
                ),
              ),
              const Spacer(),
              AuraButton(
                variant: AuraButtonVariant.text,
                size: AuraButtonSize.small,
                onPressed: () => notifier.clearAll(conversationId),
                child: Text(
                  LocaleKeys.chats_screens_chat_conversation_queued_clear_all
                      .tr(),
                ),
              ),
            ],
          ),
          SizedBox(height: context.auraTheme.spacing.xs),
          for (final draft in widget.queuedDrafts)
            Padding(
              padding: EdgeInsets.only(top: context.auraTheme.spacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: AuraText(
                      style: AuraTextStyle.caption,
                      child: Text(
                        draft.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(width: context.auraTheme.spacing.xs),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => notifier.remove(
                      conversationId: conversationId,
                      draftId: draft.id,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
