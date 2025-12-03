import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/models/providers/list_chat_models_providers.dart';
import 'package:auravibes_app/router/app_router.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatListWidget extends ConsumerWidget {
  const ChatListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatListAsync = ref.watch(conversationsListProvider);

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
      AsyncError(error: final error, stackTrace: _) => Center(
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
              color: Colors.grey,
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

class _ChatTile extends ConsumerWidget {
  const _ChatTile({required this.chat});

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
    return AuraCard(
      // backgroundColor: Colors.red,
      onTap: () {
        CoversationRoute(chatId: chat.id).go(context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: AuraText(
                            style: AuraTextStyle.heading6,
                            child: Text(
                              chat.title,
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
                        _formatDate(chat.updatedAt),
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
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
