// ignore_for_file: avoid-returning-widgets
// Required: Widgetbook stories use helper functions that return widgets.
// ignore_for_file: no-empty-block
// Required: Widgetbook stories use intentional no-op callbacks.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Primary Button', type: AuraButton)
Widget primaryButtonUseCase(BuildContext context) {
  return AuraButton(
    onPressed: () {},
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
