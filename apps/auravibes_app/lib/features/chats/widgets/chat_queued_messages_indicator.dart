import 'package:auravibes_app/features/chats/notifiers/conversation_send_queue_notifier.dart';
import 'package:auravibes_app/features/chats/providers/messages_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatQueuedMessagesIndicator extends ConsumerWidget {
  const ChatQueuedMessagesIndicator({
    required this.queuedDrafts,
    super.key,
  });

  final List<ConversationQueuedDraft> queuedDrafts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (queuedDrafts.isEmpty) {
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
                count: queuedDrafts.length,
                variant: AuraBadgeVariant.neutral,
                size: AuraBadgeSize.small,
              ),
              SizedBox(width: context.auraTheme.spacing.sm),
              AuraText(
                style: AuraTextStyle.caption,
                child: Text(
                  LocaleKeys
                      .chats_screens_chat_conversation_queued_messages_count
                      .plural(queuedDrafts.length),
                ),
              ),
              const Spacer(),
              AuraButton(
                variant: AuraButtonVariant.text,
                size: AuraButtonSize.small,
                onPressed: () => notifier.clear(conversationId),
                child: Text(
                  LocaleKeys.chats_screens_chat_conversation_queued_clear_all
                      .tr(),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          for (final (index, draft) in queuedDrafts.indexed)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignSpacing.xs,
                  ),
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
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => notifier.remove(
                          conversationId: conversationId,
                          draftId: draft.id,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        padding: const EdgeInsets.all(14),
                        tooltip: LocaleKeys.common_remove.tr(),
                      ),
                    ],
                  ),
                ),
                if (index < queuedDrafts.length - 1) const Divider(height: 1),
              ],
            ),
        ],
      ),
    );
  }
}
