// Required: Stories keep callbacks inline for readability.
import 'dart:async';

import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_confirm_dialog.stories.g.dart';

const component = ComponentMeta(name: 'AuraConfirmDialog');
const meta = Meta(ConfirmDialogDemo.new);

final $ConfirmDialog = _Story(
  name: 'Confirm Dialog',
  args: _Args(
    isDestructive: BoolArg(false, name: 'isDestructive'),
    tint: NullableEnumArg(null, name: 'tint', values: AuraTint.values),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(
      name: 'Opens Dialog',
      run: (tester, args) async {
        await tester.tap(find.text('Show Confirm Dialog'));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates a confirmation dialog with destructive and tinted states.
class ConfirmDialogDemo extends StatelessWidget {
  const ConfirmDialogDemo({
    super.key,
    required this.isDestructive,
    required this.tint,
  });

  final bool isDestructive;
  final AuraTint? tint;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => unawaited(_showConfirmDialog(context)),
      child: const Text('Show Confirm Dialog'),
    );
  }

  Future<void> _showConfirmDialog(BuildContext context) async {
    final result = await AuraDialogs.confirm(
      context: context,
      title: const Text('Delete Item'),
      message: const Text(
        'Are you sure you want to delete this item? This action cannot be undone.',
      ),
      isDestructive: isDestructive,
      tint: tint,
    );
    if (!context.mounted) return;

    final _ = AuraSnackBars.show(
      context: context,
      content: Text('Result: $result'),
    );
  }
}
