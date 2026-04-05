import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/models/providers/list_chat_models_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/presentation/shared/formatters/relative_time_formatter.dart';
import 'package:auravibes_app/router/app_router.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatListWidget extends ConsumerWidget {
  const ChatListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatListAsync = ref.watch(conversationsStreamProvider());

    return switch (chatListAsync) {
      AsyncData(value: final chats) => () {
        if (chats.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            return _ChatTile(chat: chat);
          },
        );
      }(),
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncError(:final error, stackTrace: _) => Center(
        child: AuraText(
          child: Text('Error loading chats: $error'),
        ),
      ),
    };
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AuraIcon(
              Icons.chat_outlined,
              size: AuraIconSize.extraLarge,
              color: AuraColorVariant.onSurfaceVariant,
            ),
            SizedBox(height: 16),
            AuraText(
              style: AuraTextStyle.heading3,
              child: Text('No Chats Yet'),
            ),
            SizedBox(height: 8),
            AuraText(
              textAlign: TextAlign.center,
              child: Text('Start your first conversation with Aura AI'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends ConsumerStatefulWidget {
  const _ChatTile({required this.chat});

  final ConversationEntity chat;

  @override
  ConsumerState<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends ConsumerState<_ChatTile> {
  final _menuController = AuraPopupMenuController();

  @override
  void dispose() {
    _menuController.close();
    super.dispose();
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          LocaleKeys.chats_screens_chat_conversation_delete_title.tr(),
        ),
        content: Text(
          LocaleKeys.chats_screens_chat_conversation_delete_confirm.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const TextLocale(LocaleKeys.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const TextLocale(LocaleKeys.common_delete),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref
          .read(conversationRepositoryProvider)
          .deleteConversation(widget.chat.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelDisplayName = ref.watch(
      listCredentialsCredentialsProvider.select(
        (cms) => cms.value
            ?.firstWhereOrNull(
              (cm) => cm.credentialsModel.id == widget.chat.modelId,
            )
            ?.credentialsModel
            .modelId,
      ),
    );
    final title =
        ref.watch(streamingTitleProvider(widget.chat.id)) ?? widget.chat.title;
    return AuraCard(
      onTap: () {
        ConversationRoute(chatId: widget.chat.id).go(context);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.chat.isPinned) ...[
                      const AuraIcon(
                        Icons.push_pin_outlined,
                        size: AuraIconSize.small,
                        color: AuraColorVariant.warning,
                      ),
                      const SizedBox(width: 8),
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
                const SizedBox(height: 4),
                AuraText(
                  style: AuraTextStyle.bodySmall,
                  color: AuraColorVariant.onSurfaceVariant,
                  child: Text(
                    formatRelativeTime(widget.chat.updatedAt),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (modelDisplayName != null) ...[
            const SizedBox(width: 8),
            AuraBadge.text(
              variant: AuraBadgeVariant.info,
              child: Text(modelDisplayName),
            ),
          ],
          const SizedBox(width: 8),
          AuraPopupMenu(
            controller: _menuController,
            items: [
              AuraPopupMenuItem(
                variant: AuraTileVariant.error,
                title: const TextLocale(LocaleKeys.common_delete),
                leading: const AuraIcon(Icons.delete_outline),
                onTap: () => _handleDelete(context),
              ),
            ],
            child: AuraIconButton(
              icon: Icons.more_vert,
              size: AuraIconSize.small,
              tooltip: LocaleKeys
                  .chats_screens_chat_conversation_options_tooltip
                  .tr(),
              onPressed: _menuController.toggle,
            ),
          ),
        ],
      ),
    );
  }
}
