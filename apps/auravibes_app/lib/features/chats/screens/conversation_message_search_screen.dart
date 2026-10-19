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
  final _queryController = TextEditingController();
  _ConversationSearchScope _scope = .currentWorkspace;
  List<ConversationMessageSearchResult> _results = const [];
  var _pagesLoaded = 0;
  var _hasMore = false;
  var _isLoading = false;
  var _hasError = false;
  var _searchGeneration = 0;
  var _activeQuery = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScreen(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          TextField(
            controller: _queryController,
            decoration: .new(
              labelText: LocaleKeys.chats_screens_conversation_search_query
                  .tr(),
              prefixIcon: const Icon(Icons.search),
            ),
            textInputAction: .search,
            maxLength: 256,
            onSubmitted: (_) => unawaited(_search()),
          ),
          const SizedBox(height: 12),
          SegmentedButton<_ConversationSearchScope>(
            segments: const [
              ButtonSegment(
                value: .currentWorkspace,
                label: TextLocale(
                  LocaleKeys
                      .chats_screens_conversation_search_current_workspace,
                ),
              ),
              ButtonSegment(
                value: .allWorkspaces,
                label: TextLocale(
                  LocaleKeys.chats_screens_conversation_search_all_workspaces,
                ),
              ),
            ],
            selected: {_scope},
            onSelectionChanged: _selectScope,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isLoading ? null : () => unawaited(_search()),
            icon: const Icon(Icons.search),
            label: const TextLocale(
              LocaleKeys.chats_screens_conversation_search_search,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _SearchResults(
              isLoading: _isLoading,
              hasError: _hasError,
              query: _queryController.text,
              results: _results,
              hasMore: _hasMore,
              loadNextPage: _loadNextPage,
            ),
          ),
        ],
      ),
    ),
    appBar: const AuraAppBarWithDrawer(
      title: TextLocale(LocaleKeys.chats_screens_conversation_search_title),
    ),
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
    setState(() {
      _activeQuery = query;
      _results = const [];
      _pagesLoaded = 0;
      _hasMore = false;
      _hasError = false;
    });
    await _loadPage(query, 0, generation);
  }

  Future<void> _loadNextPage() =>
      _loadPage(_activeQuery, _pagesLoaded, _searchGeneration);

  Future<void> _loadPage(String query, int pageIndex, int generation) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final page = await ref.read(
        conversationMessageSearchPageProvider((
          query: query,
          workspaceId: _scope == .currentWorkspace ? widget.workspaceId : null,
          offset: pageIndex * conversationMessageSearchPageSize,
        )).future,
      );
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = [..._results, ...page.results]
          ..sort(compareConversationMessageSearchResults);
        _pagesLoaded++;
        _hasMore = page.hasMore;
        _hasError = page.hasError;
        _isLoading = false;
      });
    } on Object {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }
}

class const _ConversationMessageSearchResultTile({
  required final ConversationMessageSearchResult result,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = result.conversationTitle.isEmpty
        ? LocaleKeys.chats_screens_conversation_search_untitled_conversation
              .tr()
        : result.conversationTitle;
    final role = result.role == 'user'
        ? LocaleKeys.chats_screens_conversation_search_user_role.tr()
        : LocaleKeys.chats_screens_conversation_search_assistant_role.tr();

    return ListTile(
      title: Text(title, overflow: .ellipsis, maxLines: 1),
      subtitle: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            '${result.workspaceName} | $role | '
            '${DateFormat.yMMMd().add_jm().format(result.createdAt)}',
            overflow: .ellipsis,
            maxLines: 1,
          ),
          Text(result.excerpt, overflow: .ellipsis, maxLines: 3),
        ],
      ),
      onTap: () => ConversationRoute(
        workspaceId: result.workspaceId,
        chatId: result.conversationId,
        messageId: result.messageId,
      ).go(context),
    );
  }
}

class const _SearchResults({
  required final bool isLoading,
  required final bool hasError,
  required final String query,
  required final List<ConversationMessageSearchResult> results,
  required final bool hasMore,
  required final Future<void> Function() loadNextPage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (isLoading && results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasError && results.isEmpty) {
      return const Center(
        child: TextLocale(LocaleKeys.chats_screens_conversation_search_error),
      );
    }
    if (query.trim().isNotEmpty && !isLoading && results.isEmpty) {
      return const Center(
        child: TextLocale(LocaleKeys.chats_screens_conversation_search_empty),
      );
    }

    return Column(
      children: [
        if (hasError)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: TextLocale(
              LocaleKeys.chats_screens_conversation_search_error,
            ),
          ),
        Expanded(
          child: ListView.separated(
            itemBuilder: (context, index) =>
                _ConversationMessageSearchResultTile(result: results[index]),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: results.length,
          ),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          )
        else if (hasMore)
          OutlinedButton(
            onPressed: () => unawaited(loadNextPage()),
            child: const TextLocale(
              LocaleKeys.chats_screens_conversation_search_load_more,
            ),
          ),
      ],
    );
  }
}
