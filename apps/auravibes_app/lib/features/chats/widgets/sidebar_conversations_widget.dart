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
import 'package:auravibes_app/features/chats/widgets/conversation_options_menu.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const SidebarConversationsWidget({
  required final String? workspaceId,
  super.key,
  final int limit = 10,
}) extends ConsumerWidget {
  // Null workspace ID means no workspace has been selected yet.
  // ignore: unnecessary-nullable
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = this.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentChatId = _currentChatId(
      GoRouter.maybeOf(context)
          ?.routeInformationProvider
          .value
          .uri
          .pathSegments,
    );
    final chatListAsync = ref.watch(
      conversationsStreamProvider(workspaceId: workspaceId, limit: limit),
    );
    switch (chatListAsync) {
      case AsyncData(value: final chats):
        if (chats.isEmpty) {
          return const Column(
            children: [
              _SidebarConversationsSectionHeader(),
              _SidebarConversationsEmptyState(),
            ],
          );
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
      case AsyncLoading():
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: context.auraTheme.fromSpacing(.md),
            ),
            child: const AuraSpinner(),
          ),
        );
      case AsyncError(:final error):
        return _SidebarConversationsError(error: error);
    }
  }

  String? _currentChatId(List<String>? pathSegments) {
    if (pathSegments == null) return null;
    const minimumRouteSegments = 4;
    if (pathSegments.length < minimumRouteSegments) return null;
    final [firstSegment, _, thirdSegment, fourthSegment, ...] = pathSegments;
    if (firstSegment != 'workspaces') return null;
    if (thirdSegment != 'chats') return null;

    return fourthSegment;
  }

  bool _isCompacting(WidgetRef ref, String conversationId) {
    final execution = ref.watch(compactionExecutionProvider);
    final entry = execution[conversationId];

    return entry != null && entry.status == CompactionExecutionStatus.running;
  }
}

class const _SidebarConversationsError<T extends Object>({
  required final T error,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: context.auraTheme.fromSpacing(.md),
          horizontal: context.auraTheme.fromSpacing(.sm),
        ),
        child: AuraText(
          child: TextLocale(CloudAppErrors.localizationKey(error)),
          style: AuraTextStyle.bodySmall,
          tint: AuraTint.error,
        ),
      ),
    );
  }
}

class const _SidebarConversationsSectionHeader() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.fromSpacing(.xs),
        horizontal: context.auraTheme.fromSpacing(.sm),
      ),
      child: const AuraText(
        child: TextLocale(LocaleKeys.sidebar_recent_chats),
        style: AuraTextStyle.caption,
      ),
    );
  }
}

class const _SidebarConversationsEmptyState() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.fromSpacing(.md),
        horizontal: context.auraTheme.fromSpacing(.sm),
      ),
      child: const AuraText(
        child: TextLocale(LocaleKeys.sidebar_no_recent_chats),
        style: AuraTextStyle.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class const _SidebarConversationsViewAllButton({
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: context.auraTheme.fromSpacing(.sm),
        top: context.auraTheme.fromSpacing(.xs),
        right: context.auraTheme.fromSpacing(.sm),
        bottom: context.auraTheme.fromSpacing(.md),
      ),
      child: AuraButton(
        onPressed: () => ChatsRoute(workspaceId: workspaceId).go(context),
        child: const TextLocale(LocaleKeys.sidebar_view_all_chats),
        variant: AuraButtonVariant.ghost,
        size: AuraButtonSize.small,
        isFullWidth: true,
      ),
    );
  }
}

class const _SidebarConversationTile({
  required final ConversationEntity chat,
  required final String workspaceId,
  required final bool isActive,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.fromSpacing(.xs),
        horizontal: context.auraTheme.fromSpacing(.sm),
      ),
      child: AuraTile(
        child: AuraText(
          child: Text(
            ref.watch(streamingTitleProvider(chat.id)) ?? chat.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          style: AuraTextStyle.bodySmall,
          tint: isActive ? AuraTint.primary : null,
        ),
        onTap: () => ConversationRoute(
          workspaceId: workspaceId,
          chatId: chat.id,
        ).go(context),
        variant: isActive ? AuraTileVariant.selected : AuraTileVariant.ghost,
        size: AuraTileSize.small,
        leading: AuraIcon(
          Icons.chat_bubble_outline,
          size: AuraIconSize.small,
          tint: isActive ? AuraTint.primary : null,
        ),
        trailing: ConversationOptionsMenu(conversation: chat),
      ),
    );
  }
}

class const _CompactingRow() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.fromSpacing(.xs),
        horizontal: context.auraTheme.fromSpacing(.sm),
      ),
      child: const AuraTile(
        child: AuraText(
          child: TextLocale(LocaleKeys.compaction_compacting_row_label),
          style: AuraTextStyle.bodySmall,
        ),
        variant: AuraTileVariant.ghost,
        size: AuraTileSize.small,
        leading: Padding(
          padding: EdgeInsets.all(4),
          child: SizedBox(width: 16, height: 16, child: AuraSpinner()),
        ),
        enabled: false,
      ),
    );
  }
}
