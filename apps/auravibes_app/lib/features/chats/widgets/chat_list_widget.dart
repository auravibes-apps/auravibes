// Required: Existing test and UI helpers keep compact return flow.
// Required: UI callbacks stay local to their widgets.
// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/widgets/delete_conversation_confirm_dialog.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/utils/relative_time_formatter.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _conversationPageSize = 20;
const _conversationSearchDebounce = Duration(milliseconds: 300);

class const ChatListWidget({required final String workspaceId, super.key})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchText = useState('');
    final loadedChats = useState<List<ConversationEntity>>([]);
    final hasMore = useState(false);
    final isLoadingMore = useState(false);
    final showSearchInput = useState(false);
    final normalizedSearch = searchText.value.trim();
    final debouncedSearch = useDebounced(
      normalizedSearch,
      _conversationSearchDebounce,
    );
    final databaseSearch = debouncedSearch ?? '';
    final chatListAsync = ref.watch(
      conversationsStreamProvider(
        workspaceId: workspaceId,
        search: databaseSearch,
        limit: _conversationPageSize + 1,
      ),
    );

    Dispose? resetSearchEffect() {
      hasMore.value = false;

      return null;
    }

    Dispose? updateFirstPageEffect() {
      if (chatListAsync case AsyncData(:final value)) {
        loadedChats.value = value.take(_conversationPageSize).toList();
        hasMore.value = value.length > _conversationPageSize;
        if (value.isNotEmpty) showSearchInput.value = true;
      }

      return null;
    }

    useEffect(resetSearchEffect, [databaseSearch]);
    useEffect(updateFirstPageEffect, [chatListAsync]);

    Future<void> loadMore() async {
      if (isLoadingMore.value || !hasMore.value) return;
      isLoadingMore.value = true;
      final nextPageProvider = conversationsStreamProvider(
        workspaceId: workspaceId,
        search: databaseSearch,
        limit: _conversationPageSize + 1,
        offset: loadedChats.value.length,
      );
      final pageSubscription = ref.listenManual(
        nextPageProvider,
        (_, _) => isLoadingMore.value = true,
      );
      try {
        final nextPage = await ref.read(nextPageProvider.future);
        if (!context.mounted) return;

        final existingIds = loadedChats.value.map((chat) => chat.id).toSet();
        final nextChats = nextPage
            .take(_conversationPageSize)
            .where((chat) => !existingIds.contains(chat.id));
        loadedChats.value = [...loadedChats.value, ...nextChats];
        hasMore.value = nextPage.length > _conversationPageSize;
      } finally {
        pageSubscription.close();
        if (context.mounted) isLoadingMore.value = false;
      }
    }

    final fetchedChats = chatListAsync.asData?.value;
    final isRefreshing = chatListAsync.isLoading;
    final hasError = chatListAsync.hasError;
    final isDebouncing = debouncedSearch == null
        ? normalizedSearch.isNotEmpty
        : debouncedSearch != normalizedSearch;
    final hasSearchInput =
        showSearchInput.value || fetchedChats?.isNotEmpty == true;
    final fetchedHasMore =
        fetchedChats != null && fetchedChats.length > _conversationPageSize;

    if (!hasSearchInput && isRefreshing) {
      return const Center(child: AuraSpinner());
    }
    if (!hasSearchInput && hasError) {
      return const Center(
        child: AuraText(
          child: TextLocale(LocaleKeys.workspace_management_unexpected_error),
        ),
      );
    }

    return _ChatListLoaded(
      chats: loadedChats.value.isEmpty
          ? fetchedChats?.take(_conversationPageSize).toList() ?? const []
          : loadedChats.value,
      hasMore: hasMore.value || (loadedChats.value.isEmpty && fetchedHasMore),
      hasError: hasError,
      isLoadingMore: isLoadingMore.value,
      isSearching: isDebouncing || isRefreshing,
      isRefreshing: isRefreshing,
      onLoadMore: () => unawaited(loadMore()),
      onSearchChanged: (value) => searchText.value = value,
      searchController: searchController,
      searchQuery: searchText.value,
      showSearchInput: hasSearchInput,
      workspaceId: workspaceId,
    );
  }
}

class const _ChatListEmptyState({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: _ChatListEmptyStateColumn(workspaceId: workspaceId),
    ),
  );
}

class const _ChatListEmptyStateColumn({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: .center,
    children: [
      const AuraIcon(Icons.chat_outlined, size: .extraLarge),
      const SizedBox(height: 16),
      const AuraText(
        child: TextLocale(
          LocaleKeys.home_screen_conversation_states_no_chats_yet,
        ),
        style: .heading3,
      ),
      const SizedBox(height: 8),
      const AuraText(
        child: TextLocale(
          LocaleKeys.home_screen_conversation_states_start_first_conversation,
        ),
        textAlign: .center,
      ),
      const SizedBox(height: 16),
      _ChatListStartButton(workspaceId: workspaceId),
    ],
  );
}

class const _ChatListStartButton({required final String workspaceId})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => NewChatRoute(workspaceId: workspaceId).go(context),
    child: const TextLocale(LocaleKeys.home_screen_actions_start_new_chat),
  );
}

class const _ChatTile({
  required final ConversationEntity chat,
  required final String workspaceId,
}) extends ConsumerStatefulWidget {
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

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;

    return _ChatTileProvider(
      chat: chat,
      workspaceId: widget.workspaceId,
      controller: _menuController,
      onDelete: () => _handleDelete(context),
      onMenuToggle: _menuController.toggle,
      onTap: () => _openConversation(context),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final chat = widget.chat;
    final confirmed = await DeleteConversationConfirmDialog.show(context);
    if (!confirmed) return;

    await _deleteChat(chat);
  }

  Future<void> _deleteChat(ConversationEntity chat) async {
    final cloud = await ref.read(
      cloudConversationUsecaseProvider(chat.workspaceId).future,
    );
    if (cloud != null) {
      await cloud.delete(chat);

      return;
    }

    final _ = await ref
        .read(conversationRepositoryProvider)
        .deleteConversation(chat.id);

    return;
  }

  void _openConversation(BuildContext context) {
    ConversationRoute(
      workspaceId: widget.workspaceId,
      chatId: widget.chat.id,
    ).go(context);
  }
}

class const _ChatTileProvider({
  required final ConversationEntity chat,
  required final String workspaceId,
  required final AuraPopupMenuController controller,
  required final VoidCallback onDelete,
  required final VoidCallback onMenuToggle,
  required final VoidCallback onTap,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelDisplayName = _chatModelDisplayName(ref, workspaceId, chat);
    final title = ref.watch(streamingTitleProvider(chat.id)) ?? chat.title;

    return _ChatTileView(
      chat: chat,
      modelDisplayName: modelDisplayName,
      title: title,
      controller: controller,
      onDelete: onDelete,
      onMenuToggle: onMenuToggle,
      onTap: onTap,
    );
  }
}

String? _chatModelDisplayName(
  WidgetRef ref,
  String workspaceId,
  ConversationEntity chat,
) => ref
    .watch(listWorkspaceModelSelectionsProvider(workspaceId: workspaceId))
    .asData
    ?.value
    .where((cm) => cm.workspaceModelSelection.id == chat.modelId)
    .firstOrNull
    ?.workspaceModelSelection
    .modelId;

class const _ChatListLoaded({
  required final List<ConversationEntity> chats,
  required final bool hasMore,
  required final bool hasError,
  required final bool isLoadingMore,
  required final bool isSearching,
  required final bool isRefreshing,
  required final VoidCallback onLoadMore,
  required final ValueChanged<String> onSearchChanged,
  required final TextEditingController searchController,
  required final String searchQuery,
  required final bool showSearchInput,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    if (!showSearchInput) {
      return _ChatListEmptyState(workspaceId: workspaceId);
    }

    final results = switch ((
      isRefreshing: isRefreshing,
      hasError: hasError,
      isEmpty: chats.isEmpty,
      searchIsEmpty: searchQuery.trim().isEmpty,
    )) {
      (isRefreshing: true, hasError: _, isEmpty: _, searchIsEmpty: _) =>
        const Center(child: AuraSpinner()),
      (isRefreshing: false, hasError: true, isEmpty: _, searchIsEmpty: _) =>
        const Center(
          child: AuraText(
            child: TextLocale(LocaleKeys.workspace_management_unexpected_error),
          ),
        ),
      (
        isRefreshing: false,
        hasError: false,
        isEmpty: true,
        searchIsEmpty: true,
      ) =>
        _ChatListEmptyState(workspaceId: workspaceId),
      (
        isRefreshing: false,
        hasError: false,
        isEmpty: true,
        searchIsEmpty: false,
      ) =>
        const _ChatListSearchEmptyState(),
      (
        isRefreshing: false,
        hasError: false,
        isEmpty: false,
        searchIsEmpty: _,
      ) =>
        ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) =>
              _ChatTile(chat: chats[index], workspaceId: workspaceId),
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemCount: chats.length,
        ),
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
          child: AuraInput(
            controller: searchController,
            placeholder: const TextLocale(
              LocaleKeys.chats_screens_chats_list_search_placeholder,
            ),
            prefixIcon: const AuraIcon(Icons.search),
            suffixIcon: SizedBox(
              width: 16,
              height: 16,
              child: AuraAnimatedContent(
                child: isSearching
                    ? const AuraSpinner(
                        key: ValueKey('conversation-searching'),
                        size: .small,
                      )
                    : const SizedBox(key: ValueKey('conversation-idle')),
              ),
            ),
            size: .small,
            onChanged: onSearchChanged,
          ),
        ),
        Expanded(child: results),
        if (hasMore && !isRefreshing && !hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AuraButton(
              onPressed: onLoadMore,
              child: const TextLocale(LocaleKeys.common_show_more),
              size: .small,
              isLoading: isLoadingMore,
            ),
          ),
      ],
    );
  }
}

class const _ChatListSearchEmptyState() extends StatelessWidget {
  @override
  Widget build(BuildContext _) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: .min,
        children: [
          AuraIcon(Icons.search_off, size: .extraLarge),
          SizedBox(height: 8),
          AuraText(
            child: TextLocale(
              LocaleKeys.chats_screens_chats_list_search_no_results,
            ),
            textAlign: .center,
          ),
        ],
      ),
    ),
  );
}

class const _ChatTileView({
  required final ConversationEntity chat,
  required final String? modelDisplayName,
  required final String title,
  required final AuraPopupMenuController controller,
  required final VoidCallback onDelete,
  required final VoidCallback onMenuToggle,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: _ChatTileRow(
      chat: chat,
      modelDisplayName: modelDisplayName,
      title: title,
      controller: controller,
      onDelete: onDelete,
      onMenuToggle: onMenuToggle,
    ),
    onTap: onTap,
    style: .border,
  );
}

class const _ChatTileRow({
  required final ConversationEntity chat,
  required final String? modelDisplayName,
  required final String title,
  required final AuraPopupMenuController controller,
  required final VoidCallback onDelete,
  required final VoidCallback onMenuToggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: .start,
    children: [
      Expanded(
        child: _ChatTileInfo(chat: chat, title: title),
      ),
      if (modelDisplayName case final displayName?) ...[
        const SizedBox(width: 8),
        AuraBadge.text(child: Text(displayName), variant: .info),
      ],
      const SizedBox(width: 8),
      _ChatTileMenu(
        controller: controller,
        onDelete: onDelete,
        onToggle: onMenuToggle,
      ),
    ],
  );
}

class const _ChatTileInfo({
  required final ConversationEntity chat,
  required final String title,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _ChatTileTitleRow(chat: chat, title: title),
      const SizedBox(height: 4),
      AuraText(
        child: Text(
          RelativeTimeFormatter.format(chat.updatedAt),
          overflow: .ellipsis,
        ),
        style: .bodySmall,
      ),
    ],
    crossAxisAlignment: .start,
  );
}

class const _ChatTileTitleRow({
  required final ConversationEntity chat,
  required final String title,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      if (chat.isPinned) ...[
        const AuraIcon(Icons.push_pin_outlined, size: .small, tint: .warning),
        const SizedBox(width: 8),
      ],
      Expanded(
        child: AuraText(
          child: Text(title, overflow: .ellipsis),
          style: .heading6,
        ),
      ),
    ],
  );
}

class const _ChatTileMenu({
  required final AuraPopupMenuController controller,
  required final VoidCallback onDelete,
  required final VoidCallback onToggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraPopupMenu(
      child: AuraIconButton(
        icon: Icons.more_vert,
        onPressed: onToggle,
        size: .small,
        tooltip: LocaleKeys.chats_screens_chat_conversation_options_tooltip
            .tr(),
      ),
      items: [
        AuraPopupMenuItem(
          title: const TextLocale(LocaleKeys.common_delete),
          onTap: onDelete,
          leading: const AuraIcon(Icons.delete_outline),
          variant: .error,
        ),
      ],
      controller: controller,
    );
  }
}
