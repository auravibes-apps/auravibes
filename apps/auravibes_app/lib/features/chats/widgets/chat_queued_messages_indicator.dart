import 'package:auravibes_app/features/chats/notifiers/conversation_queued_draft.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([conversationSelected])
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Text(
                  LocaleKeys
                      .chats_screens_chat_conversation_queued_messages_count
                      .plural(queuedDrafts.length),
                ),
                style: AuraTextStyle.caption,
              ),
              const Spacer(),
              AuraButton(
                onPressed: () => notifier.clear(conversationId),
                child: Text(
                  LocaleKeys.chats_screens_chat_conversation_queued_clear_all
                      .tr(),
                ),
                variant: AuraButtonVariant.text,
                size: AuraButtonSize.small,
              ),
            ],
          ),
          const Divider(height: 1),
          for (final (index, draft) in queuedDrafts.indexed)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AuraText(
                          child: Text(
                            draft.content,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          style: AuraTextStyle.caption,
                        ),
                      ),
                      SizedBox(width: context.auraTheme.spacing.xs),
                      IconButton(
                        padding: const EdgeInsets.all(14),
                        onPressed: () => notifier.remove(
                          conversationId: conversationId,
                          draftId: draft.id,
                        ),
                        tooltip: LocaleKeys.common_remove.tr(),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: const Icon(Icons.close, size: 20),
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
