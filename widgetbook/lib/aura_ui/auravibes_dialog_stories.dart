// Required: Stories keep callbacks inline for readability.
// Required: Widgetbook stories group related story widgets.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Confirm Dialog', type: AuraConfirmDialog)
Widget confirmDialogUseCase(BuildContext context) {
  return _ConfirmDialogDemo(
    isDestructive: context.knobs.boolean(
      label: 'isDestructive',
      initialValue: false,
    ),
    tint: context.knobs.objectOrNull.dropdown(
      label: 'tint',
      options: AuraTint.values,
      initialOption: null,
      labelBuilder: (value) => value.name,
    ),
  );
}

class _ConfirmDialogDemo extends StatelessWidget {
  const _ConfirmDialogDemo({
    required this.isDestructive,
    required this.tint,
  });

  final bool isDestructive;
  final AuraTint? tint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            unawaited(_showConfirmDialog(context));
          },
          child: const Text('Show Confirm Dialog'),
        ),
      ),
    );
  }

  Future<void> _showConfirmDialog(BuildContext context) async {
    final result = await showAuraConfirmDialog(
      context: context,
      title: const Text('Delete Item'),
      message: const Text(
        'Are you sure you want to delete this item? This action cannot be undone.',
      ),
      isDestructive: isDestructive,
      tint: tint,
    );
    if (!context.mounted) return;

    final _ = ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Result: $result')));
  }
}

@widgetbook.UseCase(name: 'Alert Dialog', type: AuraAlertDialog)
Widget alertDialogUseCase(BuildContext context) {
  return _AlertDialogDemo(
    tint: context.knobs.objectOrNull.dropdown(
      label: 'tint',
      options: [...AuraTint.values],
      initialOption: null,
      labelBuilder: (value) => value.name,
    ),
  );
}

class _AlertDialogDemo extends StatelessWidget {
  const _AlertDialogDemo({required this.tint});

  final AuraTint? tint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            unawaited(
              showAuraAlertDialog(
                context: context,
                title: const Text('Update Available'),
                message: const Text(
                  'A new version of the app is available. Please update to the latest version.',
                ),
                tint: tint,
              ),
            );
          },
          child: const Text('Show Alert Dialog'),
        ),
      ),
    );
  }
}
