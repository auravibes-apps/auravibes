import 'package:auravibes_app/features/quick_switcher/models/quick_switcher_entry.dart';
import 'package:auravibes_app/features/quick_switcher/providers/quick_switcher_entries_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const double _quickSwitcherPlaceholderHeight = 180;

class const QuickSwitcherDialog({required final String workspaceId, super.key})
    extends ConsumerStatefulWidget {
  @override
  ConsumerState<QuickSwitcherDialog> createState() =>
      _QuickSwitcherDialogState();
}

class _QuickSwitcherDialogState extends ConsumerState<QuickSwitcherDialog> {
  final _queryController = TextEditingController();
  final _resultsScrollController = ScrollController();
  final _searchFocus = FocusNode();
  var _selectedIndex = 0;

  List<QuickSwitcherEntry> get _visibleEntries {
    final results = ref.read(quickSwitcherEntriesProvider(widget.workspaceId));

    return switch (results) {
      AsyncData(:final value) => _filterEntries(
        context,
        value.entries,
        _queryController.text,
      ),
      AsyncLoading() || AsyncError() => const [],
    };
  }

  @override
  void dispose() {
    _queryController.dispose();
    _resultsScrollController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(quickSwitcherEntriesProvider(widget.workspaceId));

    return AuraAlertDialog(
      title: const TextLocale(LocaleKeys.quick_switcher_title),
      message: _QuickSwitcherDialogBody(state: this, results: results),
      dismissLabel: const TextLocale(LocaleKeys.common_close),
    );
  }

  KeyEventResult _handleSearchKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return .ignored;

    return switch (event.logicalKey) {
      .arrowDown => _moveSelection(1),
      .arrowUp => _moveSelection(-1),
      .enter || .numpadEnter => _activateSelected(),
      .escape => _dismissDialog(context),
      _ => .ignored,
    };
  }

  KeyEventResult _moveSelection(int direction) {
    final entries = _visibleEntries;
    if (entries.isEmpty) return .handled;

    setState(() {
      _selectedIndex = _nextSelectionIndex(
        _selectedIndex,
        direction,
        entries.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSelectedItemVisible();
    });

    return .handled;
  }

  void _onQueryChanged(String _) {
    setState(() => _selectedIndex = 0);
    if (_resultsScrollController.hasClients) {
      _resultsScrollController.jumpTo(0);
    }
  }

  void _ensureSelectedItemVisible() {
    if (!mounted || !_resultsScrollController.hasClients) return;

    final position = _resultsScrollController.position;
    final target = _selectedItemScrollTarget(
      position,
      _selectedIndex,
      _visibleEntries.length,
    );
    if (target == null) return;

    _resultsScrollController.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  KeyEventResult _activateSelected() {
    final entries = _visibleEntries;
    if (entries.isNotEmpty) {
      Navigator.of(context)
          .pop(entries[_safeSelectedIndex(_selectedIndex, entries.length)]);
    }

    return .handled;
  }

  void _retry() => _retryQuickSwitcher(ref, widget.workspaceId);

  void _select(QuickSwitcherEntry entry) => Navigator.of(context).pop(entry);
}

class const _QuickSwitcherDialogBody({
  required final _QuickSwitcherDialogState state,
  required final AsyncValue<QuickSwitcherEntries> results,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 360,
    child: Column(
      mainAxisSize: .min,
      children: [
        _QuickSwitcherSearchField(state: state),
        const SizedBox(height: 8),
        _QuickSwitcherAsyncResults(state: state, results: results),
        const SizedBox(height: 8),
        const TextLocale(LocaleKeys.quick_switcher_keyboard_hint),
      ],
    ),
  );
}

class const _QuickSwitcherSearchField({
  required final _QuickSwitcherDialogState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Focus(
    child: _QuickSwitcherSearchInput(state: state),
    onKeyEvent: state._handleSearchKey,
  );
}

class const _QuickSwitcherSearchInput({
  required final _QuickSwitcherDialogState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextField(
    controller: state._queryController,
    focusNode: state._searchFocus,
    decoration: .new(
      hintText: LocaleKeys.quick_switcher_search.tr(),
      prefixIcon: const Icon(Icons.search),
    ),
    autofocus: true,
    onChanged: state._onQueryChanged,
    onSubmitted: (_) => state._activateSelected(),
  );
}

class const _QuickSwitcherAsyncResults({
  required final _QuickSwitcherDialogState state,
  required final AsyncValue<QuickSwitcherEntries> results,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (results) {
    AsyncLoading() => const _QuickSwitcherLoading(),
    AsyncError() => _QuickSwitcherLoadError(onRetry: state._retry),
    AsyncData(:final value) => _QuickSwitcherResultsList(
      entries: _filterEntries(
        context,
        value.entries,
        state._queryController.text,
      ),
      hasUnavailableResults: value.hasUnavailableResults,
      selectedIndex: state._selectedIndex,
      scrollController: state._resultsScrollController,
      onSelect: state._select,
    ),
  };
}

class const _QuickSwitcherLoading() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: _quickSwitcherPlaceholderHeight,
    child: Center(child: TextLocale(LocaleKeys.quick_switcher_loading)),
  );
}

class const _QuickSwitcherResultsList({
  required final List<QuickSwitcherEntry> entries,
  required final bool hasUnavailableResults,
  required final int selectedIndex,
  required final ScrollController scrollController,
  required final ValueChanged<QuickSwitcherEntry> onSelect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const _QuickSwitcherNoResults();

    final safeSelectedIndex = _safeSelectedIndex(selectedIndex, entries.length);

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        _QuickSwitcherSelectionAnnouncement(entry: entries[safeSelectedIndex]),
        _QuickSwitcherEntryList(
          entries: entries,
          hasUnavailableResults: hasUnavailableResults,
          selectedIndex: safeSelectedIndex,
          scrollController: scrollController,
          onSelect: onSelect,
        ),
      ],
    );
  }
}

class const _QuickSwitcherNoResults() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: _quickSwitcherPlaceholderHeight,
    child: Center(child: TextLocale(LocaleKeys.quick_switcher_no_results)),
  );
}

class const _QuickSwitcherPartialResults() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: TextLocale(LocaleKeys.quick_switcher_partial_results),
  );
}

class const _QuickSwitcherSelectionAnnouncement({
  required final QuickSwitcherEntry entry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('quick_switcher_selection_announcement'),
    child: const SizedBox.shrink(),
    container: true,
    liveRegion: true,
    label: _selectionAnnouncementLabel(context, entry),
  );
}

class const _QuickSwitcherEntryList({
  required final List<QuickSwitcherEntry> entries,
  required final bool hasUnavailableResults,
  required final int selectedIndex,
  required final ScrollController scrollController,
  required final ValueChanged<QuickSwitcherEntry> onSelect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      if (hasUnavailableResults) const _QuickSwitcherPartialResults(),
      _QuickSwitcherEntryListView(
        entries: entries,
        selectedIndex: selectedIndex,
        scrollController: scrollController,
        onSelect: onSelect,
      ),
    ],
  );
}

class const _QuickSwitcherEntryListView({
  required final List<QuickSwitcherEntry> entries,
  required final int selectedIndex,
  required final ScrollController scrollController,
  required final ValueChanged<QuickSwitcherEntry> onSelect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 240,
    child: ListView.builder(
      controller: scrollController,
      itemBuilder: (context, index) => _QuickSwitcherEntryTile(
        entry: entries[index],
        isSelected: index == selectedIndex,
        onSelect: onSelect,
      ),
      itemCount: entries.length,
    ),
  );
}

class const _QuickSwitcherEntryTile({
  required final QuickSwitcherEntry entry,
  required final bool isSelected,
  required final ValueChanged<QuickSwitcherEntry> onSelect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = _entryTitle(context, entry);
    final subtitle = _entrySubtitle(context, entry);

    return Semantics(
      child: ExcludeSemantics(
        child: _QuickSwitcherTileContent(
          type: entry.type,
          title: title,
          subtitle: subtitle,
          isSelected: isSelected,
          onTap: _select,
        ),
      ),
      selected: isSelected,
      button: true,
      label: _entryAccessibilityLabel(title, subtitle),
      onTap: _select,
    );
  }

  void _select() => onSelect(entry);
}

class const _QuickSwitcherTileContent({
  required final QuickSwitcherEntryType type,
  required final String title,
  required final String subtitle,
  required final bool isSelected,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Material(
    type: .transparency,
    child: ListTile(
      leading: Icon(_entryIcon(type)),
      title: _QuickSwitcherEntryText(text: title),
      subtitle: _QuickSwitcherEntryText(text: subtitle),
      dense: true,
      onTap: onTap,
      selected: isSelected,
    ),
  );
}

class const _QuickSwitcherEntryText({required final String text})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Text(text, overflow: .ellipsis, maxLines: 1);
}

class const _QuickSwitcherLoadError({required final VoidCallback onRetry})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: _quickSwitcherPlaceholderHeight,
    child: Column(
      mainAxisAlignment: .center,
      children: [
        const TextLocale(LocaleKeys.quick_switcher_load_error),
        const SizedBox(height: 8),
        AuraButton(
          onPressed: onRetry,
          child: const TextLocale(LocaleKeys.quick_switcher_retry),
          variant: .text,
        ),
      ],
    ),
  );
}

List<QuickSwitcherEntry> _filterEntries(
  BuildContext context,
  List<QuickSwitcherEntry> entries,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return entries;

  return entries
      .where((entry) => _matchesQuery(context, entry, normalizedQuery))
      .toList();
}

bool _matchesQuery(
  BuildContext context,
  QuickSwitcherEntry entry,
  String query,
) => _entrySearchableText(context, entry).contains(query);

String _entrySearchableText(BuildContext context, QuickSwitcherEntry entry) {
  final title = _entryTitle(context, entry);
  final type = _entryKindKey(entry.type).tr(context: context);

  return '$title ${entry.searchTerms} ${entry.workspaceName} $type'
      .toLowerCase();
}

String _entryTitle(BuildContext context, QuickSwitcherEntry entry) =>
    switch (entry.type) {
      .newConversation => LocaleKeys.quick_switcher_new_conversation.tr(
        context: context,
      ),
      .settings => LocaleKeys.quick_switcher_settings.tr(context: context),
      .skill => _skillTitle(context, entry.titleKey, entry.title),
      _ => entry.title,
    };

String _skillTitle(BuildContext context, String? titleKey, String fallback) {
  final key = titleKey;
  if (key == null) return fallback;

  return key.tr(context: context);
}

String _entrySubtitle(BuildContext context, QuickSwitcherEntry entry) {
  final kind = _entryKindKey(entry.type).tr(context: context);

  return entry.type == .workspace ? kind : '$kind - ${entry.workspaceName}';
}

String _entryKindKey(QuickSwitcherEntryType type) => switch (type) {
  .workspace => LocaleKeys.quick_switcher_workspace,
  .conversation => LocaleKeys.quick_switcher_conversation,
  .agent => LocaleKeys.quick_switcher_agent,
  .skill => LocaleKeys.quick_switcher_skill,
  .newConversation || .settings => LocaleKeys.quick_switcher_action,
};

IconData _entryIcon(QuickSwitcherEntryType type) => switch (type) {
  .workspace => Icons.workspaces_outlined,
  .conversation => Icons.chat_bubble_outline,
  .agent => Icons.smart_toy_outlined,
  .skill => Icons.auto_awesome_outlined,
  .newConversation => Icons.add_comment_outlined,
  .settings => Icons.settings_outlined,
};

int _nextSelectionIndex(int selectedIndex, int direction, int entryCount) =>
    (selectedIndex + direction + entryCount) % entryCount;

int _safeSelectedIndex(int selectedIndex, int entryCount) =>
    selectedIndex < entryCount ? selectedIndex : 0;

double? _selectedItemScrollTarget(
  ScrollPosition position,
  int selectedIndex,
  int entryCount,
) {
  if (entryCount < 2) return null;

  final itemExtent =
      (position.maxScrollExtent + position.viewportDimension) / entryCount;
  final itemTop =
      position.minScrollExtent +
      _safeSelectedIndex(selectedIndex, entryCount) * itemExtent;

  return _visibleItemScrollTarget(position, itemTop, itemExtent);
}

double? _visibleItemScrollTarget(
  ScrollPosition position,
  double itemTop,
  double itemExtent,
) {
  final itemBottom = itemTop + itemExtent;
  final viewportTop = position.pixels;
  final viewportBottom = viewportTop + position.viewportDimension;
  if (itemTop < viewportTop) return itemTop;
  if (itemBottom > viewportBottom) {
    return itemBottom - position.viewportDimension;
  }

  return null;
}

void _retryQuickSwitcher(WidgetRef ref, String workspaceId) {
  ref
    ..invalidate(allWorkspacesProvider)
    ..invalidate(quickSwitcherEntriesProvider(workspaceId));
}

KeyEventResult _dismissDialog(BuildContext context) {
  Navigator.of(context).pop();

  return .handled;
}

String _selectionAnnouncementLabel(
  BuildContext context,
  QuickSwitcherEntry entry,
) => LocaleKeys.quick_switcher_selection_announcement.tr(
  namedArgs: _selectionAnnouncementArgs(context, entry),
  context: context,
);

Map<String, String> _selectionAnnouncementArgs(
  BuildContext context,
  QuickSwitcherEntry entry,
) => {
  'title': _entryTitle(context, entry),
  'subtitle': _entrySubtitle(context, entry),
};

String _entryAccessibilityLabel(String title, String subtitle) =>
    '$title, $subtitle';
