import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class const ChatThinkingIndicator({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.auraTheme.fromSpacing(.md),
      ),
      child: Row(
        children: [
          const AuraTypingIndicator(
            size: AuraTypingIndicatorSize.small,
            showContainer: false,
          ),
          const AuraSizedBox(width: .sm),
          Flexible(
            child: AuraText(
              child: Text(
                LocaleKeys.chats_screens_chat_conversation_thinking_status.tr(),
              ),
              style: AuraTextStyle.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
