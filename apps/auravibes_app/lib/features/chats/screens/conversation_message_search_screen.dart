import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_message_search_result.dart';
import 'package:auravibes_app/features/chats/providers/conversation_message_search_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _ConversationSearchScope { currentWorkspace, allWorkspaces }

class const ConversationMessageSearchScreen({
  required final String workspaceId,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConversationMessageSearchScreen> createState() =>
      _ConversationMessageSearchScreenState();
}

class _ConversationMessageSearchScreenState
    extends ConsumerState<ConversationMessageSearchScreen> {
  static const _searchAppBar = AuraAppBarWithDrawer(
    title: TextLocale(LocaleKeys.chats_screens_conversation_search_title),
  );

  final _queryController = TextEditingController();
  _ConversationSearchScope _scope = .currentWorkspace;
  ConversationMessageSearchPage _page = const (
    results: <ConversationMessageSearchResult>[],
    hasMore: false,
    hasError: false,
  );
  var _pagesLoaded = 0;
  var _isLoading = false;
  var _searchGeneration = 0;
  var _activeQuery = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScreen(
    child: _ConversationSearchBody(
      controls: _ConversationSearchControls(
        controller: _queryController,
        scope: _scope,
        onSelectionChanged: _selectScope,
        isLoading: _isLoading,
        onSearch: _search,
      ),
      results: _SearchResults(
        isLoading: _isLoading,
        query: _queryController.text,
        page: _page,
        loadNextPage: _loadNextPage,
      ),
    ),
    appBar: _searchAppBar,
  );

  void _selectScope(Set<_ConversationSearchScope> selected) {
    final scope = selected.single;
    if (scope == _scope) return;
    setState(() => _scope = scope);
    if (_queryController.text.trim().isNotEmpty) unawaited(_search());
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    final generation = ++_searchGeneration;
    setState(() => _startSearch(query));
    await _loadPage(query, 0, generation);
  }

  void _startSearch(String query) {
    _activeQuery = query;
    _page = const (
      results: <ConversationMessageSearchResult>[],
      hasMore: false,
      hasError: false,
    );
    _pagesLoaded = 0;
  }

  Future<void> _loadNextPage() =>
      _loadPage(_activeQuery, _pagesLoaded, _searchGeneration);

  Future<void> _loadPage(String query, int pageIndex, int generation) async {
    setState(() {
      _isLoading = true;
      _page = _searchPageWithError(_page, false);
    });
    try {
      final page = await _fetchPage(query, pageIndex);
      _applyPage(page, generation);
    } on Object {
      _applyPageError(generation);
    }
  }

  Future<ConversationMessageSearchPage> _fetchPage(
    String query,
    int pageIndex,
  ) => ref.read(
    conversationMessageSearchPageProvider((
      query: query,
      workspaceId: _scope == .currentWorkspace ? widget.workspaceId : null,
      offset: pageIndex * conversationMessageSearchPageSize,
    )).future,
  );

  void _applyPage(ConversationMessageSearchPage page, int generation) {
    if (!mounted || generation != _searchGeneration) return;
    setState(() {
      _page = _mergeSearchPage(_page, page);
      _pagesLoaded++;
      _isLoading = false;
    });
  }

  void _applyPageError(int generation) {
    if (!mounted || generation != _searchGeneration) return;
    setState(() {
      _page = _searchPageWithError(_page, true);
      _isLoading = false;
    });
  }
}

class const _ConversationSearchBody({
  required final Widget controls,
  required final Widget results,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: .stretch,
      children: [
        controls,
        const SizedBox(height: 8),
        Expanded(child: results),
      ],
    ),
  );
}

class const _ConversationSearchControls({
  required final TextEditingController controller,
  required final _ConversationSearchScope scope,
  required final ValueChanged<Set<_ConversationSearchScope>> onSelectionChanged,
  required final bool isLoading,
  required final Future<void> Function() onSearch,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _ConversationSearchQueryField(
        controller: controller,
        onSubmitted: onSearch,
      ),
      const SizedBox(height: 12),
      _ConversationSearchScopeSelector(
        scope: scope,
        onSelectionChanged: onSelectionChanged,
      ),
      const SizedBox(height: 12),
      _ConversationSearchActionButton(
        isLoading: isLoading,
        onPressed: onSearch,
      ),
    ],
  );
}

class const _ConversationSearchQueryField({
  required final TextEditingController controller,
  required final Future<void> Function() onSubmitted,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: .new(
      labelText: LocaleKeys.chats_screens_conversation_search_query.tr(),
      prefixIcon: const Icon(Icons.search),
    ),
    textInputAction: .search,
    maxLength: 256,
    onSubmitted: (_) => unawaited(onSubmitted()),
  );
}

const List<ButtonSegment<_ConversationSearchScope>>
_conversationSearchScopeSegments = [
  ButtonSegment(
    value: _ConversationSearchScope.currentWorkspace,
    label: TextLocale(
      LocaleKeys.chats_screens_conversation_search_current_workspace,
    ),
  ),
  ButtonSegment(
    value: _ConversationSearchScope.allWorkspaces,
    label: TextLocale(
      LocaleKeys.chats_screens_conversation_search_all_workspaces,
    ),
  ),
];

class const _ConversationSearchScopeSelector({
  required final _ConversationSearchScope scope,
  required final ValueChanged<Set<_ConversationSearchScope>> onSelectionChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      SegmentedButton<_ConversationSearchScope>(
        segments: _conversationSearchScopeSegments,
        selected: {scope},
        onSelectionChanged: onSelectionChanged,
      );
}

class const _ConversationSearchActionButton({
  required final bool isLoading,
  required final Future<void> Function() onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: isLoading ? null : () => unawaited(onPressed()),
    icon: const Icon(Icons.search),
    label: const TextLocale(
      LocaleKeys.chats_screens_conversation_search_search,
    ),
  );
}

class const _ConversationMessageSearchResultTile({
  required final ConversationMessageSearchResult result,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    title: _ConversationMessageSearchResultTitle(result: result),
    subtitle: _ConversationMessageSearchResultSubtitle(result: result),
    onTap: () => ConversationRoute(
      workspaceId: result.workspaceId,
      chatId: result.conversationId,
      messageId: result.messageId,
    ).go(context),
  );
}

class const _ConversationMessageSearchResultTitle({
  required final ConversationMessageSearchResult result,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    result.conversationTitle.isEmpty
        ? LocaleKeys.chats_screens_conversation_search_untitled_conversation
              .tr()
        : result.conversationTitle,
    overflow: .ellipsis,
    maxLines: 1,
  );
}

class const _ConversationMessageSearchResultSubtitle({
  required final ConversationMessageSearchResult result,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      _ConversationMessageSearchResultMetadata(result: result),
      Text(result.excerpt, overflow: .ellipsis, maxLines: 3),
    ],
  );
}

class const _ConversationMessageSearchResultMetadata({
  required final ConversationMessageSearchResult result,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final role = result.role == 'user'
        ? LocaleKeys.chats_screens_conversation_search_user_role.tr()
        : LocaleKeys.chats_screens_conversation_search_assistant_role.tr();

    return Text(
      '${result.workspaceName} | $role | '
      '${DateFormat.yMMMd().add_jm().format(result.createdAt)}',
      overflow: .ellipsis,
      maxLines: 1,
    );
  }
}

class const _SearchResults({
  required final bool isLoading,
  required final String query,
  required final ConversationMessageSearchPage page,
  required final Future<void> Function() loadNextPage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final results = page.results;
    final hasError = page.hasError;
    final hasResults = results.isNotEmpty;

    return Column(
      children: [
        _SearchResultsStatus(
          query: query,
          isLoading: isLoading,
          hasError: hasError,
          hasResults: hasResults,
        ),
        _SearchResultsError(visible: hasError && hasResults),
        Expanded(child: _SearchResultList(results: results)),
        _SearchResultsFooter(
          isLoading: isLoading,
          hasMore: page.hasMore,
          loadNextPage: loadNextPage,
        ),
      ],
    );
  }
}

class const _SearchResultsStatus({
  required final String query,
  required final bool isLoading,
  required final bool hasError,
  required final bool hasResults,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (isLoading && !hasResults) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasError && !hasResults) {
      return const Center(
        child: TextLocale(LocaleKeys.chats_screens_conversation_search_error),
      );
    }
    if (query.trim().isNotEmpty && !isLoading && !hasResults) {
      return const Center(
        child: TextLocale(LocaleKeys.chats_screens_conversation_search_empty),
      );
    }

    return const SizedBox.shrink();
  }
}

class const _SearchResultsError({required final bool visible})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => visible
      ? const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: TextLocale(LocaleKeys.chats_screens_conversation_search_error),
        )
      : const SizedBox.shrink();
}

class const _SearchResultList({
  required final List<ConversationMessageSearchResult> results,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView.separated(
    itemBuilder: (context, index) =>
        _ConversationMessageSearchResultTile(result: results[index]),
    separatorBuilder: (context, index) => const Divider(height: 1),
    itemCount: results.length,
  );
}

class const _SearchResultsFooter({
  required final bool isLoading,
  required final bool hasMore,
  required final Future<void> Function() loadNextPage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: CircularProgressIndicator(),
      );
    }
    if (!hasMore) return const SizedBox.shrink();

    return OutlinedButton(
      onPressed: () => unawaited(loadNextPage()),
      child: const TextLocale(
        LocaleKeys.chats_screens_conversation_search_load_more,
      ),
    );
  }
}

List<ConversationMessageSearchResult> _mergeSearchResults(
  List<ConversationMessageSearchResult> current,
  List<ConversationMessageSearchResult> next,
) => [...current, ...next]..sort(compareConversationMessageSearchResults);

ConversationMessageSearchPage _mergeSearchPage(
  ConversationMessageSearchPage current,
  ConversationMessageSearchPage next,
) => (
  results: _mergeSearchResults(current.results, next.results),
  hasMore: next.hasMore,
  hasError: next.hasError,
);

ConversationMessageSearchPage _searchPageWithError(
  ConversationMessageSearchPage page,
  bool hasError,
) => (results: page.results, hasMore: page.hasMore, hasError: hasError);
