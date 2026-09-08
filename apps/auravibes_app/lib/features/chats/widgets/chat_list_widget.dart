// Required: Existing test and UI helpers keep compact return flow.
// Required: UI callbacks stay local to their widgets.
// Required: Feature widgets keep closely related private widgets together.
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_options_menu.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const ChatListWidget({required final String workspaceId, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatListAsync = ref.watch(
      conversationsStreamProvider(workspaceId: workspaceId),
    );

    return switch (chatListAsync) {
      AsyncData(value: final chats) => () {
        if (chats.isEmpty) {
          return _ChatListEmptyState(workspaceId: workspaceId);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final chat = chats[index];

            return _ChatTile(chat: chat, workspaceId: workspaceId);
          },
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemCount: chats.length,
        );
      }(),
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncError() => const Center(
        child: AuraText(
          child: TextLocale(LocaleKeys.workspace_management_unexpected_error),
        ),
      ),
    };
  }
}

class const _ChatListEmptyState({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AuraIcon(Icons.chat_outlined, size: AuraIconSize.extraLarge),
            const SizedBox(height: 16),
            const AuraText(
              child: TextLocale(
                LocaleKeys.home_screen_conversation_states_no_chats_yet,
              ),
              style: AuraTextStyle.heading3,
            ),
            const SizedBox(height: 8),
            const AuraText(
              child: TextLocale(
                LocaleKeys
                    .home_screen_conversation_states_start_first_conversation,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AuraButton(
              onPressed: () {
                NewChatRoute(workspaceId: workspaceId).go(context);
              },
              child: const TextLocale(
                LocaleKeys.home_screen_actions_start_new_chat,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class const _ChatTile({
  required final ConversationEntity chat,
  required final String workspaceId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceModelSelectionsAsync = ref.watch(
      listWorkspaceModelSelectionsProvider(workspaceId: workspaceId),
    );
    final modelDisplayName = workspaceModelSelectionsAsync.asData?.value
        .where((cm) => cm.workspaceModelSelection.id == chat.modelId)
        .firstOrNull
        ?.workspaceModelSelection
        .modelId;
    final title = ref.watch(streamingTitleProvider(chat.id)) ?? chat.title;

    return AuraCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (chat.isPinned) ...[
                      const AuraIcon(
                        Icons.push_pin_outlined,
                        size: AuraIconSize.small,
                        tint: AuraTint.warning,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: AuraText(
                        child: Text(title, overflow: TextOverflow.ellipsis),
                        style: AuraTextStyle.heading6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AuraText(
                  child: Text(
                    RelativeTimeFormatter.format(chat.updatedAt),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: AuraTextStyle.bodySmall,
                ),
              ],
            ),
          ),
          if (modelDisplayName != null) ...[
            const SizedBox(width: 8),
            AuraBadge.text(
              child: Text(modelDisplayName),
              variant: AuraBadgeVariant.info,
            ),
          ],
          const SizedBox(width: 8),
          ConversationOptionsMenu(conversation: chat),
        ],
      ),
      onTap: () => _openConversation(context),
      style: AuraCardStyle.border,
    );
  }

  void _openConversation(BuildContext context) {
    ConversationRoute(workspaceId: workspaceId, chatId: chat.id).go(context);
  }
}
