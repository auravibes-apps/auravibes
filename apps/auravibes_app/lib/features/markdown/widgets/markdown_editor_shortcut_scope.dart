import 'package:auravibes_app/features/markdown/widgets/markdown_editor_toolbar.dart';
import 'package:material_ui/material_ui.dart';

/// Provides the Markdown editor's existing keyboard shortcuts to its surface.
class const MarkdownEditorShortcutScope({
  required final MarkdownEditorShortcutController controller,
  required final FocusNode focusNode,
  required final bool enabled,
  required final Widget child,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Actions(
    actions: {
      _MarkdownToolbarIntent: _MarkdownToolbarCallbackAction(
        isEditorFocused: () => enabled && focusNode.hasPrimaryFocus,
        onInvoke: (intent) {
          controller.invoke(intent.action, context);

          return null;
        },
      ),
    },
    child: Shortcuts(
      shortcuts: _MarkdownToolbarShortcutBindings.forPlatform(
        Theme.of(context).platform,
      ),
      child: child,
    ),
  );
}

class const _MarkdownToolbarIntent(final MarkdownEditorShortcutAction action)
    extends Intent;

class _MarkdownToolbarCallbackAction({
  required final bool Function() isEditorFocused,
  required super.onInvoke,
}) extends CallbackAction<_MarkdownToolbarIntent> {
  @override
  bool isEnabled(_MarkdownToolbarIntent intent) => isEditorFocused();
}

abstract final class _MarkdownToolbarShortcutBindings {
  static const _macShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(.keyB, meta: true, includeRepeats: false):
        _MarkdownToolbarIntent(.bold),
    SingleActivator(.keyI, meta: true, includeRepeats: false):
        _MarkdownToolbarIntent(.italic),
    SingleActivator(.keyE, meta: true, includeRepeats: false):
        _MarkdownToolbarIntent(.code),
    SingleActivator(.keyK, meta: true, includeRepeats: false):
        _MarkdownToolbarIntent(.link),
  };

  static const _controlShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(.keyB, control: true, includeRepeats: false):
        _MarkdownToolbarIntent(.bold),
    SingleActivator(.keyI, control: true, includeRepeats: false):
        _MarkdownToolbarIntent(.italic),
    SingleActivator(.keyE, control: true, includeRepeats: false):
        _MarkdownToolbarIntent(.code),
    SingleActivator(.keyK, control: true, includeRepeats: false):
        _MarkdownToolbarIntent(.link),
  };

  static Map<ShortcutActivator, Intent> forPlatform(TargetPlatform platform) =>
      platform == TargetPlatform.macOS ? _macShortcuts : _controlShortcuts;
}
