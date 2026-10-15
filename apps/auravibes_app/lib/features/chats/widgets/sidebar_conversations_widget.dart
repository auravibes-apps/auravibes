// Required: Existing thresholds and limits use numeric values.
// Required: Existing argument values intentionally repeat.
// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Feature widgets keep closely related private widgets together.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/browser/providers/browser_session_notifier.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_draft.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/bulk_conversation_actions_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/compaction_execution.dart';
import 'package:auravibes_app/features/chats/providers/conversation_activity_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/fork_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/conversation_draft_badge.dart';
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
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

final _logger = Logger('sidebar_conversations');

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
      conversationsStreamProvider(
        workspaceId: workspaceId,
        pagination: (limit: limit, offset: 0),
      ),
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
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleChats = _sidebarVisibleConversations(
      ref,
      workspaceId: workspaceId,
      currentChatId: currentChatId,
      recentChats: chats,
    );

    return visibleChats.isEmpty
        ? const Column(
            children: [
              _SidebarConversationsSectionHeader(),
              _SidebarConversationsEmptyState(),
            ],
          )
        : _SidebarConversationsList(
            chats: visibleChats,
            workspaceId: workspaceId,
            currentChatId: currentChatId,
          );
  }
}

List<ConversationEntity> _sidebarVisibleConversations(
  WidgetRef ref, {
  required String workspaceId,
  required String? currentChatId,
  required List<ConversationEntity> recentChats,
}) {
  final activeChatId = currentChatId;
  if (activeChatId == null ||
      recentChats.any((chat) => chat.id == activeChatId)) {
    return recentChats;
  }

  final activeChat = ref
      .watch(
        conversationByIdStreamProvider(
          workspaceId,
          conversationId: activeChatId,
        ),
      )
      .value;

  return activeChat == null ? recentChats : [activeChat, ...recentChats];
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
  Widget build(BuildContext context) => _buildTile();

  void _deleteConversation() =>
      unawaited(_deleteSidebarConversation(context, ref, widget.chat));

  void _forkConversation() =>
      unawaited(_forkSidebarConversation(context, ref, widget.chat));

  void _togglePin() =>
      unawaited(_toggleSidebarConversationPin(context, ref, widget.chat));

  void _renameConversation() =>
      unawaited(_renameSidebarConversation(context, ref, widget.chat));

  void _openConversation() => _openSidebarConversation(context, widget.chat);
}

extension on _SidebarConversationTileState {
  Widget _buildTile() {
    final chat = widget.chat;

    return _SidebarConversationTileView(child: _buildTileContent(chat));
  }

  Widget _buildTileContent(ConversationEntity chat) =>
      _SidebarConversationTileContent(
        chat: chat,
        isActive: widget.isActive,
        title: ref.watch(streamingTitleProvider(chat.id)) ?? chat.title,
        controller: _menuController,
        onFork: _forkConversation,
        onDelete: _deleteConversation,
        onTogglePin: _togglePin,
        onRename: _renameConversation,
        onTap: _openConversation,
      );
}

typedef _SidebarConversationTileStatus = ({
  bool isAgentWorking,
  bool hasDraft,
  bool hasBrowserTabs,
  bool isBrowserSuspended,
  String semanticLabel,
});
typedef _SidebarTileActivityStatus = ({bool isAgentWorking, bool hasDraft});
typedef _SidebarBrowserTabStatus = ({
  bool hasBrowserTabs,
  bool isBrowserSuspended,
});

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
  required final ConversationEntity chat,
  required final bool isActive,
  required final String title,
  required final AuraPopupMenuController controller,
  required final VoidCallback onFork,
  required final VoidCallback onDelete,
  required final VoidCallback onTogglePin,
  required final VoidCallback onRename,
  required final VoidCallback onTap,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SidebarConversationTileBody(
      content: this,
      status: _sidebarConversationTileStatus(ref, this),
    );
  }

  bool _isAgentWorking(WidgetRef ref) => ref.watch(
    conversationActivityProvider.select(
      (conversationIds) => conversationIds.contains(chat.id),
    ),
  );

  bool _hasDraft(WidgetRef ref) =>
      ref
          .watch(conversationDraftProvider(chat.workspaceId, chat.id))
          ?.isEmpty ==
      false;
}

_SidebarConversationTileStatus _sidebarConversationTileStatus(
  WidgetRef ref,
  _SidebarConversationTileContent content,
) {
  final activity = _sidebarTileActivityStatus(ref, content);
  final browser = _sidebarBrowserTabStatus(ref, content);

  return (
    isAgentWorking: activity.isAgentWorking,
    hasDraft: activity.hasDraft,
    hasBrowserTabs: browser.hasBrowserTabs,
    isBrowserSuspended: browser.isBrowserSuspended,
    semanticLabel: _sidebarConversationTileSemanticLabel(
      content.title,
      activity.isAgentWorking,
      activity.hasDraft,
    ),
  );
}

_SidebarTileActivityStatus _sidebarTileActivityStatus(
  WidgetRef ref,
  _SidebarConversationTileContent content,
) => (
  isAgentWorking: content._isAgentWorking(ref),
  hasDraft: content._hasDraft(ref),
);

_SidebarBrowserTabStatus _sidebarBrowserTabStatus(
  WidgetRef ref,
  _SidebarConversationTileContent content,
) {
  final session = ref
      .watch(browserSessionProvider(content.chat.workspaceId, content.chat.id))
      .value;

  return (
    hasBrowserTabs: session?.tabs.isNotEmpty ?? false,
    isBrowserSuspended: session?.isSuspended ?? false,
  );
}

class const _SidebarConversationTileTrailing({
  required final _SidebarConversationTileContent content,
  required final _SidebarConversationTileStatus status,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        _SidebarConversationStatus(content: content, status: status),
        _SidebarConversationTileMenu(content: content, status: status),
      ],
    );
  }
}

class const _SidebarConversationTileBody({
  required final _SidebarConversationTileContent content,
  required final _SidebarConversationTileStatus status,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildTile();
  }
}

extension on _SidebarConversationTileBody {
  Widget _buildTile() {
    final tile = content;

    return AuraTile(
      child: _tileLabel(tile),
      onTap: tile.onTap,
      variant: tile.isActive ? AuraTileVariant.selected : AuraTileVariant.ghost,
      size: .small,
      leading: _SidebarConversationTileLeading(isActive: tile.isActive),
      trailing: _SidebarConversationTileTrailing(content: tile, status: status),
      semanticLabel: status.semanticLabel,
    );
  }

  Widget _tileLabel(_SidebarConversationTileContent tile) =>
      _SidebarConversationTileLabel(content: tile, hasDraft: status.hasDraft);
}

class const _SidebarConversationStatus({
  required final _SidebarConversationTileContent content,
  required final _SidebarConversationTileStatus status,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      if (status.isAgentWorking)
        _SidebarAgentWorkingStatus(conversationId: content.chat.id),
      if (status.hasBrowserTabs)
        _SidebarBrowserStatus(
          conversationId: content.chat.id,
          isSuspended: status.isBrowserSuspended,
        ),
    ],
  );
}

String _sidebarConversationTileSemanticLabel(
  String title,
  bool isAgentWorking,
  bool hasDraft,
) => [
  title,
  if (isAgentWorking) LocaleKeys.sidebar_agent_working.tr(),
  if (hasDraft) LocaleKeys.chats_screens_chats_list_draft_marker.tr(),
].join(', ');

class const _SidebarAgentWorkingStatus({required final String conversationId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIcon(
    Icons.sync,
    key: ValueKey('sidebar-agent-working-status-$conversationId'),
    size: .small,
    tint: .primary,
  );
}

class const _SidebarBrowserStatus({
  required final String conversationId,
  required final bool isSuspended,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Tooltip(
    message:
        (isSuspended
                ? LocaleKeys.browser_suspended_indicator
                : LocaleKeys.browser_open_indicator)
            .tr(),
    child: AuraIcon(
      Icons.language,
      key: ValueKey('sidebar-browser-status-$conversationId'),
      size: .small,
      tint: isSuspended ? AuraTint.secondary : AuraTint.primary,
      semanticLabel:
          (isSuspended
                  ? LocaleKeys.browser_suspended_indicator
                  : LocaleKeys.browser_open_indicator)
              .tr(),
    ),
  );
}

class const _SidebarConversationTileLabel({
  required final _SidebarConversationTileContent content,
  required final bool hasDraft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      if (content.chat.isPinned) ...[
        const AuraIcon(Icons.push_pin_outlined, size: .small, tint: .warning),
        const SizedBox(width: 8),
      ],
      Expanded(child: _SidebarConversationTileLabelText(content: content)),
      if (hasDraft) ...[
        const SizedBox(width: 8),
        ConversationDraftBadge(conversationId: content.chat.id),
      ],
    ],
  );
}

class const _SidebarConversationTileLabelText({
  required final _SidebarConversationTileContent content,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(content.title, overflow: .ellipsis, maxLines: 1),
    style: .bodySmall,
    tint: content.isActive ? AuraTint.primary : null,
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
  required final _SidebarConversationTileContent content,
  required final _SidebarConversationTileStatus status,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => _buildMenu(ref);
}

extension on _SidebarConversationTileMenu {
  Widget _buildMenu(WidgetRef ref) => AuraPopupMenu(
    child: AuraIconButton(
      icon: Icons.more_vert,
      onPressed: content.controller.toggle,
      size: .small,
      tooltip: LocaleKeys.chats_screens_chat_conversation_options_tooltip.tr(),
    ),
    items: _menuItems(ref),
    controller: content.controller,
  );

  void _toggleBrowserSuspension(WidgetRef ref) {
    final notifier = _browserSessionNotifier(ref);
    unawaited(
      status.isBrowserSuspended ? notifier.resume() : notifier.suspend(),
    );
  }

  void _closeAllBrowserTabs(WidgetRef ref) =>
      unawaited(_browserSessionNotifier(ref).closeAllTabs());

  BrowserSessionNotifier _browserSessionNotifier(WidgetRef ref) => ref.read(
    browserSessionProvider(content.chat.workspaceId, content.chat.id).notifier,
  );

  List<AuraPopupMenuEntry> _menuItems(WidgetRef ref) => [
    _sidebarConversationPinItem(content.chat.isPinned, content.onTogglePin),
    _forkConversationItem,
    ..._browserMenuItems(ref),
    ..._sidebarConversationMenuItems(
      onRename: content.onRename,
      onDelete: content.onDelete,
    ),
  ];

  AuraPopupMenuItem get _forkConversationItem => AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.chats_screens_chat_conversation_fork),
    onTap: content.onFork,
    leading: const AuraIcon(Icons.call_split_outlined),
  );

  List<AuraPopupMenuEntry> _browserMenuItems(WidgetRef ref) {
    if (!status.hasBrowserTabs) return const [];

    return [
      const AuraPopupMenuDivider(),
      _browserSuspensionItem(ref),
      _browserCloseAllItem(ref),
    ];
  }

  AuraPopupMenuItem _browserSuspensionItem(WidgetRef ref) => AuraPopupMenuItem(
    title: TextLocale(
      status.isBrowserSuspended
          ? LocaleKeys.browser_resume
          : LocaleKeys.browser_suspend,
    ),
    onTap: () => _toggleBrowserSuspension(ref),
    leading: AuraIcon(
      status.isBrowserSuspended ? Icons.play_arrow : Icons.pause,
    ),
  );

  AuraPopupMenuItem _browserCloseAllItem(WidgetRef ref) => AuraPopupMenuItem(
    title: const TextLocale(LocaleKeys.browser_close_all_tabs),
    onTap: () => _closeAllBrowserTabs(ref),
    leading: const AuraIcon(Icons.close),
    variant: .error,
  );
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

  try {
    await _deleteSidebarConversationInStorage(ref, chat);
    _invalidateDeletedConversation(ref, chat);
  } on Object catch (error, stackTrace) {
    _logger.severe(
      'Failed to delete conversation ${chat.id}',
      error,
      stackTrace,
    );
    if (!context.mounted) return;
    _showSidebarDeleteSnack(context, error);
  }
}

Future<void> _deleteSidebarConversationInStorage(
  WidgetRef ref,
  ConversationEntity chat,
) async {
  final _ = await ref.read(bulkConversationActionsUsecaseProvider).delete(chat);
}

void _showSidebarDeleteSnack(BuildContext context, Object error) {
  final _ = AuraSnackBars.show(
    context: context,
    content: TextLocale(_deleteErrorKey(error)),
    variant: .error,
  );
}

void _invalidateDeletedConversation(WidgetRef ref, ConversationEntity chat) {
  final _ = ref.invalidate(
    conversationsStreamProvider(workspaceId: chat.workspaceId),
  );
  final _ = ref.invalidate(
    conversationByIdStreamProvider(chat.workspaceId, conversationId: chat.id),
  );
}

String _deleteErrorKey(Object error) => error is CloudAppException
    ? CloudAppErrors.localizationKey(error)
    : LocaleKeys.chats_screens_chat_conversation_delete_error;

Future<void> _forkSidebarConversation(
  BuildContext context,
  WidgetRef ref,
  ConversationEntity chat,
) async {
  try {
    final forkId = await _forkSidebarConversationInStorage(ref, chat);
    if (!context.mounted) return;
    _navigateToSidebarFork(ref, context, chat, forkId);
  } on Object {
    if (!context.mounted) return;
    _showSidebarForkError(context);
  }
}

void _navigateToSidebarFork(
  WidgetRef ref,
  BuildContext context,
  ConversationEntity chat,
  String forkId,
) {
  final _ = ref.invalidate(
    conversationsStreamProvider(workspaceId: chat.workspaceId),
  );
  if (!context.mounted) return;
  ConversationRoute(workspaceId: chat.workspaceId, chatId: forkId).go(context);
}

void _showSidebarForkError(BuildContext context) {
  if (!context.mounted) return;
  final _ = AuraSnackBars.show(
    context: context,
    content: const TextLocale(
      LocaleKeys.chats_screens_chat_conversation_fork_error,
    ),
    variant: .error,
  );
}

Future<String> _forkSidebarConversationInStorage(
  WidgetRef ref,
  ConversationEntity chat,
) async {
  final cloud = await ref.read(
    cloudConversationUsecaseProvider(chat.workspaceId).future,
  );

  return cloud != null
      ? (await cloud.fork(chat)).id
      : (await ref.read(forkConversationUsecaseProvider).call(chat)).id;
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
