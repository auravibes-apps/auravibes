// ignore_for_file: avoid-returning-widgets
// Required: Widgetbook stories use helper functions that return widgets.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default Typing Indicator', type: AuraTypingIndicator)
Widget defaultTypingIndicatorUseCase(BuildContext context) {
  return AuraTypingIndicator(
    size: context.knobs.object.dropdown(
      label: 'size',
      options: AuraTypingIndicatorSize.values,
      labelBuilder: (value) => value.name,
    ),
    color: context.knobs.color(label: 'color', initialValue: Colors.grey),
    showContainer: context.knobs.boolean(
      label: 'showContainer',
      initialValue: true,
    ),
    animationDuration: Duration(
      milliseconds: context.knobs.int.slider(
        label: 'animationDuration (ms)',
        initialValue: 600,
        min: 100,
        max: 2000,
      ),
    ),
  );
}
