// Required: Existing test and UI helpers keep compact return flow.
// Required: UI callbacks stay local to their widgets.
// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/conversation_result.dart';
import 'package:auravibes_app/features/chats/providers/bulk_conversation_actions_provider.dart';
import 'package:auravibes_app/features/chats/providers/cloud_conversation_provider.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/usecases/bulk_conversation_actions_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/fork_conversation_usecase.dart';
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
import 'package:logging/logging.dart';
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
       onLoadMore = actions.callbacks.onLoadMore,
       onSearchChanged = actions.callbacks.onSearchChanged,
       searchController = actions.input.searchController,
       searchQuery = actions.input.searchText.value,
       showSearchInput = data.hasSearchInput,
       selectedChats = actions.results.selectedChats,
       onSelectionChanged = _conversationSelectionChanged(
         actions.results.selectedChats,
       ),
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
  final ValueNotifier<Map<String, ConversationEntity>> selectedChats;
  final _ChatListSelectionChanged onSelectionChanged;
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
  ValueNotifier<Map<String, ConversationEntity>> selectedChats,
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
  _ChatListActionCallbacks callbacks,
  _ChatListInputState input,
  _ChatListResultsState results,
  String workspaceId,
});

typedef _ChatListActionCallbacks = ({
  VoidCallback onLoadMore,
  ValueChanged<String> onSearchChanged,
});

typedef _ChatListSelectionChanged = void Function(
  ConversationEntity chat, {
  required bool selected,
});

typedef _ChatTileCallbacks = ({
  VoidCallback onFork,
  VoidCallback onDelete,
  VoidCallback onTogglePin,
  VoidCallback onRename,
  VoidCallback onMenuToggle,
  VoidCallback onTap,
  ValueChanged<bool> onSelectionChanged,
});

typedef _ChatTileSelectionState = ({
  bool isSelected,
  bool isSelectionMode,
  ValueChanged<bool> onSelectionChanged,
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
final _logger = Logger('chat_list');

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

  useEffect(() => _clearSelectedChats(results.selectedChats), [workspaceId]);
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
  selectedChats: useState<Map<String, ConversationEntity>>({}),
);

void Function()? _clearSelectedChats(
  ValueNotifier<Map<String, ConversationEntity>> selectedChats,
) {
  selectedChats.value = {};

  return null;
}

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
  final hooks = runtime.hooks;

  return (
    callbacks: _chatListActionCallbacks(
      hooks.input.searchText,
      _chatListPaginationState(runtime, databaseSearch),
    ),
    input: hooks.input,
    results: hooks.results,
    workspaceId: runtime.workspaceId,
  );
}

_ChatListSelectionChanged _conversationSelectionChanged(
  ValueNotifier<Map<String, ConversationEntity>> selectedChats,
) =>
    (chat, {required selected}) =>
        _setConversationSelection(selectedChats, chat, selected: selected);

_ChatListActionCallbacks _chatListActionCallbacks(
  ValueNotifier<String> searchText,
  _ChatListPaginationState paginationState,
) => (
  onLoadMore: () => unawaited(_loadMoreConversations(paginationState)),
  onSearchChanged: (value) => searchText.value = value,
);

void _setConversationSelection(
  ValueNotifier<Map<String, ConversationEntity>> selectedChats,
  ConversationEntity chat, {
  required bool selected,
}) {
  final updated = {...selectedChats.value};
  if (selected) {
    updated[chat.id] = chat;
  } else {
    final _ = updated.remove(chat.id);
  }
  selectedChats.value = updated;
}

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
  required final _ChatTileSelectionState selection,
  super.key,
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
  Widget build(BuildContext context) => _buildTileProvider(context);
}

extension on _ChatTileState {
  Widget _buildTileProvider(BuildContext context) => _ChatTileProvider(
    chat: widget.chat,
    workspaceId: widget.workspaceId,
    isSelected: widget.selection.isSelected,
    controller: _menuController,
    callbacks: _tileCallbacks(context),
  );

  _ChatTileCallbacks _tileCallbacks(BuildContext context) => (
    onFork: () => _handleFork(context),
    onDelete: () => _handleDelete(context),
    onTogglePin: () => _togglePin(widget.chat),
    onRename: () => _handleRename(context),
    onMenuToggle: _menuController.toggle,
    onTap: _selectionAwareTap(context),
    onSelectionChanged: widget.selection.onSelectionChanged,
  );

  VoidCallback _selectionAwareTap(BuildContext context) {
    final selection = widget.selection;

    return selection.isSelectionMode
        ? () => selection.onSelectionChanged(!selection.isSelected)
        : () => _openConversation(context);
  }
}

extension on _ChatTileState {
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

  Future<void> _handleDelete(BuildContext context) =>
      _confirmChatDelete(this, context);

  Future<void> _handleFork(BuildContext context) =>
      _forkChatAndNavigate(this, context);

  Future<void> _deleteChat(ConversationEntity chat) async {
    final _ = await ref
        .read(bulkConversationActionsUsecaseProvider)
        .delete(chat);
    if (!mounted) return;
    _invalidateConversations(chat.workspaceId);
  }

  Future<void> _togglePin(ConversationEntity chat) async {
    final updated = await ref
        .read(bulkConversationActionsUsecaseProvider)
        .setPinned(chat, isPinned: !chat.isPinned);
    if (!mounted || updated == null) return;
    _invalidateConversations(chat.workspaceId);
  }

  Future<String> _forkChat(ConversationEntity chat) async {
    final cloud = await ref.read(
      cloudConversationUsecaseProvider(chat.workspaceId).future,
    );
    if (cloud != null) {
      final fork = await cloud.fork(chat);
      _invalidateConversations(chat.workspaceId);

      return fork.id;
    } else {
      final fork = await ref.read(forkConversationUsecaseProvider).call(chat);
      _invalidateConversations(chat.workspaceId);

      return fork.id;
    }
  }

  void _invalidateConversations(String workspaceId) =>
      ref.invalidate(conversationsStreamProvider(workspaceId: workspaceId));

  void _openConversation(BuildContext context) {
    ConversationRoute(
      workspaceId: widget.workspaceId,
      chatId: widget.chat.id,
    ).go(context);
  }
}

Future<void> _forkChatAndNavigate(
  _ChatTileState state,
  BuildContext context,
) async {
  try {
    final forkId = await state._forkChat(state.widget.chat);
    if (!context.mounted) return;
    _navigateToChatFork(context, state.widget.workspaceId, forkId);
  } on Object {
    if (!context.mounted) return;
    _showChatForkError(context);
  }
}

void _navigateToChatFork(
  BuildContext context,
  String workspaceId,
  String forkId,
) {
  if (!context.mounted) return;
  ConversationRoute(workspaceId: workspaceId, chatId: forkId).go(context);
}

void _showChatForkError(BuildContext context) {
  if (!context.mounted) return;
  final _ = AuraSnackBars.show(
    context: context,
    content: const TextLocale(
      LocaleKeys.chats_screens_chat_conversation_fork_error,
    ),
    variant: .error,
  );
}

Future<void> _confirmChatDelete(
  _ChatTileState state,
  BuildContext context,
) async {
  final confirmed = await DeleteConversationConfirmDialog.show(context);
  if (!confirmed) return;
  if (!context.mounted) return;

  await _deleteChatWithErrorHandling(state, context);
}

Future<void> _deleteChatWithErrorHandling(
  _ChatTileState state,
  BuildContext context,
) async {
  try {
    await state._deleteChat(state.widget.chat);
  } on Object catch (error, stackTrace) {
    _logger.severe(
      'Failed to delete conversation ${state.widget.chat.id}',
      error,
      stackTrace,
    );
    if (!context.mounted) return;
    final _ = AuraSnackBars.show(
      context: context,
      content: TextLocale(_chatDeleteErrorKey(error)),
      variant: .error,
    );
  }
}

String _chatDeleteErrorKey(Object error) => error is CloudAppException
    ? CloudAppErrors.localizationKey(error)
    : LocaleKeys.chats_screens_chat_conversation_delete_error;

class const _ChatTileProvider({
  required final ConversationEntity chat,
  required final String workspaceId,
  required final bool isSelected,
  required final AuraPopupMenuController controller,
  required final _ChatTileCallbacks callbacks,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => _buildTile(ref);
}

extension on _ChatTileProvider {
  Widget _buildTile(WidgetRef ref) {
    final modelDisplayName = _chatModelDisplayName(ref, workspaceId, chat);
    final title = ref.watch(streamingTitleProvider(chat.id)) ?? chat.title;

    return _buildView(modelDisplayName, title);
  }

  Widget _buildView(String? modelDisplayName, String title) => _ChatTileView(
    chat: chat,
    isSelected: isSelected,
    modelDisplayName: modelDisplayName,
    title: title,
    controller: controller,
    callbacks: callbacks,
  );
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
      _ChatListBulkActions(
        workspaceId: state.workspaceId,
        selectedChats: state.selectedChats,
      ),
      _ChatListSearchInput(state: state),
      Expanded(child: _ChatListResults(state: state)),
      if (state.hasMore && !state.isRefreshing && !state.hasError)
        _ChatListLoadMore(state: state),
    ],
  );
}

class const _ChatListBulkActions({
  required final String workspaceId,
  required final ValueNotifier<Map<String, ConversationEntity>> selectedChats,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ChatListBulkActions> createState() =>
      _ChatListBulkActionsState();
}

class _ChatListBulkActionsState extends ConsumerState<_ChatListBulkActions> {
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<Map<String, ConversationEntity>>(
        valueListenable: widget.selectedChats,
        builder: (context, selected, _) => selected.isEmpty
            ? const SizedBox.shrink()
            : _buildActionBar(selected),
      );

  Widget _buildActionBar(Map<String, ConversationEntity> selected) =>
      _ChatListBulkActionBar(
        selected: selected,
        isWorking: _isWorking,
        callbacks: (
          onPin: (isPinned) =>
              unawaited(_setPins(selected.values.toList(), isPinned)),
          onDelete: () => unawaited(_deleteSelected()),
          onClear: () => widget.selectedChats.value = {},
        ),
      );

  Future<void> _setPins(List<ConversationEntity> chats, bool isPinned) async {
    if (_isWorking) return;
    await _withWorking(() => _applyPins(chats, isPinned));
  }

  Future<void> _applyPins(List<ConversationEntity> chats, bool isPinned) async {
    final result = await ref
        .read(bulkConversationActionsUsecaseProvider)
        .pinMany(chats, isPinned: isPinned);
    if (!mounted) return;

    _recordPinnedChats(widget.selectedChats, result.updated);
    _finishBulkAction(
      LocaleKeys.chats_screens_chats_list_bulk_pin_failures,
      result.failures,
      result.errors,
      action: 'pin',
    );
  }

  Future<void> _deleteSelected() async {
    if (_isWorking) return;
    final confirmed = await DeleteConversationConfirmDialog.show(
      context,
      bulk: true,
    );
    if (!confirmed || !mounted) return;
    final chats = widget.selectedChats.value.values.toList();
    if (chats.isEmpty) return;
    await _withWorking(() => _deleteChats(chats));
  }

  Future<void> _deleteChats(List<ConversationEntity> chats) async {
    final result = await ref
        .read(bulkConversationActionsUsecaseProvider)
        .deleteMany(chats);
    if (!mounted) return;

    _recordDeletedChats(widget.selectedChats, result.deleted);
    _finishBulkAction(
      LocaleKeys.chats_screens_chats_list_bulk_delete_failures,
      result.failures,
      result.errors,
      action: 'delete',
    );
  }

  Future<void> _withWorking(Future<void> Function() action) async {
    setState(() => _isWorking = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  void _finishBulkAction(
    String key,
    List<ConversationEntity> failures,
    List<BulkConversationOperationError> errors, {
    required String action,
  }) {
    if (!mounted) return;
    for (final failure in errors) {
      _logger.severe(
        'Failed to $action conversation ${failure.conversation.id}',
        failure.error,
        failure.stackTrace,
      );
    }
    ref.invalidate(
      conversationsStreamProvider(workspaceId: widget.workspaceId),
    );
    _showConversationFailures(context, key, failures);
  }
}

void _recordPinnedChats(
  ValueNotifier<Map<String, ConversationEntity>> selectedChats,
  List<ConversationEntity> chats,
) {
  final updated = {...selectedChats.value};
  for (final chat in chats) {
    updated[chat.id] = chat;
  }
  selectedChats.value = updated;
}

void _recordDeletedChats(
  ValueNotifier<Map<String, ConversationEntity>> selectedChats,
  List<ConversationEntity> chats,
) {
  final updated = {...selectedChats.value};
  for (final chat in chats) {
    final _ = updated.remove(chat.id);
  }
  selectedChats.value = updated;
}

void _showConversationFailures(
  BuildContext context,
  String key,
  List<ConversationEntity> failures,
) {
  if (failures.isEmpty || !context.mounted) return;
  final titles = failures.map((chat) => chat.title).join(', ');
  final _ = AuraSnackBars.show(
    context: context,
    content: TextLocale(key, args: [titles]),
    variant: .error,
  );
}

typedef _ChatListBulkActionCallbacks = ({
  ValueChanged<bool> onPin,
  VoidCallback onDelete,
  VoidCallback onClear,
});

class const _ChatListBulkActionBar({
  required final Map<String, ConversationEntity> selected,
  required final bool isWorking,
  required final _ChatListBulkActionCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const AuraEdgeInsetsGeometry.only(
      left: .base,
      top: .sm,
      right: .base,
    ).toEdgeInsets(context),
    child: _ChatListBulkActionLayout(
      count: selected.length,
      shouldPin: !selected.values.every((chat) => chat.isPinned),
      isWorking: isWorking,
      callbacks: callbacks,
    ),
  );
}

class const _ChatListBulkActionLayout({
  required final int count,
  required final bool shouldPin,
  required final bool isWorking,
  required final _ChatListBulkActionCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.auraTheme.fromSpacing(.sm);

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      crossAxisAlignment: .center,
      children: [
        _ChatListSelectionActions(
          count: count,
          shouldPin: shouldPin,
          isWorking: isWorking,
          callbacks: callbacks,
        ),
        _ChatListManagementActions(isWorking: isWorking, callbacks: callbacks),
      ],
    );
  }
}

class const _ChatListSelectionActions({
  required final int count,
  required final bool shouldPin,
  required final bool isWorking,
  required final _ChatListBulkActionCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.auraTheme.fromSpacing(.sm);

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      crossAxisAlignment: .center,
      children: [
        _ChatListSelectedCount(count: count),
        _ChatListBulkPinButton(
          shouldPin: shouldPin,
          isWorking: isWorking,
          onPin: callbacks.onPin,
        ),
      ],
    );
  }
}

class const _ChatListManagementActions({
  required final bool isWorking,
  required final _ChatListBulkActionCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.auraTheme.fromSpacing(.sm);

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      crossAxisAlignment: .center,
      children: [
        _ChatListBulkDeleteButton(
          isWorking: isWorking,
          onDelete: callbacks.onDelete,
        ),
        _ChatListBulkClearButton(
          isWorking: isWorking,
          onClear: callbacks.onClear,
        ),
      ],
    );
  }
}

class const _ChatListSelectedCount({required final int count})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(
      context.plural(LocaleKeys.chats_screens_chats_list_selected_count, count),
    ),
    style: .bodySmall,
  );
}

class const _ChatListBulkPinButton({
  required final bool shouldPin,
  required final bool isWorking,
  required final ValueChanged<bool> onPin,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraButton(
    onPressed: () => onPin(shouldPin),
    child: TextLocale(
      shouldPin
          ? LocaleKeys.chats_screens_chats_list_bulk_pin
          : LocaleKeys.chats_screens_chats_list_bulk_unpin,
    ),
    size: .small,
    isLoading: isWorking,
  );
}

class const _ChatListBulkDeleteButton({
  required final bool isWorking,
  required final VoidCallback onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraButton(
    onPressed: onDelete,
    child: const TextLocale(LocaleKeys.chats_screens_chats_list_bulk_delete),
    size: .small,
    isLoading: isWorking,
  );
}

class const _ChatListBulkClearButton({
  required final bool isWorking,
  required final VoidCallback onClear,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraIconButton(
    icon: Icons.close,
    onPressed: isWorking ? null : onClear,
    size: .small,
    tooltip: LocaleKeys.chats_screens_chats_list_clear_selection.tr(),
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
    if (viewState.chats.isEmpty) {
      return _ChatListEmptyResults(state: viewState);
    }

    return _ChatListConversationList(state: viewState);
  }
}

class const _ChatListEmptyResults({required final _ChatListViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => state.searchQuery.trim().isEmpty
      ? _ChatListEmptyState(workspaceId: state.workspaceId)
      : const _ChatListSearchEmptyState();
}

class const _ChatListConversationList({required final _ChatListViewState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemBuilder: _buildTile,
    separatorBuilder: (context, index) => const SizedBox(height: 10),
    itemCount: state.chats.length,
  );

  Widget _buildTile(BuildContext _, int index) =>
      _ChatListConversationListTile(state: state, index: index);
}

class const _ChatListConversationListTile({
  required final _ChatListViewState state,
  required final int index,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) =>
      ValueListenableBuilder<Map<String, ConversationEntity>>(
        valueListenable: state.selectedChats,
        builder: _buildChatTile,
      );

  Widget _buildChatTile(
    BuildContext _,
    Map<String, ConversationEntity> selected,
    Widget? _,
  ) {
    final chat = state.chats[index];

    return _ChatTile(
      chat: chat,
      workspaceId: state.workspaceId,
      selection: _tileSelection(chat, selected),
      key: ValueKey(chat.id),
    );
  }

  _ChatTileSelectionState _tileSelection(
    ConversationEntity chat,
    Map<String, ConversationEntity> selected,
  ) => (
    isSelected: selected.containsKey(chat.id),
    isSelectionMode: selected.isNotEmpty,
    onSelectionChanged: (isSelected) =>
        state.onSelectionChanged(chat, selected: isSelected),
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
  required final bool isSelected,
  required final String? modelDisplayName,
  required final String title,
  required final AuraPopupMenuController controller,
  required final _ChatTileCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: _ChatTileRow(
      chat: chat,
      isSelected: isSelected,
      modelDisplayName: modelDisplayName,
      title: title,
      controller: controller,
      callbacks: callbacks,
    ),
    onTap: callbacks.onTap,
    style: .border,
  );
}

class const _ChatTileRow({
  required final ConversationEntity chat,
  required final bool isSelected,
  required final String? modelDisplayName,
  required final String title,
  required final AuraPopupMenuController controller,
  required final _ChatTileCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Row(
    crossAxisAlignment: .start,
    children: [
      _ChatTileMainSection(
        chat: chat,
        isSelected: isSelected,
        title: title,
        onSelectionChanged: callbacks.onSelectionChanged,
      ),
      _ChatTileModelBadge(displayName: modelDisplayName),
      _ChatTileMenu(chat: chat, controller: controller, callbacks: callbacks),
    ],
  );
}

class const _ChatTileMainSection({
  required final ConversationEntity chat,
  required final bool isSelected,
  required final String title,
  required final ValueChanged<bool> onSelectionChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Expanded(
    child: Row(
      crossAxisAlignment: .start,
      children: [
        _ChatTileSelectionControl(
          conversationId: chat.id,
          isSelected: isSelected,
          title: title,
          onChanged: onSelectionChanged,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ChatTileInfo(chat: chat, title: title),
        ),
      ],
    ),
  );
}

class const _ChatTileSelectionControl({
  required final String conversationId,
  required final bool isSelected,
  required final String title,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCheckbox(
    value: isSelected,
    onChanged: onChanged,
    key: ValueKey('conversation-selection-$conversationId'),
    semanticLabel:
        (isSelected
                ? LocaleKeys.chats_screens_chats_list_deselect_conversation
                : LocaleKeys.chats_screens_chats_list_select_conversation)
            .tr(args: [title]),
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
  required final _ChatTileCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _buildMenu();
}

extension on _ChatTileMenu {
  Widget _buildMenu() => AuraPopupMenu(
    child: AuraIconButton(
      icon: Icons.more_vert,
      onPressed: callbacks.onMenuToggle,
      size: .small,
      tooltip: LocaleKeys.chats_screens_chat_conversation_options_tooltip.tr(),
    ),
    items: _menuItems(),
    controller: controller,
  );

  List<AuraPopupMenuItem> _menuItems() => [
    _chatTilePinItem(chat, callbacks.onTogglePin),
    AuraPopupMenuItem(
      title: const TextLocale(LocaleKeys.chats_screens_chat_conversation_fork),
      onTap: callbacks.onFork,
      leading: const AuraIcon(Icons.call_split_outlined),
    ),
    ..._chatTileMenuItems(
      onRename: callbacks.onRename,
      onDelete: callbacks.onDelete,
    ),
  ];
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
