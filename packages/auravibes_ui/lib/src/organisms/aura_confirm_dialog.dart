// Required: Component callbacks stay colocated with UI state.
// Required: UI components keep related private widgets together.
// Required: UI package exposes top-level helpers and constants.
import 'package:auravibes_ui/src/molecules/aura_button.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A custom confirmation dialog with customizable title, message, and actions.
///
/// Provides both a widget for composition and helper function
/// for displaying dialogs imperatively using showGeneralDialog.
class AuraConfirmDialog extends StatelessWidget {
  /// Creates a confirmation dialog.
  const AuraConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    super.key,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.tint,
  });

  /// The dialog title widget.
  final Widget title;

  /// The dialog message/content widget.
  final Widget message;

  /// Label for the confirm button. Defaults to localized "Confirm".
  final Widget confirmLabel;

  /// Label for the cancel button. Defaults to localized "Cancel".
  final Widget cancelLabel;

  /// Called when the confirm button is pressed.
  final VoidCallback? onConfirm;

  /// Called when the cancel button is pressed.
  final VoidCallback? onCancel;

  /// If true, confirm button uses error styling (red).
  final bool isDestructive;

  /// The accent color for the dialog.
  final AuraTint? tint;

  @override
  Widget build(BuildContext context) {
    return _AuraDialogShell(
      title: title,
      message: message,
      actions: [
        AuraButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: cancelLabel,
          variant: AuraButtonVariant.text,
        ),
        const SizedBox(width: 8),
        AuraButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          child: confirmLabel,
          variant: AuraButtonVariant.text,
          tint: isDestructive ? AuraTint.error : tint ?? AuraTint.primary,
        ),
      ],
    );
  }
}

/// A custom alert dialog with a single dismiss action.
///
/// Provides a simple alert dialog with customizable title,
/// message and optional dismiss action.
class AuraAlertDialog extends StatelessWidget {
  /// Creates an alert dialog.
  const AuraAlertDialog({
    required this.title,
    required this.message,
    required this.dismissLabel,
    super.key,
    this.tint,
  });

  /// The dialog title widget.
  final Widget title;

  /// The dialog message/content widget.
  final Widget message;

  /// Label for the dismiss button. Defaults to "OK".
  final Widget dismissLabel;

  /// The accent color for the dialog.
  final AuraTint? tint;

  @override
  Widget build(BuildContext context) {
    return _AuraDialogShell(
      title: title,
      message: message,
      actions: [
        AuraButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: dismissLabel,
          variant: AuraButtonVariant.text,
          tint: tint,
        ),
      ],
    );
  }
}

class _AuraDialogShell extends StatelessWidget {
  const _AuraDialogShell({
    required this.title,
    required this.message,
    required this.actions,
  });

  final Widget title;
  final Widget message;
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
              Radius.circular(
                auraTheme.fromBorderRadius(.lg),
              ),
            ),
            boxShadow: const [DesignShadows.lg],
          ),
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title.
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
              // Message (scrollable if too long).
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
                padding: EdgeInsets.all(
                  mediumSpacing,
                ),
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

/// Labels used by [AuraDialogs.confirm].
class AuraConfirmDialogActions {
  /// Creates labels for confirmation dialog actions.
  const AuraConfirmDialogActions({
    this.confirmLabel,
    this.cancelLabel,
  });

  /// Label for the confirm action.
  final Widget? confirmLabel;

  /// Label for the cancel action.
  final Widget? cancelLabel;
}

/// Shows a confirmation dialog and returns user selection.
///
/// Returns `true` if confirmed, `false` if cancelled,
/// `null` if dismissed (e.g., by tapping outside).
abstract final class AuraDialogs {
  /// Shows a confirmation dialog and returns the user's selection.
  static Future<bool?> confirm({
    required BuildContext context,
    required Widget title,
    required Widget message,
    AuraConfirmDialogActions actions = const AuraConfirmDialogActions(),
    bool isDestructive = false,
    bool barrierDismissible = true,
    AuraTint? tint,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AuraConfirmDialog(
          title: title,
          message: message,
          confirmLabel: actions.confirmLabel ?? const Text('Confirm'),
          cancelLabel: actions.cancelLabel ?? const Text('Cancel'),
          isDestructive: isDestructive,
          tint: tint,
        );
      },
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: context.auraColors.scrim,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale:
                Tween<double>(
                  begin: 0.95,
                  end: 1,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          ),
        );
      },
    );
  }

  /// Shows an alert dialog and dismisses on button tap.
  static Future<void> alert({
    required BuildContext context,
    required Widget title,
    required Widget message,
    Widget? dismissLabel,
    AuraTint? tint,
    bool barrierDismissible = true,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AuraAlertDialog(
          title: title,
          message: message,
          dismissLabel: dismissLabel ?? const Text('OK'),
          tint: tint,
        );
      },
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: context.auraColors.scrim,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
