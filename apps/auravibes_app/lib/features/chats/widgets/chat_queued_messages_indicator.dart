import 'package:auravibes_app/features/chats/notifiers/conversation_send_queue_notifier.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ChatQueuedMessagesIndicator extends StatelessWidget {
  const ChatQueuedMessagesIndicator({
    required this.queuedDrafts,
    super.key,
  });

  final List<ConversationQueuedDraft> queuedDrafts;

  @override
  Widget build(BuildContext context) {
    if (queuedDrafts.isEmpty) {
      return const SizedBox.shrink();
    }

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
            ],
          ),
          SizedBox(height: context.auraTheme.spacing.xs),
          for (final draft in queuedDrafts)
            Padding(
              padding: EdgeInsets.only(top: context.auraTheme.spacing.xs),
              child: AuraText(
                style: AuraTextStyle.caption,
                child: Text(
                  draft.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
