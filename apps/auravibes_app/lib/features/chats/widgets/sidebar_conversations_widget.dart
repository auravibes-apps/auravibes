// Required: Existing thresholds and limits use numeric values.
// Required: Existing argument values intentionally repeat.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _currentChatIdProvider = Provider<String?>(
  (ref) {
    final pathSegments = ref.watch(routerPathSegmentsProvider);
    if (pathSegments.length < 4) return null;
    final [firstSegment, _, thirdSegment, fourthSegment, ...] = pathSegments;
    if (firstSegment != 'workspaces') return null;
    if (thirdSegment != 'chats') return null;

    return fourthSegment;
  },
);

class SidebarConversationsWidget extends ConsumerWidget {
  // Null workspace ID means no workspace has been selected yet.
  // ignore: unnecessary-nullable
  const SidebarConversationsWidget({
    required this.workspaceId,
    super.key,
    this.limit = 10,
  });

  final String? workspaceId;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = this.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentChatId = ref.watch(_currentChatIdProvider);
    final chatListAsync = ref.watch(
      conversationsStreamProvider(workspaceId: workspaceId, limit: limit),
    );

    return switch (chatListAsync) {
      AsyncData(value: final chats) => () {
        if (chats.isEmpty) {
          return const _SidebarConversationsEmptyState();
        }

        return Column(
          children: [
            const _SidebarConversationsSectionHeader(),
            for (final chat in chats) ...[
              _SidebarConversationTile(
                chat: chat,
                workspaceId: workspaceId,
                isActive: chat.id == currentChatId,
              ),
              if (_isCompacting(ref, chat.id)) const _CompactingRow(),
            ],
            _SidebarConversationsViewAllButton(workspaceId: workspaceId),
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
      AsyncError(:final error, stackTrace: _) => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: context.auraTheme.spacing.md,
            horizontal: context.auraTheme.spacing.sm,
          ),
          child: AuraText(
            child: TextLocale(
              LocaleKeys
                  .home_screen_conversation_states_error_loading_conversations,
              args: [error.toString()],
            ),
            style: AuraTextStyle.bodySmall,
            color: AuraColorVariant.error,
          ),
        ),
      ),
    };
  }

  bool _isCompacting(WidgetRef ref, String conversationId) {
    final execution = ref.watch(compactionExecutionProvider);
    final entry = execution[conversationId];

    return entry != null && entry.status == CompactionExecutionStatus.running;
  }
}

class _SidebarConversationsSectionHeader extends StatelessWidget {
  const _SidebarConversationsSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.spacing.xs,
        horizontal: context.auraTheme.spacing.sm,
      ),
      child: const AuraText(
        child: TextLocale(
          LocaleKeys.sidebar_recent_chats,
        ),
        style: AuraTextStyle.caption,
        color: AuraColorVariant.onSurfaceVariant,
      ),
    );
  }
}

class _SidebarConversationsEmptyState extends StatelessWidget {
  const _SidebarConversationsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.spacing.md,
        horizontal: context.auraTheme.spacing.sm,
      ),
      child: const AuraText(
        child: TextLocale(
          LocaleKeys.sidebar_no_recent_chats,
        ),
        style: AuraTextStyle.bodySmall,
        textAlign: TextAlign.center,
        color: AuraColorVariant.onSurfaceVariant,
      ),
    );
  }
}

class _SidebarConversationsViewAllButton extends StatelessWidget {
  const _SidebarConversationsViewAllButton({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: context.auraTheme.spacing.sm,
        top: context.auraTheme.spacing.xs,
        right: context.auraTheme.spacing.sm,
        bottom: context.auraTheme.spacing.md,
      ),
      child: AuraButton(
        onPressed: () => ChatsRoute(workspaceId: workspaceId).go(context),
        child: const TextLocale(
          LocaleKeys.sidebar_view_all_chats,
        ),
        variant: AuraButtonVariant.ghost,
        size: AuraButtonSize.small,
        isFullWidth: true,
      ),
    );
  }
}

class _SidebarConversationTile extends ConsumerStatefulWidget {
  const _SidebarConversationTile({
    required this.chat,
    required this.workspaceId,
    required this.isActive,
  });

  final ConversationEntity chat;
  final String workspaceId;
  final bool isActive;

  @override
  ConsumerState<_SidebarConversationTile> createState() =>
      _SidebarConversationTileState();
}

class _SidebarConversationTileState
    extends ConsumerState<_SidebarConversationTile> {
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
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.spacing.xs,
        horizontal: context.auraTheme.spacing.sm,
      ),
      child: AuraTile(
        child: AuraText(
          child: Text(
            ref.watch(streamingTitleProvider(widget.chat.id)) ??
                widget.chat.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          style: AuraTextStyle.bodySmall,
          color: widget.isActive ? AuraColorVariant.primary : null,
        ),
        onTap: () => ConversationRoute(
          workspaceId: widget.workspaceId,
          chatId: widget.chat.id,
        ).go(context),
        variant: widget.isActive
            ? AuraTileVariant.selected
            : AuraTileVariant.ghost,
        size: AuraTileSize.small,
        leading: AuraIcon(
          Icons.chat_bubble_outline,
          size: AuraIconSize.small,
          color: widget.isActive
              ? AuraColorVariant.primary
              : AuraColorVariant.onSurfaceVariant,
        ),
        trailing: AuraPopupMenu(
          child: AuraIconButton(
            icon: Icons.more_vert,
            onPressed: _menuController.toggle,
            size: AuraIconSize.small,
            tooltip: LocaleKeys.chats_screens_chat_conversation_options_tooltip
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
      ),
    );
  }
}

class _CompactingRow extends ConsumerWidget {
  const _CompactingRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.spacing.xs,
        horizontal: context.auraTheme.spacing.sm,
      ),
      child: const AuraTile(
        child: AuraText(
          child: TextLocale(
            LocaleKeys.compaction_compacting_row_label,
          ),
          style: AuraTextStyle.bodySmall,
          color: AuraColorVariant.onSurfaceVariant,
        ),
        variant: AuraTileVariant.ghost,
        size: AuraTileSize.small,
        leading: Padding(
          padding: EdgeInsets.all(4),
          child: SizedBox(
            width: 16,
            height: 16,
            child: AuraSpinner(),
          ),
        ),
        enabled: false,
      ),
    );
  }
}
