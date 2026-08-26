import 'package:auravibes_ui/src/molecules/aura_button.dart';
import 'package:auravibes_ui/src/organisms/aura_dialog_shell.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart' show AuraTint;
import 'package:flutter/material.dart';

/// A custom alert dialog with a single dismiss action.
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

  /// Label for the dismiss button.
  final Widget dismissLabel;

  /// The accent color for the dialog.
  final AuraTint? tint;

  @override
  Widget build(BuildContext context) {
    return AuraDialogShell(
      title: title,
      message: message,
      actions: [
        AuraButton(
          onPressed: Navigator.of(context).pop,
          child: dismissLabel,
          variant: AuraButtonVariant.text,
          tint: tint,
        ),
      ],
    );
  }
}
