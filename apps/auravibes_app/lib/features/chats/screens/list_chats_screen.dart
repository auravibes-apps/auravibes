import 'package:auravibes_app/features/chats/widgets/chat_list_widget.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/app_router.dart';
import 'package:auravibes_app/widgets/app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/app_content.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraScreen(
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.chats_screens_chats_list_title),
      ),
      child: AuraColumn(
        children: [
          AuraPadding(
            padding: const .horizontal(.md),
            child: AppContent(
              child: Row(
                children: [
                  Expanded(
                    child: AuraButton(
                      onPressed: () {
                        NewChatRoute().go(context);
                      },
                      child: const TextLocale(
                        LocaleKeys.chats_screens_chats_list_add_chat,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Expanded(child: ChatListWidget()),
        ],
      ),
    );
  }
}
