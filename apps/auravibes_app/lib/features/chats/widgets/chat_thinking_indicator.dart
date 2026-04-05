import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ChatThinkingIndicator extends StatelessWidget {
  const ChatThinkingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSpacing.md),
      child: Row(
        children: [
          const AuraTypingIndicator(
            size: AuraTypingIndicatorSize.small,
            showContainer: false,
          ),
          SizedBox(width: context.auraTheme.spacing.sm),
          Flexible(
            child: AuraText(
              style: AuraTextStyle.bodySmall,
              child: Text(
                LocaleKeys.chats_screens_chat_conversation_thinking_status.tr(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
