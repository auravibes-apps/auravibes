// Required: Widgetbook stories use intentional no-op callbacks.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

part 'auravibes_snackbar.stories.g.dart';

const component = ComponentMeta(name: 'Snackbar Variants');

class const _SnackBarInput({
  required final AuraSnackBarVariant variant,
  required final bool showAction,
  required final int durationSeconds,
});

const meta = Meta(SnackBarDemo.new, argsType: _SnackBarInput.new);

final _Defaults snackbarDefaults = _Defaults(
  builder: (context, args) => SnackBarDemo(
    variant: args.variant,
    showAction: args.showAction,
    duration: Duration(seconds: args.durationSeconds),
  ),
);

final $SnackbarVariants = _Story(
  name: 'Snackbar Variants',
  setup: (context, child, args) =>
      SizedBox(width: 420, height: 300, child: Scaffold(body: child)),
  args: _Args(
    variant: EnumArg(
      AuraSnackBarVariant.default_,
      name: 'variant',
      values: AuraSnackBarVariant.values,
    ),
    showAction: BoolArg(true, name: 'showAction'),
    durationSeconds: IntArg(
      4,
      name: 'duration (seconds)',
      style: const SliderIntArgStyle(min: 1, max: 10, divisions: 9),
    ),
  ),
  scenarios: [
    _Scenario(
      name: 'Shows Snackbar',
      run: (tester, args) async {
        await tester.tap(find.text('Show SnackBar'));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates snackbar variants, actions, and display duration.
class const SnackBarDemo({
  super.key,
  required final AuraSnackBarVariant variant,
  required final bool showAction,
  required final Duration duration,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showSnackBar(context),
      child: const Text('Show SnackBar'),
    );
  }

  String _getMessage() {
    return switch (variant) {
      AuraSnackBarVariant.default_ => 'This is a default snackbar message.',
      AuraSnackBarVariant.success => 'Operation completed successfully!',
      AuraSnackBarVariant.error => 'An error occurred. Please try again.',
      AuraSnackBarVariant.warning => 'Warning: This action cannot be undone.',
      AuraSnackBarVariant.info => 'New updates are available.',
    };
  }

  void _showSnackBar(BuildContext context) {
    final _ = AuraSnackBars.show(
      context: context,
      content: Text(_getMessage()),
      variant: variant,
      duration: duration,
      actionLabel: showAction ? 'UNDO' : null,
      onAction: showAction ? _handleUndo : null,
    );
  }

  void _handleUndo() {
    final _ = Object();
  }
}
