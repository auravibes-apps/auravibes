// Required: UI callbacks stay local to their widgets.
import 'package:auravibes_app/features/chats/widgets/chat_list_widget.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_content.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const ChatsListScreen({required final String workspaceId, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraScreen(
      child: _ChatsListBody(workspaceId: workspaceId),
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale(LocaleKeys.chats_screens_chats_list_title),
      ),
    );
  }
}

class const _ChatsListBody({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _ChatsListAddChatButton(workspaceId: workspaceId),
        Expanded(child: ChatListWidget(workspaceId: workspaceId)),
      ],
    );
  }
}

class const _ChatsListAddChatButton({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraPadding(
      child: AppContent(
        child: _ChatsListNewChatButton(workspaceId: workspaceId),
      ),
      padding: const .horizontal(.md),
    );
  }
}

class const _ChatsListNewChatButton({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AuraButton(
            onPressed: () {
              NewChatRoute(workspaceId: workspaceId).go(context);
            },
            child: const TextLocale(
              LocaleKeys.chats_screens_chats_list_add_chat,
            ),
          ),
        ),
      ],
    );
  }
}
