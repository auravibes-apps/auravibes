import 'dart:async';

import 'package:auravibes_app/domain/entities/conversation_message_search_result.dart';
import 'package:auravibes_app/features/chats/providers/conversation_message_search_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _ConversationSearchScope { currentWorkspace, allWorkspaces }

const _maxQueryLength = 256;
const _metadataDotCodePoint = 0x00B7;
const ConversationMessageSearchPage _emptySearchPage = (
  results: <ConversationMessageSearchResult>[],
  hasMore: false,
  hasError: false,
);
final _metadataSeparator = ' ${String.fromCharCode(_metadataDotCodePoint)} ';
final _queryInputFormatters = <TextInputFormatter>[
  LengthLimitingTextInputFormatter(_maxQueryLength),
];

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
  ConversationMessageSearchPage _page = _emptySearchPage;
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
        onClearQuery: _clearSearch,
        onSelectionChanged: _selectScope,
        isLoading: _isLoading,
        onSearch: _search,
      ),
      results: _SearchResults(
        isLoading: _isLoading,
        query: _activeQuery,
        scope: _scope,
        page: _page,
        loadNextPage: _loadNextPage,
      ),
    ),
    appBar: _searchAppBar,
  );

  void _clearSearch() {
    _searchGeneration++;
    _queryController.clear();
    setState(() => _startSearch(''));
  }

  void _selectScope(Set<_ConversationSearchScope> selected) {
    final scope = selected.single;
    if (scope == _scope) return;
    setState(() => _scope = scope);
    if (_queryController.text.trim().isNotEmpty) unawaited(_search());
  }

  Future<void> _search() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    final generation = ++_searchGeneration;
    setState(() => _startSearch(query));
    await _loadPage(query, 0, generation);
  }

  void _startSearch(String query) {
    _activeQuery = query;
    _page = _emptySearchPage;
    _pagesLoaded = 0;
    _isLoading = false;
  }

  Future<void> _loadNextPage() => _activeQuery.isEmpty
      ? _search()
      : _loadPage(_activeQuery, _pagesLoaded, _searchGeneration);

  Future<void> _loadPage(String query, int pageIndex, int generation) async {
    setState(() => _isLoading = true);
    try {
      final page = await _fetchSearchPage(
        ref,
        query: query,
        workspaceId: _scope == .currentWorkspace ? widget.workspaceId : null,
        pageIndex: pageIndex,
      );
      _applyPage(page, pageIndex, generation);
    } on Object {
      _applyPageError(generation);
    }
  }

  void _applyPage(
    ConversationMessageSearchPage page,
    int pageIndex,
    int generation,
  ) {
    if (!mounted || generation != _searchGeneration) return;
    setState(() {
      _page = _mergeSearchPage(_page, page, pageIndex);
      _pagesLoaded = _nextPagesLoaded(pageIndex, page.hasError);
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
  Widget build(BuildContext context) => AuraPadding(
    child: Column(
      crossAxisAlignment: .stretch,
      children: [
        controls,
        const SizedBox(height: 8),
        Expanded(child: results),
      ],
    ),
    padding: .medium,
  );
}

class const _ConversationSearchControls({
  required final TextEditingController controller,
  required final _ConversationSearchScope scope,
  required final VoidCallback onClearQuery,
  required final ValueChanged<Set<_ConversationSearchScope>> onSelectionChanged,
  required final bool isLoading,
  required final Future<void> Function() onSearch,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _ConversationSearchQueryField(
        controller: controller,
        onClear: onClearQuery,
        onSubmitted: onSearch,
      ),
      _ConversationSearchScopeSelector(
        scope: scope,
        onSelectionChanged: onSelectionChanged,
      ),
      _ConversationSearchActionButton(
        controller: controller,
        isLoading: isLoading,
        onPressed: onSearch,
      ),
    ],
    spacing: .sm,
    crossAxisAlignment: .stretch,
  );
}

class const _ConversationSearchQueryField({
  required final TextEditingController controller,
  required final VoidCallback onClear,
  required final Future<void> Function() onSubmitted,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => _ConversationSearchInput(
          controller: controller,
          hasText: value.text.isNotEmpty,
          onClear: onClear,
          onSubmitted: onSubmitted,
        ),
      );
}

class const _ConversationSearchInput({
  required final TextEditingController controller,
  required final bool hasText,
  required final VoidCallback onClear,
  required final Future<void> Function() onSubmitted,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    label: const TextLocale(LocaleKeys.chats_screens_conversation_search_query),
    prefixIcon: const AuraIcon(Icons.search),
    suffixIcon: _buildClearSuffix(hasText, onClear),
    size: .small,
    textInputAction: .search,
    inputFormatters: _queryInputFormatters,
    onSubmitted: (_) => unawaited(onSubmitted()),
  );
}

class const _ConversationSearchClearButton({
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.close,
    onPressed: onPressed,
    key: const ValueKey('conversation-search-clear'),
    size: .small,
    semanticLabel: LocaleKeys.common_clear_search.tr(context: context),
    tooltip: LocaleKeys.common_clear_search.tr(context: context),
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
  Widget build(BuildContext context) => SizedBox(
    width: .infinity,
    child: SegmentedButton<_ConversationSearchScope>(
      segments: _conversationSearchScopeSegments,
      selected: {scope},
      onSelectionChanged: onSelectionChanged,
    ),
  );
}

class const _ConversationSearchActionButton({
  required final TextEditingController controller,
  required final bool isLoading,
  required final Future<void> Function() onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => _ConversationSearchSubmitButton(
          canSearch: value.text.trim().isNotEmpty,
          isLoading: isLoading,
          onPressed: onPressed,
        ),
      );
}

class const _ConversationSearchSubmitButton({
  required final bool canSearch,
  required final bool isLoading,
  required final Future<void> Function() onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => unawaited(onPressed()),
    child: const TextLocale(
      LocaleKeys.chats_screens_conversation_search_search,
    ),
    key: const ValueKey('conversation-search-submit'),
    isLoading: isLoading,
    isFullWidth: true,
    disabled: !canSearch || isLoading,
  );
}

class const _ConversationMessageSearchResultTile({
  required final ConversationMessageSearchResult result,
  required final _ConversationSearchScope scope,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    title: _ConversationMessageSearchResultExcerpt(result: result),
    subtitle: _ConversationMessageSearchResultSubtitle(
      result: result,
      scope: scope,
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => _openSearchResult(context, result),
  );
}

class const _ConversationMessageSearchResultExcerpt({
  required final ConversationMessageSearchResult result,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Text(result.excerpt, overflow: .ellipsis, maxLines: 2);
}

class const _ConversationMessageSearchResultSubtitle({
  required final ConversationMessageSearchResult result,
  required final _ConversationSearchScope scope,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Column(
      crossAxisAlignment: .start,
      children: [
        _ConversationMessageSearchResultTitle(result: result),
        _ConversationMessageSearchResultMetadata(result: result, scope: scope),
      ],
    ),
  );
}

class const _ConversationMessageSearchResultTitle({
  required final ConversationMessageSearchResult result,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    result.conversationTitle.trim().isEmpty
        ? LocaleKeys.chats_screens_conversation_search_untitled_conversation
              .tr()
        : result.conversationTitle,
    overflow: .ellipsis,
    maxLines: 1,
  );
}

class const _ConversationMessageSearchResultMetadata({
  required final ConversationMessageSearchResult result,
  required final _ConversationSearchScope scope,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    _formatSearchResultMetadata(context, result, scope: scope),
    overflow: .ellipsis,
    maxLines: 1,
  );
}

class const _SearchResults({
  required final bool isLoading,
  required final String query,
  required final _ConversationSearchScope scope,
  required final ConversationMessageSearchPage page,
  required final Future<void> Function() loadNextPage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: _SearchResultsContent(
          query: query,
          isLoading: isLoading,
          scope: scope,
          page: page,
          loadNextPage: loadNextPage,
        ),
      ),
      _SearchResultsFooter(
        isLoading: isLoading,
        hasMore: page.hasMore,
        loadNextPage: loadNextPage,
      ),
    ],
  );
}

class const _SearchResultsContent({
  required final String query,
  required final bool isLoading,
  required final _ConversationSearchScope scope,
  required final ConversationMessageSearchPage page,
  required final Future<void> Function() loadNextPage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _SearchResultsErrorBanner(
        visible: page.hasError && !isLoading,
        onRetry: loadNextPage,
      ),
      _SearchResultsStatus(query: query, isLoading: isLoading, page: page),
      Expanded(
        child: _SearchResultList(results: page.results, scope: scope),
      ),
    ],
  );
}

class const _SearchResultsStatus({
  required final String query,
  required final bool isLoading,
  required final ConversationMessageSearchPage page,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (isLoading && page.results.isEmpty) {
      return const _SearchLoadingStatus();
    }
    if (_shouldShowEmptySearchStatus(query, isLoading, page)) {
      return const _SearchEmptyStatus();
    }

    return const SizedBox.shrink();
  }
}

class const _SearchEmptyStatus() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: TextLocale(LocaleKeys.chats_screens_conversation_search_empty),
    ),
  );
}

class const _SearchLoadingStatus() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: AuraColumn(
        children: [
          AuraSpinner(),
          TextLocale(LocaleKeys.chats_screens_conversation_search_loading),
        ],
        spacing: .sm,
        mainAxisSize: .min,
      ),
    ),
  );
}

class const _SearchResultsErrorBanner({
  required final bool visible,
  required final Future<void> Function() onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => visible
      ? Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: AuraCallout(
                  title: LocaleKeys.chats_screens_conversation_search_error
                      .tr(),
                  icon: Icons.error_outline,
                  tint: .error,
                ),
              ),
              const SizedBox(width: 8),
              _SearchResultsRetryButton(onRetry: onRetry),
            ],
          ),
        )
      : const SizedBox.shrink();
}

class const _SearchResultsRetryButton({
  required final Future<void> Function() onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => unawaited(onRetry()),
    child: const TextLocale(
      LocaleKeys.chats_screens_conversation_search_target_retry,
    ),
    variant: .outlined,
    tint: .error,
    size: .small,
  );
}

class const _SearchResultList({
  required final List<ConversationMessageSearchResult> results,
  required final _ConversationSearchScope scope,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: EdgeInsets.zero,
    itemBuilder: (context, index) => _ConversationMessageSearchResultTile(
      result: results[index],
      scope: scope,
    ),
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
    if (!hasMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AuraButton(
        onPressed: () => unawaited(loadNextPage()),
        child: const TextLocale(
          LocaleKeys.chats_screens_conversation_search_load_more,
        ),
        variant: .outlined,
        size: .small,
        isLoading: isLoading,
        disabled: isLoading,
      ),
    );
  }
}

bool _shouldShowEmptySearchStatus(
  String query,
  bool isLoading,
  ConversationMessageSearchPage page,
) =>
    query.trim().isNotEmpty &&
    !isLoading &&
    !page.hasError &&
    page.results.isEmpty;

Widget? _buildClearSuffix(bool hasText, VoidCallback onClear) =>
    hasText ? _ConversationSearchClearButton(onPressed: onClear) : null;

void _openSearchResult(
  BuildContext context,
  ConversationMessageSearchResult result,
) => ConversationRoute(
  workspaceId: result.workspaceId,
  chatId: result.conversationId,
  messageId: result.messageId,
).go(context);

String _formatSearchResultMetadata(
  BuildContext context,
  ConversationMessageSearchResult result, {
  required _ConversationSearchScope scope,
}) {
  final role = _formatSearchResultRole(result.role);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final timestamp = DateFormat.yMMMd(locale).add_jm().format(result.createdAt);

  return [
    if (scope == .allWorkspaces) result.workspaceName,
    role,
    timestamp,
  ].join(_metadataSeparator);
}

String _formatSearchResultRole(String role) => role == 'user'
    ? LocaleKeys.chats_screens_conversation_search_user_role.tr()
    : LocaleKeys.chats_screens_conversation_search_assistant_role.tr();

Future<ConversationMessageSearchPage> _fetchSearchPage(
  WidgetRef ref, {
  required String query,
  required String? workspaceId,
  required int pageIndex,
}) {
  final request = (
    query: query,
    workspaceId: workspaceId,
    offset: pageIndex * ConversationMessageSearchProvider.pageSize,
  );
  ref.invalidate(conversationMessageSearchPageProvider(request));

  return ref.read(conversationMessageSearchPageProvider(request).future);
}

int _nextPagesLoaded(int pageIndex, bool hasError) =>
    hasError ? pageIndex : pageIndex + 1;

List<ConversationMessageSearchResult> _mergeSearchResults(
  List<ConversationMessageSearchResult> current,
  List<ConversationMessageSearchResult> next,
) =>
    [...current, ...next]
      ..sort(ConversationMessageSearchProvider.compareResults);

ConversationMessageSearchPage _mergeSearchPage(
  ConversationMessageSearchPage current,
  ConversationMessageSearchPage next,
  int pageIndex,
) => (
  results: pageIndex == 0
      ? next.results
      : _mergeSearchResults(current.results, next.results),
  hasMore: next.hasMore,
  hasError: next.hasError,
);

ConversationMessageSearchPage _searchPageWithError(
  ConversationMessageSearchPage page,
  bool hasError,
) => (results: page.results, hasMore: page.hasMore, hasError: hasError);
