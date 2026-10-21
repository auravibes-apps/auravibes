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
    final selected = await _showQuickSwitcherDialog(
      context,
      widget.workspaceId,
    );
    if (!mounted || selected == null) return;

    _switchToSelection(ref, selected);
  }
}

Future<QuickSwitcherEntry?> _showQuickSwitcherDialog(
  BuildContext context,
  String workspaceId,
) => showDialog<QuickSwitcherEntry>(
  context: context,
  builder: (_) => QuickSwitcherDialog(workspaceId: workspaceId),
);

void _switchToSelection(WidgetRef ref, QuickSwitcherEntry entry) => ref
    .read(workspaceSwitcherProvider.notifier)
    .switchToWorkspace(
      entry.workspaceId,
      destinationLocation: _destinationFor(entry),
    );

String _destinationFor(QuickSwitcherEntry entry) => switch (entry.type) {
  .workspace || .newConversation => _newChatLocation(entry.workspaceId),
  .conversation => _conversationLocation(entry),
  .agent => _agentLocation(entry),
  .skill => _skillLocation(entry),
  .settings => _settingsLocation(entry.workspaceId),
};

String _newChatLocation(String workspaceId) =>
    NewChatRoute(workspaceId: workspaceId).location;

String _conversationLocation(QuickSwitcherEntry entry) => ConversationRoute(
  workspaceId: entry.workspaceId,
  chatId: _requiredEntryId(entry),
).location;

String _agentLocation(QuickSwitcherEntry entry) => AgentDetailRoute(
  workspaceId: entry.workspaceId,
  agentId: _requiredEntryId(entry),
).location;

String _skillLocation(QuickSwitcherEntry entry) => SkillDetailRoute(
  workspaceId: entry.workspaceId,
  skillId: _requiredEntryId(entry),
).location;

String _settingsLocation(String workspaceId) =>
    SettingsRoute(workspaceId: workspaceId).location;

String _requiredEntryId(QuickSwitcherEntry entry) {
  final id = entry.id;
  if (id == null) {
    throw StateError('Quick switcher route entry requires an ID.');
  }

  return id;
}
