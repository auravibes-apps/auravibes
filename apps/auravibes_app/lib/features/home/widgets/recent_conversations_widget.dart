import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/models/providers/list_chat_models_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/presentation/shared/formatters/relative_time_formatter.dart';
import 'package:auravibes_app/router/app_router.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RecentConversationsWidget extends ConsumerWidget {
  const RecentConversationsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatListAsync = ref.watch(conversationsStreamProvider(limit: 5));

    return switch (chatListAsync) {
      AsyncData(value: final chats) => () {
        if (chats.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: chats
              .map(
                (chat) => AuraPadding(
                  padding: const .only(bottom: .base),
                  child: _RecentChatTile(chat: chat),
                ),
              )
              .toList(),
        );
      }(),
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncError(:final error, stackTrace: _) => Center(
        child: AuraText(
          color: AuraColorVariant.error,
          child: TextLocale(
            LocaleKeys
                .home_screen_conversation_states_error_loading_conversations,
            args: [error.toString()],
          ),
        ),
      ),
    };
  }

  Widget _buildEmptyState(BuildContext context) {
    return AuraCard(
      child: AuraPadding(
        padding: AuraEdgeInsetsGeometry.small,
        child: AuraColumn(
          children: [
            const AuraIcon(
              Icons.chat_outlined,
              size: AuraIconSize.large,
              color: AuraColorVariant.onSurfaceVariant,
            ),
            const AuraText(
              style: AuraTextStyle.heading6,
              child: TextLocale(
                LocaleKeys.home_screen_conversation_states_no_conversations,
              ),
            ),
            const AuraText(
              style: AuraTextStyle.bodySmall,
              color: AuraColorVariant.onSurfaceVariant,
              child: TextLocale(
                LocaleKeys
                    .home_screen_conversation_states_start_first_conversation,

                textAlign: TextAlign.center,
              ),
            ),
            AuraButton(
              variant: AuraButtonVariant.outlined,
              onPressed: () => NewChatRoute().go(context),
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

class _RecentChatTile extends ConsumerWidget {
  const _RecentChatTile({required this.chat});

  final ConversationEntity chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelDisplayName = ref.watch(
      listCredentialsCredentialsProvider.select(
        (cms) => cms.value
            ?.firstWhereOrNull((cm) => cm.credentialsModel.id == chat.modelId)
            ?.credentialsModel
            .modelId,
      ),
    );
    final title = ref.watch(streamingTitleProvider(chat.id)) ?? chat.title;

    return AuraCard(
      onTap: () {
        ConversationRoute(chatId: chat.id).go(context);
      },
      child: AuraPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuraRow(
                        children: [
                          if (chat.isPinned) ...[
                            const AuraIcon(
                              Icons.push_pin_outlined,
                              size: AuraIconSize.small,
                              color: AuraColorVariant.warning,
                            ),
                          ],
                          Expanded(
                            child: AuraText(
                              style: AuraTextStyle.heading6,
                              child: Text(
                                title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AuraText(
                        style: AuraTextStyle.bodySmall,
                        color: AuraColorVariant.onSurfaceVariant,
                        child: Text(
                          formatRelativeTime(chat.updatedAt),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (modelDisplayName != null) ...[
                  AuraBadge.text(
                    variant: AuraBadgeVariant.info,
                    child: Text(modelDisplayName),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
