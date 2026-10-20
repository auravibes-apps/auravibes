import 'dart:async';

import 'package:auravibes_app/features/quick_switcher/models/quick_switcher_entry.dart';
import 'package:auravibes_app/features/quick_switcher/widgets/quick_switcher_dialog.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_switcher.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
    child: widget.child,
    autofocus: true,
    onKeyEvent: (node, event) => _handleShortcut(context, event),
    skipTraversal: true,
  );

  KeyEventResult _handleShortcut(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.keyK) {
      return .ignored;
    }
    if (!_hasShortcutModifier(context)) return .ignored;
    if (_isEditableTextFocused()) return .ignored;

    unawaited(_openSwitcher());

    return .handled;
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
      chatId: _requiredEntryId(entry),
    ).location,
    .agent => AgentDetailRoute(
      workspaceId: entry.workspaceId,
      agentId: _requiredEntryId(entry),
    ).location,
    .skill => SkillDetailRoute(
      workspaceId: entry.workspaceId,
      skillId: _requiredEntryId(entry),
    ).location,
    .settings => SettingsRoute(workspaceId: entry.workspaceId).location,
  };
}

String _requiredEntryId(QuickSwitcherEntry entry) {
  final id = entry.id;
  if (id == null) {
    throw StateError('Quick switcher route entry requires an ID.');
  }

  return id;
}
