// Required: Stories keep callbacks inline for readability.
import 'dart:async';

import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_alert_dialog.stories.bridge.g.dart';
part 'auravibes_alert_dialog.stories.g.dart';

const _component = ComponentMeta(name: 'AuraAlertDialog');
const _meta = Meta(AlertDialogDemo.new);

abstract final class _StorybookDefinitions {
  static final $AlertDialog = _Story(
    name: 'Alert Dialog',
    args: _Args(
      tint: NullableEnumArg(null, name: 'tint', values: AuraTint.values),
    ),
    scenarios: [
      _Scenario(
        name: 'Compact Phone',
        modes: [ViewportMode(StoryHelpers.compactPhoneViewport)],
      ),
      _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(.rtl)]),
      _Scenario(
        name: 'Opens Dialog',
        run: (tester, args) async {
          await tester.tap(find.text('Show Alert Dialog'));
          await tester.pump(const Duration(milliseconds: 300));
        },
      ),
    ],
  );
}

/// Demonstrates the alert dialog trigger and dismissible dialog content.
class const AlertDialogDemo({super.key, required final AuraTint? tint})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => unawaited(_showAlertDialog(context)),
      child: const Text('Show Alert Dialog'),
    );
  }

  Future<void> _showAlertDialog(BuildContext context) {
    return AuraDialogs.alert(
      context: context,
      title: const Text('Update Available'),
      message: const Text(
        'A new version of the app is available. Please update to the latest version.',
      ),
      tint: tint,
    );
  }
}
