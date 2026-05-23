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
    this.colorVariant,
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
  final AuraColorVariant? colorVariant;

  @override
  Widget build(BuildContext context) {
    return _AuraDialogShell(
      title: title,
      message: message,
      actions: [
        AuraButton(
          variant: AuraButtonVariant.text,
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: cancelLabel,
        ),
        const SizedBox(width: 8),
        AuraButton(
          variant: AuraButtonVariant.text,
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          colorVariant: isDestructive
              ? AuraColorVariant.error
              : colorVariant ?? AuraColorVariant.primary,
          child: confirmLabel,
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
    this.colorVariant,
  });

  /// The dialog title widget.
  final Widget title;

  /// The dialog message/content widget.
  final Widget message;

  /// Label for the dismiss button. Defaults to "OK".
  final Widget dismissLabel;

  /// The accent color for the dialog.
  final AuraColorVariant? colorVariant;

  @override
  Widget build(BuildContext context) {
    return _AuraDialogShell(
      title: title,
      message: message,
      actions: [
        AuraButton(
          variant: AuraButtonVariant.text,
          onPressed: () {
            Navigator.of(context).pop();
          },
          colorVariant: colorVariant,
          child: dismissLabel,
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

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: auraColors.surface,
            borderRadius: BorderRadius.circular(auraTheme.borderRadius.lg),
            boxShadow: const [DesignShadows.lg],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Padding(
                padding: EdgeInsets.only(
                  left: auraTheme.spacing.md,
                  right: auraTheme.spacing.md,
                  top: auraTheme.spacing.lg,
                ),
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: auraTheme.typography.sizes.lg,
                    fontWeight: auraTheme.typography.weights.semibold,
                    color: auraColors.onSurface,
                  ),
                  child: title,
                ),
              ),
              // Message (scrollable if too long)
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: auraTheme.spacing.md,
                    vertical: auraTheme.spacing.sm,
                  ),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: auraTheme.typography.sizes.base,
                      fontWeight: auraTheme.typography.weights.regular,
                      color: auraColors.onSurfaceVariant,
                      height: auraTheme.typography.lineHeights.base,
                    ),
                    child: message,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(auraTheme.spacing.md),
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

/// Shows a confirmation dialog and returns user selection.
///
/// Returns `true` if confirmed, `false` if cancelled,
/// `null` if dismissed (e.g., by tapping outside).
Future<bool?> showAuraConfirmDialog({
  required BuildContext context,
  required Widget title,
  required Widget message,
  AuraConfirmDialogActions actions = const AuraConfirmDialogActions(),
  bool isDestructive = false,
  bool barrierDismissible = true,
  AuraColorVariant? colorVariant,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    pageBuilder: (context, animation, secondaryAnimation) {
      return AuraConfirmDialog(
        title: title,
        message: message,
        confirmLabel: actions.confirmLabel ?? const Text('Confirm'),
        cancelLabel: actions.cancelLabel ?? const Text('Cancel'),
        isDestructive: isDestructive,
        colorVariant: colorVariant,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.95,
            end: 1,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
  );
}

/// Labels used by [showAuraConfirmDialog].
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

/// Shows an alert dialog and dismisses on button tap.
///
/// Returns a Future that can be awaited.
Future<void> showAuraAlertDialog({
  required BuildContext context,
  required Widget title,
  required Widget message,
  Widget? dismissLabel,
  AuraColorVariant? colorVariant,
  bool barrierDismissible = true,
}) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    pageBuilder: (context, animation, secondaryAnimation) {
      return AuraAlertDialog(
        title: title,
        message: message,
        dismissLabel: dismissLabel ?? const Text('OK'),
        colorVariant: colorVariant,
      );
    },
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
