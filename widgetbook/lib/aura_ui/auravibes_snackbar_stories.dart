import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Snackbar Variants', type: SnackBar)
Widget snackbarVariantsUseCase(BuildContext context) {
  return _SnackBarDemo(
    variant: context.knobs.object.dropdown(
      label: 'variant',
      options: AuraSnackBarVariant.values,
      initialOption: AuraSnackBarVariant.default_,
      labelBuilder: (value) => value.name,
    ),
    showAction: context.knobs.boolean(label: 'showAction', initialValue: true),
    duration: Duration(
      seconds: context.knobs.int.slider(
        label: 'duration (seconds)',
        initialValue: 4,
        min: 1,
        max: 10,
      ),
    ),
  );
}

class _SnackBarDemo extends StatelessWidget {
  const _SnackBarDemo({
    required this.variant,
    required this.showAction,
    required this.duration,
  });

  final AuraSnackBarVariant variant;
  final bool showAction;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showAuraSnackBar(
              context: context,
              content: Text(_getMessage()),
              variant: variant,
              duration: duration,
              actionLabel: showAction ? 'UNDO' : null,
              onAction: showAction ? () {} : null,
            );
          },
          child: const Text('Show SnackBar'),
        ),
      ),
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
}
