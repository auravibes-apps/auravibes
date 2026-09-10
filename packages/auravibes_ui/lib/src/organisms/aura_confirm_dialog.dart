// Required: Component callbacks stay colocated with UI state.
// Required: UI components keep related private widgets together.
// Required: UI package exposes top-level helpers and constants.
import 'package:auravibes_ui/src/molecules/aura_button.dart';
import 'package:auravibes_ui/src/organisms/aura_alert_dialog.dart';
import 'package:auravibes_ui/src/organisms/aura_dialog_shell.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

export 'aura_alert_dialog.dart';

/// A custom confirmation dialog with customizable title, message, and actions.
///
/// Provides both a widget for composition and helper function
/// for displaying dialogs imperatively using showGeneralDialog.
class AuraConfirmDialog extends StatelessWidget {
  /// Creates a confirmation dialog.
  const new({
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
    return AuraDialogShell(
      title: title,
      message: message,
      actions: [
        _AuraConfirmCancelButton(label: cancelLabel, onCancel: onCancel),
        const SizedBox(width: 8),
        _AuraConfirmButton(
          label: confirmLabel,
          onConfirm: onConfirm,
          isDestructive: isDestructive,
          tint: tint,
        ),
      ],
    );
  }
}

class const _AuraConfirmCancelButton({
  required final Widget label,
  required final VoidCallback? onCancel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraButton(
      onPressed: _onPressed(context),
      child: label,
      variant: .text,
    );
  }

  VoidCallback _onPressed(BuildContext context) => () {
    Navigator.of(context).pop(false);
    onCancel?.call();
  };
}

class const _AuraConfirmButton({
  required final Widget label,
  required final VoidCallback? onConfirm,
  required final bool isDestructive,
  required final AuraTint? tint,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraButton(
      onPressed: _onPressed(context),
      child: label,
      variant: .text,
      tint: isDestructive ? AuraTint.error : tint ?? AuraTint.primary,
    );
  }

  VoidCallback _onPressed(BuildContext context) => () {
    Navigator.of(context).pop(true);
    onConfirm?.call();
  };
}

/// Labels used by [AuraDialogs.confirm].
class AuraConfirmDialogActions {
  /// Creates labels for confirmation dialog actions.
  const new({this.confirmLabel, this.cancelLabel});

  /// Label for the confirm action.
  final Widget? confirmLabel;

  /// Label for the cancel action.
  final Widget? cancelLabel;

  /// Whether either action label was provided explicitly.
  bool hasCustomLabels() => confirmLabel != null || cancelLabel != null;
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
    return _showAuraDialog<bool>(
      context: context,
      child: AuraConfirmDialog(
        title: title,
        message: message,
        confirmLabel: actions.confirmLabel ?? const Text('Confirm'),
        cancelLabel: actions.cancelLabel ?? const Text('Cancel'),
        isDestructive: isDestructive,
        tint: tint,
      ),
      barrierDismissible: barrierDismissible,
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
    await _showAuraDialog<void>(
      context: context,
      child: AuraAlertDialog(
        title: title,
        message: message,
        dismissLabel: dismissLabel ?? const Text('OK'),
        tint: tint,
      ),
      barrierDismissible: barrierDismissible,
    );
  }
}

Future<T?> _showAuraDialog<T>({
  required BuildContext context,
  required Widget child,
  required bool barrierDismissible,
}) {
  final pageBuilder = _auraDialogPageBuilder(child);

  return showGeneralDialog<T>(
    context: context,
    pageBuilder: pageBuilder,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: context.auraColors.scrim,
    transitionBuilder: (_, animation, _, child) =>
        _AuraDialogTransition(animation: animation, child: child),
  );
}

typedef _AuraDialogPageBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
);

_AuraDialogPageBuilder _auraDialogPageBuilder(Widget child) =>
    (_, _, _) => child;

class const _AuraDialogTransition({
  required final Animation<double> animation,
  required final Widget child,
}) extends StatelessWidget {
  static const _transitionScale = 0.95;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: _transitionScale,
          end: 1,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }
}
