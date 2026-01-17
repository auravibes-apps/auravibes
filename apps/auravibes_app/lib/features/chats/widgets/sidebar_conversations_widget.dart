import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/router/app_router.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _currentChatIdProvider = Provider<String?>(
  (ref) {
    final pathSegments = ref.watch(routerPathSegmentsProvider);
    if (pathSegments.isEmpty) return null;
    if (pathSegments[0] != 'chats') return null;
    if (pathSegments.length < 2) return null;
    final chatId = pathSegments[1];
    return chatId;
  },
);

class SidebarConversationsWidget extends ConsumerWidget {
  const SidebarConversationsWidget({
    super.key,
    this.limit = 10,
  });

  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentChatId = ref.watch(_currentChatIdProvider);
    final chatListAsync = ref.watch(conversationsListProvider);

    return switch (chatListAsync) {
      AsyncData(value: final chats) => () {
        final limitedChats = chats.take(limit).toList();

        if (limitedChats.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: [
            _buildSectionHeader(context),
            ...limitedChats.map(
              (chat) => _SidebarConversationTile(
                chat: chat,
                isActive: chat.id == currentChatId,
              ),
            ),
            _buildViewAllButton(context),
          ],
        );
      }(),
      AsyncLoading() => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: context.auraTheme.spacing.md,
          ),
          child: const AuraSpinner(),
        ),
      ),
      AsyncError(error: final error, stackTrace: _) => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: context.auraTheme.spacing.md,
            horizontal: context.auraTheme.spacing.sm,
          ),
          child: AuraText(
            style: AuraTextStyle.bodySmall,
            color: AuraColorVariant.error,
            child: TextLocale(
              LocaleKeys
                  .home_screen_conversation_states_error_loading_conversations,
              args: [error.toString()],
            ),
          ),
        ),
      ),
    };
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.auraTheme.spacing.sm,
        vertical: context.auraTheme.spacing.xs,
      ),
      child: const AuraText(
        style: AuraTextStyle.caption,
        color: AuraColorVariant.onSurfaceVariant,
        child: TextLocale(
          LocaleKeys.sidebar_recent_chats,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.auraTheme.spacing.sm,
        vertical: context.auraTheme.spacing.md,
      ),
      child: const AuraText(
        style: AuraTextStyle.bodySmall,
        color: AuraColorVariant.onSurfaceVariant,
        textAlign: TextAlign.center,
        child: TextLocale(
          LocaleKeys.sidebar_no_recent_chats,
        ),
      ),
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: context.auraTheme.spacing.sm,
        right: context.auraTheme.spacing.sm,
        top: context.auraTheme.spacing.xs,
        bottom: context.auraTheme.spacing.md,
      ),
      child: AuraButton(
        variant: AuraButtonVariant.ghost,
        size: AuraButtonSize.small,
        isFullWidth: true,
        onPressed: () => ChatsRoute().go(context),
        child: const TextLocale(
          LocaleKeys.sidebar_view_all_chats,
        ),
      ),
    );
  }
}

class _SidebarConversationTile extends StatelessWidget {
  const _SidebarConversationTile({
    required this.chat,
    required this.isActive,
  });

  final ConversationEntity chat;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.auraTheme.spacing.sm,
        vertical: context.auraTheme.spacing.xs,
      ),
      child: AuraTile(
        variant: isActive ? AuraTileVariant.surface : AuraTileVariant.ghost,
        size: AuraTileSize.small,
        onTap: () => CoversationRoute(chatId: chat.id).go(context),
        leading: isActive
            ? AuraIcon(
                Icons.chat_bubble_outline,
                size: AuraIconSize.small,
                color: context.auraColors.primary,
              )
            : AuraIcon(
                Icons.chat_bubble_outline,
                size: AuraIconSize.small,
                color: context.auraColors.onSurfaceVariant,
              ),
        child: AuraText(
          style: AuraTextStyle.bodySmall,
          color: isActive ? AuraColorVariant.primary : null,
          child: Text(
            chat.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
