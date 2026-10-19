import 'dart:async';

import 'package:auravibes_app/features/quick_switcher/models/quick_switcher_entry.dart';
import 'package:auravibes_app/features/quick_switcher/providers/quick_switcher_entries_provider.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_switcher.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

class const QuickSwitcherShortcutScope({
  required final String workspaceId,
  required final Widget child,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<QuickSwitcherShortcutScope> createState() =>
      _QuickSwitcherShortcutScopeState();
}

class _QuickSwitcherShortcutScopeState
    extends ConsumerState<QuickSwitcherShortcutScope> {
  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    skipTraversal: true,
    onKeyEvent: (node, event) => _handleShortcut(context, event),
    child: widget.child,
  );

  KeyEventResult _handleShortcut(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.keyK) {
      return KeyEventResult.ignored;
    }
    if (!_hasShortcutModifier(context)) return KeyEventResult.ignored;
    if (_isEditableTextFocused()) return KeyEventResult.ignored;

    unawaited(_openSwitcher());
    return KeyEventResult.handled;
  }

  bool _hasShortcutModifier(BuildContext context) {
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isAltPressed || keyboard.isShiftPressed) return false;

    final isMac = Theme.of(context).platform == TargetPlatform.macOS;

    return isMac
        ? keyboard.isMetaPressed && !keyboard.isControlPressed
        : keyboard.isControlPressed && !keyboard.isMetaPressed;
  }

  bool _isEditableTextFocused() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;

    return context.widget is EditableText ||
        context.findAncestorWidgetOfExactType<EditableText>() != null ||
        context.findAncestorWidgetOfExactType<TextField>() != null;
  }

  Future<void> _openSwitcher() async {
    final selected = await showDialog<QuickSwitcherEntry>(
      context: context,
      builder: (_) => QuickSwitcherDialog(workspaceId: widget.workspaceId),
    );
    if (!mounted || selected == null) return;

    ref
        .read(workspaceSwitcherProvider.notifier)
        .switchToWorkspace(
          selected.workspaceId,
          destinationLocation: _destinationFor(selected),
        );
  }

  String _destinationFor(QuickSwitcherEntry entry) => switch (entry.type) {
    .workspace ||
    .newConversation => NewChatRoute(workspaceId: entry.workspaceId).location,
    .conversation => ConversationRoute(
      workspaceId: entry.workspaceId,
      chatId: entry.id!,
    ).location,
    .agent => AgentDetailRoute(
      workspaceId: entry.workspaceId,
      agentId: entry.id!,
    ).location,
    .skill => SkillDetailRoute(
      workspaceId: entry.workspaceId,
      skillId: entry.id!,
    ).location,
    .settings => SettingsRoute(workspaceId: entry.workspaceId).location,
  };
}

class const QuickSwitcherDialog({required final String workspaceId, super.key})
    extends ConsumerStatefulWidget {
  @override
  ConsumerState<QuickSwitcherDialog> createState() =>
      _QuickSwitcherDialogState();
}

class _QuickSwitcherDialogState extends ConsumerState<QuickSwitcherDialog> {
  final _queryController = TextEditingController();
  final _resultsScrollController = ScrollController();
  late final FocusNode _searchFocus;
  var _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchFocus = FocusNode(onKeyEvent: _handleSearchKey);
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
            TextField(
              controller: _queryController,
              focusNode: _searchFocus,
              autofocus: true,
              onChanged: _onQueryChanged,
              onSubmitted: (_) => _activateSelected(),
              decoration: InputDecoration(
                hintText: LocaleKeys.quick_switcher_search.tr(),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            switch (state) {
              AsyncLoading() => const SizedBox(
                height: 180,
                child: Center(
                  child: TextLocale(LocaleKeys.quick_switcher_loading),
                ),
              ),
              AsyncError() => _QuickSwitcherLoadError(
                onRetry: () {
                  ref
                    ..invalidate(allWorkspacesProvider)
                    ..invalidate(provider);
                },
              ),
              AsyncData(:final value) => _QuickSwitcherResultsList(
                entries: _filterEntries(value.entries, _queryController.text),
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

  List<QuickSwitcherEntry> get _visibleEntries {
    final results = ref.read(quickSwitcherEntriesProvider(widget.workspaceId));
    return switch (results) {
      AsyncData(:final value) => _filterEntries(
        value.entries,
        _queryController.text,
      ),
      AsyncLoading() || AsyncError() => const [],
    };
  }

  KeyEventResult _handleSearchKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    return switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown => _moveSelection(1),
      LogicalKeyboardKey.arrowUp => _moveSelection(-1),
      LogicalKeyboardKey.enter ||
      LogicalKeyboardKey.numpadEnter => _activateSelected(),
      LogicalKeyboardKey.escape => _dismiss(),
      _ => KeyEventResult.ignored,
    };
  }

  KeyEventResult _moveSelection(int direction) {
    final entries = _visibleEntries;
    if (entries.isEmpty) return KeyEventResult.handled;
    final selectedIndex = _selectedIndex < entries.length ? _selectedIndex : 0;
    setState(() {
      _selectedIndex =
          (selectedIndex + direction + entries.length) % entries.length;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSelectedItemVisible();
    });

    return KeyEventResult.handled;
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

    unawaited(
      _resultsScrollController.animateTo(
        target
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble(),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      ),
    );
  }

  KeyEventResult _activateSelected() {
    final entries = _visibleEntries;
    if (entries.isNotEmpty) {
      final index = _selectedIndex < entries.length ? _selectedIndex : 0;
      _select(entries[index]);
    }

    return KeyEventResult.handled;
  }

  KeyEventResult _dismiss() {
    Navigator.of(context).pop();

    return KeyEventResult.handled;
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
          container: true,
          liveRegion: true,
          label: LocaleKeys.quick_switcher_selection_announcement.tr(
            namedArgs: {
              'title': _entryTitle(context, entries[selectedIndex]),
              'subtitle': _entrySubtitle(context, entries[selectedIndex]),
            },
            context: context,
          ),
          child: const SizedBox.shrink(),
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
            itemCount: entries.length,
            prototypeItem: _buildResult(context, 0, selectedIndex),
            itemBuilder: (context, index) =>
                _buildResult(context, index, selectedIndex),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context, int index, int selectedIndex) {
    final entry = entries[index];
    final title = _entryTitle(context, entry);
    final subtitle = _entrySubtitle(context, entry);
    final isSelected = index == selectedIndex;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title, $subtitle',
      onTap: () => onSelect(entry),
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            dense: true,
            selected: isSelected,
            leading: Icon(_entryIcon(entry.type)),
            title: Text(title, maxLines: 1, overflow: .ellipsis),
            subtitle: Text(subtitle, maxLines: 1, overflow: .ellipsis),
            onTap: () => onSelect(entry),
          ),
        ),
      ),
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
          variant: .text,
          child: const TextLocale(LocaleKeys.quick_switcher_retry),
        ),
      ],
    ),
  );
}

List<QuickSwitcherEntry> _filterEntries(
  List<QuickSwitcherEntry> entries,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return entries;

  return entries.where((entry) {
    final title = entry.titleKey == null ? entry.title : entry.titleKey!.tr();
    final type = _entryKindKey(entry.type).tr();
    final searchable =
        '$title ${entry.searchTerms} ${entry.workspaceName} $type'
            .toLowerCase();

    return searchable.contains(normalizedQuery);
  }).toList();
}

String _entryTitle(BuildContext context, QuickSwitcherEntry entry) =>
    entry.titleKey?.tr(context: context) ?? entry.title;

String _entrySubtitle(BuildContext context, QuickSwitcherEntry entry) {
  final kind = _entryKind(context, entry.type).tr(context: context);
  return entry.type == QuickSwitcherEntryType.workspace
      ? kind
      : '$kind · ${entry.workspaceName}';
}

String _entryKind(BuildContext context, QuickSwitcherEntryType type) =>
    _entryKindKey(type);

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
