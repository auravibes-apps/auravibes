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

typedef _AuraDialogRequest = ({
  BuildContext context,
  Widget child,
  bool barrierDismissible,
});

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
  Widget build(BuildContext context) =>
      _AuraConfirmDialogData(dialog: this).child;
}

class _AuraConfirmDialogData {
  new({required AuraConfirmDialog dialog})
    : child = AuraDialogShell(
        title: dialog.title,
        message: dialog.message,
        actions: [
          _AuraConfirmCancelButton(
            label: dialog.cancelLabel,
            onCancel: dialog.onCancel,
          ),
          const SizedBox(width: 8),
          _AuraConfirmButton(
            label: dialog.confirmLabel,
            onConfirm: dialog.onConfirm,
            isDestructive: dialog.isDestructive,
            tint: dialog.tint,
          ),
        ],
      );

  final Widget child;
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
  const new _();

  /// Shows a confirmation dialog and returns the user's selection.
  // Public named arguments preserve the existing confirmation API.
  // ignore: number-of-parameters
  static Future<bool?> confirm({
    required BuildContext context,
    required Widget title,
    required Widget message,
    AuraConfirmDialogActions actions = const AuraConfirmDialogActions(),
    bool isDestructive = false,
    bool barrierDismissible = true,
    AuraTint? tint,
  }) => _showConfirmationDialog(
    .new(
      context: context,
      title: title,
      message: message,
      actions: actions,
      isDestructive: isDestructive,
      barrierDismissible: barrierDismissible,
      tint: tint,
    ),
  );

  /// Shows an alert dialog and dismisses on button tap.
  // Public named arguments preserve the existing alert API.
  // ignore: number-of-parameters
  static Future<void> alert({
    required BuildContext context,
    required Widget title,
    required Widget message,
    Widget? dismissLabel,
    AuraTint? tint,
    bool barrierDismissible = true,
  }) => _showAlertDialog(
    .new(
      context: context,
      title: title,
      message: message,
      dismissLabel: dismissLabel,
      tint: tint,
      barrierDismissible: barrierDismissible,
    ),
  );

  @override
  String toString() => 'AuraDialogs';
}

class _AuraConfirmationRequest {
  const new({
    required this.context,
    required this.title,
    required this.message,
    required this.actions,
    required this.isDestructive,
    required this.barrierDismissible,
    this.tint,
  });

  final BuildContext context;
  final Widget title;
  final Widget message;
  final AuraConfirmDialogActions actions;
  final bool isDestructive;
  final bool barrierDismissible;
  final AuraTint? tint;
}

Future<bool?> _showConfirmationDialog(_AuraConfirmationRequest request) =>
    _showAuraDialog<bool>(_AuraConfirmationDialogData(request).value);

class _AuraConfirmationDialogData {
  new(_AuraConfirmationRequest request)
    : value = (
        context: request.context,
        child: AuraConfirmDialog(
          title: request.title,
          message: request.message,
          confirmLabel: request.actions.confirmLabel ?? const Text('Confirm'),
          cancelLabel: request.actions.cancelLabel ?? const Text('Cancel'),
          isDestructive: request.isDestructive,
          tint: request.tint,
        ),
        barrierDismissible: request.barrierDismissible,
      );

  final _AuraDialogRequest value;
}

class _AuraAlertRequest {
  const new({
    required this.context,
    required this.title,
    required this.message,
    required this.dismissLabel,
    required this.tint,
    required this.barrierDismissible,
  });

  final BuildContext context;
  final Widget title;
  final Widget message;
  final Widget? dismissLabel;
  final AuraTint? tint;
  final bool barrierDismissible;
}

Future<void> _showAlertDialog(_AuraAlertRequest request) =>
    _showAuraDialog<void>((
      context: request.context,
      child: AuraAlertDialog(
        title: request.title,
        message: request.message,
        dismissLabel: request.dismissLabel ?? const Text('OK'),
        tint: request.tint,
      ),
      barrierDismissible: request.barrierDismissible,
    ));

Future<T?> _showAuraDialog<T>(_AuraDialogRequest request) =>
    _showGeneralDialog(request);

Future<T?> _showGeneralDialog<T>(_AuraDialogRequest request) =>
    _AuraGeneralDialogData<T>(request).future;

class _AuraGeneralDialogData<T> {
  new(_AuraDialogRequest request)
    : future = showGeneralDialog<T>(
        context: request.context,
        pageBuilder: _auraDialogPageBuilder(request.child),
        barrierDismissible: request.barrierDismissible,
        barrierLabel: MaterialLocalizations.of(request.context)
            .modalBarrierDismissLabel,
        barrierColor: request.context.auraColors.scrim,
        transitionBuilder: (_, animation, _, child) =>
            _AuraDialogTransition(animation: animation, child: child),
      );

  final Future<T?> future;
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
