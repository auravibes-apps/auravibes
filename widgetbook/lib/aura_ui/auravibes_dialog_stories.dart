// ignore_for_file: avoid-returning-widgets
// Required: Widgetbook stories use helper functions that return widgets.
// ignore_for_file: prefer-extracting-callbacks
// Required: Stories keep callbacks inline for readability.
// ignore_for_file: prefer-single-widget-per-file
// Required: Widgetbook stories group related story widgets.
// ignore_for_file: prefer-static-class
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
    colorVariant: context.knobs.objectOrNull.dropdown(
      label: 'colorVariant',
      options: AuraColorVariant.values,
      initialOption: null,
      labelBuilder: (value) => value.name,
    ),
  );
}

class _ConfirmDialogDemo extends StatelessWidget {
  const _ConfirmDialogDemo({
    required this.isDestructive,
    required this.colorVariant,
  });

  final bool isDestructive;
  final AuraColorVariant? colorVariant;

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
      colorVariant: colorVariant,
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
    colorVariant: context.knobs.objectOrNull.dropdown(
      label: 'colorVariant',
      options: [...AuraColorVariant.values],
      initialOption: null,
      labelBuilder: (value) => value.name,
    ),
  );
}

class _AlertDialogDemo extends StatelessWidget {
  const _AlertDialogDemo({required this.colorVariant});

  final AuraColorVariant? colorVariant;

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
                colorVariant: colorVariant,
              ),
            );
          },
          child: const Text('Show Alert Dialog'),
        ),
      ),
    );
  }
}
