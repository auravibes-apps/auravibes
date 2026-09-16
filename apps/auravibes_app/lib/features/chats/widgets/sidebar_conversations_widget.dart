// Required: Existing thresholds and limits use numeric values.
// Required: Existing argument values intentionally repeat.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/delete_conversation_confirm_dialog.dart';
import 'package:auravibes_app/features/chats/widgets/rename_conversation_dialog.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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

    final currentChatId = _sidebarCurrentChatIdFromContext(context);
    final chatListAsync = ref.watch(
      conversationsStreamProvider(workspaceId: workspaceId, limit: limit),
    );

    return _SidebarConversationsContent(
      chatListAsync: chatListAsync,
      workspaceId: workspaceId,
      currentChatId: currentChatId,
    );
  }
}

String? _sidebarCurrentChatIdFromContext(BuildContext context) =>
    _sidebarCurrentChatId(
      GoRouter.maybeOf(context)
          ?.routeInformationProvider
          .value
          .uri
          .pathSegments,
    );

String? _sidebarCurrentChatId(List<String>? pathSegments) {
  if (pathSegments == null) return null;
  const minimumRouteSegments = 4;
  if (pathSegments.length < minimumRouteSegments) return null;
  final [firstSegment, _, thirdSegment, fourthSegment, ...] = pathSegments;
  if (firstSegment != 'workspaces') return null;
  if (thirdSegment != 'chats') return null;

  return fourthSegment;
}

class _SidebarConversationsContent extends ConsumerWidget {
  const new({
    required this.chatListAsync,
    required this.workspaceId,
    required this.currentChatId,
  });

  final AsyncValue<List<ConversationEntity>> chatListAsync;
  final String workspaceId;
  final String? currentChatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (chatListAsync) {
    AsyncData(value: final chats) => _SidebarConversationsLoaded(
      chats: chats,
      workspaceId: workspaceId,
      currentChatId: currentChatId,
    ),
    AsyncLoading() => const _SidebarConversationsLoading(),
    AsyncError(:final error) => _SidebarConversationsError(error: error),
  };
}

class const _SidebarConversationsLoaded({
  required final List<ConversationEntity> chats,
  required final String workspaceId,
  required final String? currentChatId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => chats.isEmpty
      ? const Column(
          children: [
            _SidebarConversationsSectionHeader(),
            _SidebarConversationsEmptyState(),
          ],
        )
      : _SidebarConversationsList(
          chats: chats,
          workspaceId: workspaceId,
          currentChatId: currentChatId,
        );
}

class const _SidebarConversationsLoading() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.auraTheme.fromSpacing(.md),
      ),
      child: const AuraSpinner(),
    ),
  );
}

class const _SidebarConversationsList({
  required final List<ConversationEntity> chats,
  required final String workspaceId,
  required final String? currentChatId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const _SidebarConversationsSectionHeader(),
      for (final chat in chats)
        _SidebarConversationListItem(
          chat: chat,
          workspaceId: workspaceId,
          currentChatId: currentChatId,
        ),
      _SidebarConversationsViewAllButton(workspaceId: workspaceId),
    ],
  );
}

class const _SidebarConversationListItem({
  required final ConversationEntity chat,
  required final String workspaceId,
  required final String? currentChatId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompacting =
        ref.watch(compactionExecutionProvider)[chat.id]?.status ==
        CompactionExecutionStatus.running;

    return Column(
      children: [
        _SidebarConversationTile(
          chat: chat,
          workspaceId: workspaceId,
          isActive: chat.id == currentChatId,
        ),
        if (isCompacting) const _CompactingRow(),
      ],
    );
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
          style: .bodySmall,
          tint: .error,
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
        style: .caption,
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
        style: .bodySmall,
        textAlign: .center,
      ),
    );
  }
}

class const _SidebarConversationsViewAllButton({
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: context.auraTheme.fromSpacing(.sm),
      top: context.auraTheme.fromSpacing(.xs),
      right: context.auraTheme.fromSpacing(.sm),
      bottom: context.auraTheme.fromSpacing(.md),
    ),
    child: _SidebarConversationsViewAllAction(workspaceId: workspaceId),
  );
}

class const _SidebarConversationsViewAllAction({
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => ChatsRoute(workspaceId: workspaceId).go(context),
    child: const TextLocale(LocaleKeys.sidebar_view_all_chats),
    variant: .ghost,
    size: .small,
    isFullWidth: true,
  );
}

class const _SidebarConversationTile({
  required final ConversationEntity chat,
  required final String workspaceId,
  required final bool isActive,
}) extends ConsumerStatefulWidget {
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

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;

    return _SidebarConversationTileView(
      child: _SidebarConversationTileContent(
        isActive: widget.isActive,
        isPinned: chat.isPinned,
        title: ref.watch(streamingTitleProvider(chat.id)) ?? chat.title,
        controller: _menuController,
        onDelete: _deleteConversation,
        onTogglePin: _togglePin,
        onRename: _renameConversation,
        onTap: _openConversation,
      ),
    );
  }

  void _deleteConversation() =>
      unawaited(_deleteSidebarConversation(context, ref, widget.chat));

  void _togglePin() =>
      unawaited(_toggleSidebarConversationPin(context, ref, widget.chat));

  void _renameConversation() =>
      unawaited(_renameSidebarConversation(context, ref, widget.chat));

  void _openConversation() => _openSidebarConversation(context, widget.chat);
}

void _openSidebarConversation(BuildContext context, ConversationEntity chat) =>
    ConversationRoute(
      workspaceId: chat.workspaceId,
      chatId: chat.id,
    ).go(context);

class const _SidebarConversationTileView({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      vertical: context.auraTheme.fromSpacing(.xs),
      horizontal: context.auraTheme.fromSpacing(.sm),
    ),
    child: child,
  );
}

class const _SidebarConversationTileContent({
  required final bool isActive,
  required final bool isPinned,
  required final String title,
  required final AuraPopupMenuController controller,
  required final VoidCallback onDelete,
  required final VoidCallback onTogglePin,
  required final VoidCallback onRename,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SidebarConversationTileBody(
    isActive: isActive,
    label: _SidebarConversationTileLabel(
      title: title,
      isActive: isActive,
      isPinned: isPinned,
    ),
    menu: _SidebarConversationTileMenu(
      isPinned: isPinned,
      controller: controller,
      onDelete: onDelete,
      onTogglePin: onTogglePin,
      onRename: onRename,
    ),
    onTap: onTap,
  );
}

class const _SidebarConversationTileBody({
  required final bool isActive,
  required final Widget label,
  required final Widget menu,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: label,
    onTap: onTap,
    variant: isActive ? AuraTileVariant.selected : AuraTileVariant.ghost,
    size: .small,
    leading: _SidebarConversationTileLeading(isActive: isActive),
    trailing: menu,
  );
}

class const _SidebarConversationTileLabel({
  required final String title,
  required final bool isActive,
  required final bool isPinned,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      if (isPinned) ...[
        const AuraIcon(Icons.push_pin_outlined, size: .small, tint: .warning),
        const SizedBox(width: 8),
      ],
      Expanded(
        child: AuraText(
          child: Text(title, overflow: .ellipsis, maxLines: 1),
          style: .bodySmall,
          tint: isActive ? AuraTint.primary : null,
        ),
      ),
    ],
  );
}

class const _SidebarConversationTileLeading({required final bool isActive})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIcon(
    Icons.chat_bubble_outline,
    size: .small,
    tint: isActive ? AuraTint.primary : null,
  );
}

class const _SidebarConversationTileMenu({
  required final bool isPinned,
  required final AuraPopupMenuController controller,
  required final VoidCallback onDelete,
  required final VoidCallback onTogglePin,
  required final VoidCallback onRename,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraPopupMenu(
      child: AuraIconButton(
        icon: Icons.more_vert,
        onPressed: controller.toggle,
        size: .small,
        tooltip: LocaleKeys.chats_screens_chat_conversation_options_tooltip
            .tr(),
      ),
      items: [
        _sidebarConversationPinItem(isPinned, onTogglePin),
        ..._sidebarConversationMenuItems(
          onRename: onRename,
          onDelete: onDelete,
        ),
      ],
      controller: controller,
    );
  }
}

AuraPopupMenuItem _sidebarConversationPinItem(
  bool isPinned,
  VoidCallback onTogglePin,
) => AuraPopupMenuItem(
  title: TextLocale(
    isPinned
        ? LocaleKeys.chats_screens_chat_conversation_unpin
        : LocaleKeys.chats_screens_chat_conversation_pin,
  ),
  onTap: onTogglePin,
  leading: AuraIcon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
);

List<AuraPopupMenuItem> _sidebarConversationMenuItems({
  required VoidCallback onRename,
  required VoidCallback onDelete,
}) => [
  _sidebarConversationRenameItem(onRename),
  _sidebarConversationDeleteItem(onDelete),
];

AuraPopupMenuItem _sidebarConversationRenameItem(VoidCallback onRename) =>
    AuraPopupMenuItem(
      title: const TextLocale(
        LocaleKeys.chats_screens_chat_conversation_rename,
      ),
      onTap: onRename,
      leading: const AuraIcon(Icons.edit_outlined),
    );

AuraPopupMenuItem _sidebarConversationDeleteItem(VoidCallback onDelete) =>
    AuraPopupMenuItem(
      title: const TextLocale(LocaleKeys.common_delete),
      onTap: onDelete,
      leading: const AuraIcon(Icons.delete_outline),
      variant: .error,
    );

Future<void> _deleteSidebarConversation(
  BuildContext context,
  WidgetRef ref,
  ConversationEntity chat,
) async {
  final confirmed = await DeleteConversationConfirmDialog.show(context);
  if (!confirmed) return;

  final cloud = await ref.read(
    cloudConversationUsecaseProvider(chat.workspaceId).future,
  );
  if (cloud case final cloud?) {
    await cloud.delete(chat);

    return;
  }

  final _ = await ref
      .read(conversationRepositoryProvider)
      .deleteConversation(chat.id);
}

Future<void> _toggleSidebarConversationPin(
  BuildContext context,
  WidgetRef ref,
  ConversationEntity chat,
) async {
  if (!chat.isPinned &&
      !await _hasSidebarPinnedCapacity(ref, chat.workspaceId)) {
    return;
  }
  if (!context.mounted) return;
  if (await _toggleSidebarCloudPin(context, ref, chat)) return;
  await _toggleSidebarLocalPin(ref, chat);
}

Future<bool> _hasSidebarPinnedCapacity(
  WidgetRef ref,
  String workspaceId,
) async {
  final conversations = await ref.read(
    conversationsStreamProvider(workspaceId: workspaceId).future,
  );

  return ConversationLimits.hasPinnedCapacity(conversations);
}

Future<bool> _toggleSidebarCloudPin(
  BuildContext context,
  WidgetRef ref,
  ConversationEntity chat,
) async {
  final cloud = await ref.read(
    cloudConversationUsecaseProvider(chat.workspaceId).future,
  );
  if (cloud == null) return false;

  await _updateSidebarCloudPin(cloud, chat);
  if (context.mounted) {
    ref.invalidate(conversationsStreamProvider(workspaceId: chat.workspaceId));
  }

  return true;
}

Future<void> _updateSidebarCloudPin(
  CloudConversationUsecase cloud,
  ConversationEntity chat,
) async {
  final patch = ConversationPatch(isPinned: !chat.isPinned);
  try {
    final _ = await cloud.update(chat, patch);
  } on CloudAppException catch (error) {
    if (error.code != 'validationFailed') rethrow;
  }
}

Future<void> _toggleSidebarLocalPin(
  WidgetRef ref,
  ConversationEntity chat,
) async {
  final patch = ConversationPatch(isPinned: !chat.isPinned);
  try {
    final _ = await ref
        .read(conversationRepositoryProvider)
        .patchConversation(chat.id, patch);
  } on ConversationPinLimitException {
    return;
  }
}

Future<void> _renameSidebarConversation(
  BuildContext context,
  WidgetRef ref,
  ConversationEntity chat,
) async {
  final title = await RenameConversationDialog.show(context, title: chat.title);
  if (title == null) return;

  await ref
      .read(conversationChatProvider(chat.workspaceId, chat.id).notifier)
      .rename(chat, title);
}

class const _CompactingRow() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      vertical: context.auraTheme.fromSpacing(.xs),
      horizontal: context.auraTheme.fromSpacing(.sm),
    ),
    child: const _CompactingTile(),
  );
}

class const _CompactingTile() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraTile(
    child: AuraText(
      child: TextLocale(LocaleKeys.compaction_compacting_row_label),
      style: .bodySmall,
    ),
    variant: .ghost,
    size: .small,
    leading: _CompactingIndicator(),
    enabled: false,
  );
}

class const _CompactingIndicator() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(4),
    child: SizedBox(width: 16, height: 16, child: AuraSpinner()),
  );
}
