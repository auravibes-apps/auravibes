// ignore_for_file: avoid-returning-widgets
// Required: Widgetbook stories use helper functions that return widgets.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_workspace/knobs/icons.dart';

@widgetbook.UseCase(name: 'Regular FAB', type: AuraFloatingActionButton)
Widget regularFABUseCase(BuildContext context) {
  return AuraFloatingActionButton(
    onPressed: () {},
    icon: context.knobs.iconData(label: 'Icon', initialValue: Icons.add),
    size: context.knobs.object.dropdown(
      label: 'size',
      options: AuraFABSize.values,
      labelBuilder: (value) => value.name,
    ),
    tooltip: context.knobs.stringOrNull(
      label: 'Tooltip',
      initialValue: 'Tooltip',
    ),
  );
}

@widgetbook.UseCase(name: 'Extended FAB', type: AuraFloatingActionButton)
Widget extendedFABUseCase(BuildContext context) {
  return AuraFloatingActionButton.extended(
    onPressed: () {},
    icon: context.knobs.iconData(label: 'Icon', initialValue: Icons.add),
    text: context.knobs.string(label: 'Text', initialValue: 'Create New'),
    tooltip: context.knobs.stringOrNull(
      label: 'Tooltip',
      initialValue: 'Tooltip',
    ),
  );
}
