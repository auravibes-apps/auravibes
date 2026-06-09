// Required: Widgetbook stories use intentional no-op callbacks.
// Required: Existing code repeats lookups where extraction adds noise.
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Primary Button', type: AuraButton)
Widget primaryButtonUseCase(BuildContext context) {
  return AuraButton(
    onPressed: () {
      final _ = Object();
    },
    child: Text(
      context.knobs.string(
        label: 'button content',
        initialValue: 'Primary Button',
      ),
    ),
    variant: context.knobs.object.dropdown(
      label: 'variant',
      options: AuraButtonVariant.values,
      initialOption: AuraButtonVariant.primary,
      labelBuilder: (value) => value.name,
    ),
    size: context.knobs.object.dropdown(
      label: 'size',
      options: AuraButtonSize.values,
      initialOption: AuraButtonSize.medium,
      labelBuilder: (value) => value.name,
    ),
    isLoading: context.knobs.boolean(label: 'isLoading', initialValue: false),
    isFullWidth: context.knobs.boolean(
      label: 'isFullWidth',
      initialValue: false,
    ),
    disabled: context.knobs.boolean(label: 'disabled', initialValue: false),
  );
}
