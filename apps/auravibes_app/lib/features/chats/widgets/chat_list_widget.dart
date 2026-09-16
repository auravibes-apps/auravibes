// Required: Existing test and UI helpers keep compact return flow.
// Required: UI callbacks stay local to their widgets.
// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/chats/widgets/delete_conversation_confirm_dialog.dart';
import 'package:auravibes_app/features/chats/widgets/rename_conversation_dialog.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
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
const _conversationSearchStatusSize = 16.0;

typedef _ChatListEffectsState = ({
  AsyncValue<List<ConversationEntity>> chatListAsync,
  ValueNotifier<List<ConversationEntity>> loadedChats,
  ValueNotifier<bool> hasMore,
  ValueNotifier<bool> showSearchInput,
});

typedef _ChatListPaginationState = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  String search,
  ValueNotifier<List<ConversationEntity>> loadedChats,
  ValueNotifier<bool> hasMore,
  ValueNotifier<bool> isLoadingMore,
});

class _ChatListViewState {
  new({
    required _ChatListDataState data,
    required _ChatListVisibleData visible,
    required _ChatListActions actions,
  }) : chats = visible.chats,
       hasMore = visible.hasMore,
       hasError = data.hasError,
       isLoadingMore = visible.isLoadingMore,
       isSearching = data.isDebouncing || data.isRefreshing,
       isRefreshing = data.isRefreshing,
       onLoadMore = actions.onLoadMore,
       onSearchChanged = actions.onSearchChanged,
       searchController = actions.searchController,
       searchQuery = actions.searchQuery,
       showSearchInput = data.hasSearchInput,
       workspaceId = actions.workspaceId;

  final List<ConversationEntity> chats;
  final bool hasMore;
  final bool hasError;
  final bool isLoadingMore;
  final bool isSearching;
  final bool isRefreshing;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final bool showSearchInput;
  final String workspaceId;
}

typedef _ChatListHookState = ({
  _ChatListInputState input,
  _ChatListResultsState results,
  String normalizedSearch,
  String? debouncedSearch,
  AsyncValue<List<ConversationEntity>> chatListAsync,
});

typedef _ChatListInputState = ({
  TextEditingController searchController,
  ValueNotifier<String> searchText,
  ValueNotifier<bool> showSearchInput,
});

typedef _ChatListResultsState = ({
  ValueNotifier<List<ConversationEntity>> loadedChats,
  ValueNotifier<bool> hasMore,
  ValueNotifier<bool> isLoadingMore,
});

typedef _ChatListDataState = ({
  String databaseSearch,
  List<ConversationEntity>? fetchedChats,
  bool isRefreshing,
  bool hasError,
  bool isDebouncing,
  bool hasSearchInput,
  bool fetchedHasMore,
});

typedef _ChatListRuntimeState = ({
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
  _ChatListHookState hooks,
});

typedef _ChatListVisibleData = ({
  List<ConversationEntity> chats,
  bool hasMore,
  bool isLoadingMore,
});

typedef _ChatListActions = ({
  VoidCallback onLoadMore,
  ValueChanged<String> onSearchChanged,
  TextEditingController searchController,
  String searchQuery,
  String workspaceId,
});

typedef _ChatListActionCallbacks = ({
  VoidCallback onLoadMore,
  ValueChanged<String> onSearchChanged,
});

Dispose? _resetSearchEffect(ValueNotifier<bool> hasMore) {
  hasMore.value = false;

  return null;
}

Dispose? _updateFirstPageEffect(_ChatListEffectsState state) {
  if (state.chatListAsync case AsyncData(:final value)) {
    state.loadedChats.value = value.take(_conversationPageSize).toList();
    state.hasMore.value = value.length > _conversationPageSize;
    if (value.isNotEmpty) state.showSearchInput.value = true;
  }

  return null;
}

Future<void> _loadMoreConversations(_ChatListPaginationState state) async {
  final isLoadingMore = state.isLoadingMore;
  if (isLoadingMore.value || !state.hasMore.value) return;
  isLoadingMore.value = true;
  await _loadNextConversationPage(state, isLoadingMore);
}

Future<void> _loadNextConversationPage(
  _ChatListPaginationState state,
  ValueNotifier<bool> isLoadingMore,
) async {
  final context = state.context;
  final nextPageProvider = _nextConversationPageProvider(state);
  final pageSubscription = _listenForNextConversationPage(
    state.ref,
    nextPageProvider,
    isLoadingMore,
  );
  try {
    final nextPage = await _readNextConversationPage(
      state.ref,
      nextPageProvider,
    );
    if (!context.mounted) return;
    _appendNextConversationPage(state, nextPage);
  } finally {
    pageSubscription.close();
    _stopLoadingMore(context, isLoadingMore);
  }
}

ProviderSubscription<AsyncValue<List<ConversationEntity>>>
_listenForNextConversationPage(
  WidgetRef ref,
  ConversationsStreamProvider provider,
  ValueNotifier<bool> isLoadingMore,
) => ref.listenManual(provider, (_, _) => isLoadingMore.value = true);

Future<List<ConversationEntity>> _readNextConversationPage(
  WidgetRef ref,
  ConversationsStreamProvider provider,
) => ref.read(provider.future);

ConversationsStreamProvider _nextConversationPageProvider(
  _ChatListPaginationState state,
) => conversationsStreamProvider(
  workspaceId: state.workspaceId,
  search: state.search,
  pagination: (
    limit: _conversationPageSize + 1,
    offset: state.loadedChats.value.length,
  ),
);

void _stopLoadingMore(BuildContext context, ValueNotifier<bool> isLoadingMore) {
  if (context.mounted) isLoadingMore.value = false;
}

void _appendNextConversationPage(
  _ChatListPaginationState state,
  List<ConversationEntity> nextPage,
) {
  final loadedChats = state.loadedChats;
  final existingIds = loadedChats.value.map((chat) => chat.id).toSet();
  final nextChats = _newConversationPage(nextPage, existingIds);
  loadedChats.value = [...loadedChats.value, ...nextChats];
  state.hasMore.value = nextPage.length > _conversationPageSize;
}

List<ConversationEntity> _newConversationPage(
  List<ConversationEntity> nextPage,
  Set<String> existingIds,
) => nextPage
    .take(_conversationPageSize)
    .where((chat) => !existingIds.contains(chat.id))
    .toList();

class const ChatListWidget({required final String workspaceId, super.key})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChatListContent(
      state: _useChatListState(context, ref, workspaceId),
    );
  }
}

_ChatListHookState _useChatListHookState(WidgetRef ref, String workspaceId) {
  final input = _useChatListInputState();
  final results = _useChatListResultsState();
  final query = _useChatListQueryState(ref, workspaceId, input.searchText);

  return (
    input: input,
    results: results,
    normalizedSearch: query.normalizedSearch,
    debouncedSearch: query.debouncedSearch,
    chatListAsync: query.chatListAsync,
  );
}

_ChatListInputState _useChatListInputState() => (
  searchController: useTextEditingController(),
  searchText: useState(''),
  showSearchInput: useState(false),
);

_ChatListResultsState _useChatListResultsState() => (
  loadedChats: useState<List<ConversationEntity>>([]),
  hasMore: useState(false),
  isLoadingMore: useState(false),
);

typedef _ChatListQueryState = ({
  String normalizedSearch,
  String? debouncedSearch,
  AsyncValue<List<ConversationEntity>> chatListAsync,
});

_ChatListQueryState _useChatListQueryState(
  WidgetRef ref,
  String workspaceId,
  ValueNotifier<String> searchText,
) {
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
      pagination: (limit: _conversationPageSize + 1, offset: 0),
    ),
  );

  return (
    normalizedSearch: normalizedSearch,
    debouncedSearch: debouncedSearch,
    chatListAsync: chatListAsync,
  );
}

_ChatListDataState _chatListDataState(_ChatListHookState hooks) {
  final chatListAsync = hooks.chatListAsync;
  final fetchedChats = chatListAsync.asData?.value;
  final search = _chatListSearchData(hooks, fetchedChats);

  return (
    databaseSearch: search.databaseSearch,
    fetchedChats: fetchedChats,
    isRefreshing: chatListAsync.isLoading,
    hasError: chatListAsync.hasError,
    isDebouncing: search.isDebouncing,
    hasSearchInput: search.hasSearchInput,
    fetchedHasMore: search.fetchedHasMore,
  );
}

typedef _ChatListSearchData = ({
  String databaseSearch,
  bool isDebouncing,
  bool hasSearchInput,
  bool fetchedHasMore,
});

_ChatListSearchData _chatListSearchData(
  _ChatListHookState hooks,
  List<ConversationEntity>? fetchedChats,
) {
  final debouncedSearch = hooks.debouncedSearch;

  return (
    databaseSearch: debouncedSearch ?? '',
    isDebouncing: _isSearchDebouncing(hooks.normalizedSearch, debouncedSearch),
    hasSearchInput:
        hooks.input.showSearchInput.value || fetchedChats?.isNotEmpty == true,
    fetchedHasMore:
        fetchedChats != null && fetchedChats.length > _conversationPageSize,
  );
}

_ChatListViewState _useChatListState(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
) {
  final hooks = _useChatListHookState(ref, workspaceId);
  _useChatListEffects(hooks);

  return _createChatListViewState((
    context: context,
    ref: ref,
    workspaceId: workspaceId,
    hooks: hooks,
  ));
}

void _useChatListEffects(_ChatListHookState hooks) {
  _useChatListSearchEffect(hooks);
  _useChatListFirstPageEffect(hooks);
}

void _useChatListSearchEffect(_ChatListHookState hooks) {
  final databaseSearch = hooks.debouncedSearch ?? '';
  useEffect(() => _resetSearchEffect(hooks.results.hasMore), [databaseSearch]);
}

void _useChatListFirstPageEffect(_ChatListHookState hooks) {
  final effectsState = (
    chatListAsync: hooks.chatListAsync,
    loadedChats: hooks.results.loadedChats,
    hasMore: hooks.results.hasMore,
    showSearchInput: hooks.input.showSearchInput,
  );
  useEffect(() => _updateFirstPageEffect(effectsState), [hooks.chatListAsync]);
}

_ChatListViewState _createChatListViewState(_ChatListRuntimeState runtime) {
  final hooks = runtime.hooks;
  final data = _chatListDataState(hooks);
  final visible = _chatListVisibleData(hooks.results, data);
  final actions = _chatListActions(runtime, data.databaseSearch);

  return _ChatListViewState(data: data, visible: visible, actions: actions);
}

_ChatListVisibleData _chatListVisibleData(
  _ChatListResultsState results,
  _ChatListDataState data,
) {
  final loaded = results.loadedChats.value;

  return (
    chats: loaded.isEmpty
        ? data.fetchedChats?.take(_conversationPageSize).toList() ?? const []
        : loaded,
    hasMore: results.hasMore.value || (loaded.isEmpty && data.fetchedHasMore),
    isLoadingMore: results.isLoadingMore.value,
  );
}

_ChatListActions _chatListActions(
  _ChatListRuntimeState runtime,
  String databaseSearch,
) {
  final input = runtime.hooks.input;
  final searchText = input.searchText;
  final paginationState = _chatListPaginationState(runtime, databaseSearch);
  final callbacks = _chatListActionCallbacks(searchText, paginationState);

  return (
    onLoadMore: callbacks.onLoadMore,
    onSearchChanged: callbacks.onSearchChanged,
    searchController: input.searchController,
    searchQuery: searchText.value,
    workspaceId: runtime.workspaceId,
  );
}

_ChatListActionCallbacks _chatListActionCallbacks(
  ValueNotifier<String> searchText,
  _ChatListPaginationState paginationState,
) => (
  onLoadMore: () => unawaited(_loadMoreConversations(paginationState)),
  onSearchChanged: (value) => searchText.value = value,
);

_ChatListPaginationState _chatListPaginationState(
  _ChatListRuntimeState runtime,
  String search,
) {
  final results = runtime.hooks.results;

  return (
    context: runtime.context,
    ref: runtime.ref,
    workspaceId: runtime.workspaceId,
    search: search,
    loadedChats: results.loadedChats,
    hasMore: results.hasMore,
    isLoadingMore: results.isLoadingMore,
  );
}

bool _isSearchDebouncing(String normalizedSearch, String? debouncedSearch) =>
    debouncedSearch == null
    ? normalizedSearch.isNotEmpty
    : debouncedSearch != normalizedSearch;

class const _ChatListContent({required final _ChatListViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    final viewState = state;
    if (!viewState.showSearchInput && viewState.isRefreshing) {
      return const Center(child: AuraSpinner());
    }
    if (!viewState.showSearchInput && viewState.hasError) {
      return const Center(
        child: AuraText(
          child: TextLocale(LocaleKeys.workspace_management_unexpected_error),
        ),
      );
    }

    return _ChatListLoaded(state: viewState);
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
      onTogglePin: () => _togglePin(chat),
      onRename: () => _handleRename(context),
      onMenuToggle: _menuController.toggle,
      onTap: () => _openConversation(context),
    );
  }

  Future<void> _handleRename(BuildContext context) async {
    final title = await RenameConversationDialog.show(
      context,
      title: widget.chat.title,
    );
    if (title == null) return;

    await ref
        .read(
          conversationChatProvider(widget.workspaceId, widget.chat.id).notifier,
        )
        .rename(widget.chat, title);
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

  Future<void> _togglePin(ConversationEntity chat) async {
    if (await _toggleCloudPin(chat)) return;
    await _toggleLocalPin(chat);
  }

  Future<bool> _toggleCloudPin(ConversationEntity chat) async {
    final cloud = await ref.read(
      cloudConversationUsecaseProvider(chat.workspaceId).future,
    );
    if (cloud == null) return false;

    await _updateCloudPin(cloud, chat);
    if (!mounted) return true;
    ref.invalidate(conversationsStreamProvider(workspaceId: chat.workspaceId));

    return true;
  }

  Future<void> _updateCloudPin(
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

  Future<void> _toggleLocalPin(ConversationEntity chat) async {
    if (!mounted) return;
    final patch = ConversationPatch(isPinned: !chat.isPinned);
    try {
      final _ = await ref
          .read(conversationRepositoryProvider)
          .patchConversation(chat.id, patch);
    } on ConversationPinLimitException {
      return;
    }
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
  required final VoidCallback onTogglePin,
  required final VoidCallback onRename,
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
      onTogglePin: onTogglePin,
      onRename: onRename,
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

class const _ChatListLoaded({required final _ChatListViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    final viewState = state;
    if (!viewState.showSearchInput) {
      return _ChatListEmptyState(workspaceId: viewState.workspaceId);
    }

    return _ChatListLoadedBody(state: viewState);
  }
}

class const _ChatListLoadedBody({required final _ChatListViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Column(
    children: [
      _ChatListSearchInput(state: state),
      Expanded(child: _ChatListResults(state: state)),
      if (state.hasMore && !state.isRefreshing && !state.hasError)
        _ChatListLoadMore(state: state),
    ],
  );
}

class _ChatListSearchInput extends StatelessWidget {
  new({required _ChatListViewState state})
    : _input = AuraInput(
        controller: state.searchController,
        placeholder: const TextLocale(
          LocaleKeys.chats_screens_chats_list_search_placeholder,
        ),
        prefixIcon: const AuraIcon(Icons.search),
        suffixIcon: _ChatListSearchStatus(isSearching: state.isSearching),
        size: .small,
        onChanged: state.onSearchChanged,
      );

  final AuraInput _input;

  @override
  Widget build(BuildContext _) => Padding(
    padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
    child: _input,
  );
}

class const _ChatListSearchStatus({required final bool isSearching})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => SizedBox(
    width: _conversationSearchStatusSize,
    height: _conversationSearchStatusSize,
    child: AuraAnimatedContent(
      child: isSearching
          ? const AuraSpinner(
              key: ValueKey('conversation-searching'),
              size: .small,
            )
          : const SizedBox(key: ValueKey('conversation-idle')),
    ),
  );
}

class const _ChatListResults({required final _ChatListViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    final viewState = state;
    final chats = viewState.chats;
    final workspaceId = viewState.workspaceId;
    if (viewState.isRefreshing) {
      return const Center(child: AuraSpinner());
    }
    if (viewState.hasError) {
      return const Center(
        child: AuraText(
          child: TextLocale(LocaleKeys.workspace_management_unexpected_error),
        ),
      );
    }
    if (chats.isEmpty) {
      return _ChatListEmptyResults(state: viewState);
    }

    return _ChatListConversationList(chats: chats, workspaceId: workspaceId);
  }
}

class const _ChatListEmptyResults({required final _ChatListViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => state.searchQuery.trim().isEmpty
      ? _ChatListEmptyState(workspaceId: state.workspaceId)
      : const _ChatListSearchEmptyState();
}

class const _ChatListConversationList({
  required final List<ConversationEntity> chats,
  required final String workspaceId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemBuilder: (context, index) =>
        _ChatTile(chat: chats[index], workspaceId: workspaceId),
    separatorBuilder: (context, index) => const SizedBox(height: 10),
    itemCount: chats.length,
  );
}

class const _ChatListLoadMore({required final _ChatListViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: AuraButton(
      onPressed: state.onLoadMore,
      child: const TextLocale(LocaleKeys.common_show_more),
      size: .small,
      isLoading: state.isLoadingMore,
    ),
  );
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
  required final VoidCallback onTogglePin,
  required final VoidCallback onRename,
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
      onTogglePin: onTogglePin,
      onRename: onRename,
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
  required final VoidCallback onTogglePin,
  required final VoidCallback onRename,
  required final VoidCallback onMenuToggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: .start,
    children: [
      Expanded(
        child: _ChatTileInfo(chat: chat, title: title),
      ),
      _ChatTileModelBadge(displayName: modelDisplayName),
      _ChatTileMenu(
        chat: chat,
        controller: controller,
        onDelete: onDelete,
        onTogglePin: onTogglePin,
        onRename: onRename,
        onToggle: onMenuToggle,
      ),
    ],
  );
}

class const _ChatTileModelBadge({required final String? displayName})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final displayName = this.displayName;
    if (displayName == null) return const SizedBox(width: 8);

    return Row(
      mainAxisSize: .min,
      children: [
        const SizedBox(width: 8),
        AuraBadge.text(child: Text(displayName), variant: .info),
        const SizedBox(width: 8),
      ],
    );
  }
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
  required final ConversationEntity chat,
  required final AuraPopupMenuController controller,
  required final VoidCallback onDelete,
  required final VoidCallback onTogglePin,
  required final VoidCallback onRename,
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
        _chatTilePinItem(chat, onTogglePin),
        ..._chatTileMenuItems(onRename: onRename, onDelete: onDelete),
      ],
      controller: controller,
    );
  }
}

AuraPopupMenuItem _chatTilePinItem(
  ConversationEntity chat,
  VoidCallback onTogglePin,
) => AuraPopupMenuItem(
  title: TextLocale(
    chat.isPinned
        ? LocaleKeys.chats_screens_chat_conversation_unpin
        : LocaleKeys.chats_screens_chat_conversation_pin,
  ),
  onTap: onTogglePin,
  leading: AuraIcon(chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
);

List<AuraPopupMenuItem> _chatTileMenuItems({
  required VoidCallback onRename,
  required VoidCallback onDelete,
}) => [_chatTileRenameItem(onRename), _chatTileDeleteItem(onDelete)];

AuraPopupMenuItem _chatTileRenameItem(VoidCallback onRename) =>
    AuraPopupMenuItem(
      title: const TextLocale(
        LocaleKeys.chats_screens_chat_conversation_rename,
      ),
      onTap: onRename,
      leading: const AuraIcon(Icons.edit_outlined),
    );

AuraPopupMenuItem _chatTileDeleteItem(VoidCallback onDelete) =>
    AuraPopupMenuItem(
      title: const TextLocale(LocaleKeys.common_delete),
      onTap: onDelete,
      leading: const AuraIcon(Icons.delete_outline),
      variant: .error,
    );
