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
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final auraTheme = context.auraTheme;
    final mediumSpacing = auraTheme.fromSpacing(.md);

    return Center(
      child: Material(
        color: DesignColors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: auraColors.surface,
            borderRadius: BorderRadius.all(
              Radius.circular(auraTheme.fromBorderRadius(.lg)),
            ),
            boxShadow: const [DesignShadows.lg],
          ),
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: mediumSpacing,
                  top: auraTheme.fromSpacing(.lg),
                  right: mediumSpacing,
                ),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: auraColors.onSurface,
                    fontSize: auraTheme.typography.fontSizeLg,
                    fontWeight: auraTheme.typography.fontWeightSemibold,
                  ),
                  child: title,
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    vertical: auraTheme.fromSpacing(.sm),
                    horizontal: mediumSpacing,
                  ),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: auraColors.onSurfaceVariant,
                      fontSize: auraTheme.typography.fontSizeBase,
                      fontWeight: auraTheme.typography.fontWeightRegular,
                      height: auraTheme.typography.lineHeightBase,
                    ),
                    child: message,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(mediumSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
