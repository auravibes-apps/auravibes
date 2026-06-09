// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-extracting-callbacks
// Required: UI callbacks stay local to their widgets.
// ignore_for_file: prefer-single-widget-per-file
// Required: Feature widgets keep closely related private widgets together.
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/presentation/shared/formatters/relative_time_formatter.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatListWidget extends ConsumerWidget {
  const ChatListWidget({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatListAsync = ref.watch(
      conversationsStreamProvider(workspaceId: workspaceId),
    );

    return switch (chatListAsync) {
      AsyncData(value: final chats) => () {
        if (chats.isEmpty) {
          return const _ChatListEmptyState();
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

class _ChatListEmptyState extends StatelessWidget {
  const _ChatListEmptyState();

  @override
  Widget build(BuildContext context) {
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
              child: TextLocale(
                LocaleKeys.home_screen_conversation_states_no_chats_yet,
              ),
              style: AuraTextStyle.heading3,
            ),
            SizedBox(height: 8),
            AuraText(
              child: TextLocale(
                LocaleKeys
                    .home_screen_conversation_states_start_first_conversation,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends ConsumerStatefulWidget {
  const _ChatTile({required this.chat, required this.workspaceId});

  final ConversationEntity chat;
  final String workspaceId;

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
      final _ = await ref
          .read(conversationRepositoryProvider)
          .deleteConversation(widget.chat.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspaceModelSelectionsAsync = ref.watch(
      listWorkspaceModelSelectionsProvider(workspaceId: widget.workspaceId),
    );
    final modelDisplayName = workspaceModelSelectionsAsync.asData?.value
        .where((cm) => cm.workspaceModelSelection.id == widget.chat.modelId)
        .firstOrNull
        ?.workspaceModelSelection
        .modelId;
    final title =
        ref.watch(streamingTitleProvider(widget.chat.id)) ?? widget.chat.title;

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
                        child: Text(title, overflow: TextOverflow.ellipsis),
                        style: AuraTextStyle.heading6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AuraText(
                  child: Text(
                    formatRelativeTime(widget.chat.updatedAt),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: AuraTextStyle.bodySmall,
                  color: AuraColorVariant.onSurfaceVariant,
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
          AuraPopupMenu(
            child: AuraIconButton(
              icon: Icons.more_vert,
              onPressed: _menuController.toggle,
              size: AuraIconSize.small,
              tooltip: LocaleKeys
                  .chats_screens_chat_conversation_options_tooltip
                  .tr(),
            ),
            items: [
              AuraPopupMenuItem(
                title: const TextLocale(LocaleKeys.common_delete),
                onTap: () => _handleDelete(context),
                leading: const AuraIcon(Icons.delete_outline),
                variant: AuraTileVariant.error,
              ),
            ],
            controller: _menuController,
          ),
        ],
      ),
      onTap: () {
        ConversationRoute(
          workspaceId: widget.workspaceId,
          chatId: widget.chat.id,
        ).go(context);
      },
    );
  }
}
