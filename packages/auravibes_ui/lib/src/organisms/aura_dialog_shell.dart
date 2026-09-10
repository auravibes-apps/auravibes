import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// Shared visual shell for Aura dialogs.
class AuraDialogShell extends StatelessWidget {
  /// Creates a dialog shell.
  const new({
    required this.title,
    required this.message,
    required this.actions,
    super.key,
  });

  /// Dialog title.
  final Widget title;

  /// Dialog message.
  final Widget message;

  /// Dialog actions.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => _AuraDialogShellFrame(shell: this);
}

class const _AuraDialogShellFrame({required final AuraDialogShell shell})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Material(
      color: DesignColors.transparent,
      child: Container(
        decoration: _dialogShellDecoration(context),
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: _AuraDialogShellContent(shell: shell),
      ),
    ),
  );
}

class const _AuraDialogShellContent({required final AuraDialogShell shell})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      _AuraDialogShellTitle(title: shell.title),
      _AuraDialogShellMessage(message: shell.message),
      _AuraDialogShellActions(actions: shell.actions),
    ],
  );
}

class const _AuraDialogShellTitle({required final Widget title})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraDialogShellTitleContent(
    title: title,
    theme: context.auraTheme,
    colors: context.auraColors,
  );
}

class _AuraDialogShellTitleContent extends StatelessWidget {
  _AuraDialogShellTitleContent({
    required Widget title,
    required AuraTheme theme,
    required AuraColorScheme colors,
  }) : _child = Padding(
         padding: _dialogShellTitlePadding(theme),
         child: DefaultTextStyle(
           style: TextStyle(
             color: colors.onSurface,
             fontSize: theme.typography.fontSizeLg,
             fontWeight: theme.typography.fontWeightSemibold,
           ),
           child: title,
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraDialogShellMessage({required final Widget message})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.auraTheme;

    return Flexible(
      child: SingleChildScrollView(
        padding: _dialogShellMessagePadding(theme),
        child: DefaultTextStyle(
          style: _dialogShellMessageStyle(context),
          child: message,
        ),
      ),
    );
  }
}

class const _AuraDialogShellActions({required final List<Widget> actions})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
    child: Row(mainAxisAlignment: .end, children: actions),
  );
}

BoxDecoration _dialogShellDecoration(BuildContext context) => BoxDecoration(
  color: context.auraColors.surface,
  borderRadius: BorderRadius.all(
    .circular(context.auraTheme.fromBorderRadius(.lg)),
  ),
  boxShadow: const [DesignShadows.lg],
);

EdgeInsets _dialogShellTitlePadding(AuraTheme theme) {
  final spacing = theme.fromSpacing(.md);

  return EdgeInsets.only(
    left: spacing,
    top: theme.fromSpacing(.lg),
    right: spacing,
  );
}

EdgeInsets _dialogShellMessagePadding(AuraTheme theme) => EdgeInsets.symmetric(
  vertical: theme.fromSpacing(.sm),
  horizontal: theme.fromSpacing(.md),
);

TextStyle _dialogShellMessageStyle(BuildContext context) {
  final theme = context.auraTheme;

  return TextStyle(
    color: context.auraColors.onSurfaceVariant,
    fontSize: theme.typography.fontSizeBase,
    fontWeight: theme.typography.fontWeightRegular,
    height: theme.typography.lineHeightBase,
  );
}
