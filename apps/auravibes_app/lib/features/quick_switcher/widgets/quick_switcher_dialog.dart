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
    final provider = quickSwitcherEntriesProvider(widget.workspaceId);
    final state = ref.watch(provider);

    return AuraAlertDialog(
      title: const TextLocale(LocaleKeys.quick_switcher_title),
      message: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: .min,
          children: [
            Focus(
              child: TextField(
                controller: _queryController,
                focusNode: _searchFocus,
                decoration: .new(
                  hintText: LocaleKeys.quick_switcher_search.tr(),
                  prefixIcon: const Icon(Icons.search),
                ),
                autofocus: true,
                onChanged: _onQueryChanged,
                onSubmitted: (_) => _activateSelected(),
              ),
              onKeyEvent: _handleSearchKey,
            ),
            const SizedBox(height: 8),
            switch (state) {
              AsyncLoading() => const SizedBox(
                height: 180,
                child: Center(
                  child: TextLocale(LocaleKeys.quick_switcher_loading),
                ),
              ),
              AsyncError() => _QuickSwitcherLoadError(onRetry: _retry),
              AsyncData(:final value) => _QuickSwitcherResultsList(
                entries: _filterEntries(
                  context,
                  value.entries,
                  _queryController.text,
                ),
                hasUnavailableResults: value.hasUnavailableResults,
                selectedIndex: _selectedIndex,
                scrollController: _resultsScrollController,
                onSelect: _select,
              ),
            },
            const SizedBox(height: 8),
            const TextLocale(LocaleKeys.quick_switcher_keyboard_hint),
          ],
        ),
      ),
      dismissLabel: const TextLocale(LocaleKeys.common_close),
    );
  }

  void _retry() {
    ref
      ..invalidate(allWorkspacesProvider)
      ..invalidate(quickSwitcherEntriesProvider(widget.workspaceId));
  }

  KeyEventResult _handleSearchKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return .ignored;

    return switch (event.logicalKey) {
      .arrowDown => _moveSelection(1),
      .arrowUp => _moveSelection(-1),
      .enter || .numpadEnter => _activateSelected(),
      .escape => _dismiss(),
      _ => .ignored,
    };
  }

  KeyEventResult _moveSelection(int direction) {
    final entries = _visibleEntries;
    if (entries.isEmpty) return .handled;

    final selectedIndex = _selectedIndex < entries.length ? _selectedIndex : 0;
    setState(() {
      _selectedIndex =
          (selectedIndex + direction + entries.length) % entries.length;
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
    final entryCount = _visibleEntries.length;
    if (entryCount < 2) return;

    final position = _resultsScrollController.position;
    final itemExtent =
        (position.maxScrollExtent + position.viewportDimension) / entryCount;
    final selectedIndex = _selectedIndex < entryCount ? _selectedIndex : 0;
    final itemTop = position.minScrollExtent + selectedIndex * itemExtent;
    final itemBottom = itemTop + itemExtent;
    final viewportTop = position.pixels;
    final viewportBottom = viewportTop + position.viewportDimension;
    final target = switch (itemTop < viewportTop) {
      true => itemTop,
      false when itemBottom > viewportBottom =>
        itemBottom - position.viewportDimension,
      _ => null,
    };
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
      final index = _selectedIndex < entries.length ? _selectedIndex : 0;
      _select(entries[index]);
    }

    return .handled;
  }

  KeyEventResult _dismiss() {
    Navigator.of(context).pop();

    return .handled;
  }

  void _select(QuickSwitcherEntry entry) => Navigator.of(context).pop(entry);
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
    final selectedIndex = this.selectedIndex < entries.length
        ? this.selectedIndex
        : 0;
    if (entries.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: TextLocale(LocaleKeys.quick_switcher_no_results)),
      );
    }

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        Semantics(
          key: const ValueKey<String>('quick_switcher_selection_announcement'),
          child: const SizedBox.shrink(),
          container: true,
          liveRegion: true,
          label: LocaleKeys.quick_switcher_selection_announcement.tr(
            namedArgs: {
              'title': _entryTitle(context, entries[selectedIndex]),
              'subtitle': _entrySubtitle(context, entries[selectedIndex]),
            },
            context: context,
          ),
        ),
        if (hasUnavailableResults)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: TextLocale(LocaleKeys.quick_switcher_partial_results),
          ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            controller: scrollController,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final title = _entryTitle(context, entry);
              final subtitle = _entrySubtitle(context, entry);
              final isSelected = index == selectedIndex;

              return Semantics(
                child: ExcludeSemantics(
                  child: Material(
                    type: .transparency,
                    child: ListTile(
                      leading: Icon(_entryIcon(entry.type)),
                      title: Text(title, overflow: .ellipsis, maxLines: 1),
                      subtitle: Text(
                        subtitle,
                        overflow: .ellipsis,
                        maxLines: 1,
                      ),
                      dense: true,
                      onTap: () => onSelect(entry),
                      selected: isSelected,
                    ),
                  ),
                ),
                selected: isSelected,
                button: true,
                label: '$title, $subtitle',
                onTap: () => onSelect(entry),
              );
            },
            itemCount: entries.length,
          ),
        ),
      ],
    );
  }
}

class const _QuickSwitcherLoadError({required final VoidCallback onRetry})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 180,
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

  return entries.where((entry) {
    final title = _entryTitle(context, entry);
    final type = _entryKindKey(entry.type).tr(context: context);
    final searchable =
        '$title ${entry.searchTerms} ${entry.workspaceName} $type'
            .toLowerCase();

    return searchable.contains(normalizedQuery);
  }).toList();
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
