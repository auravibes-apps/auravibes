// ignore_for_file: no-magic-number
// Required: Widgetbook stories use fixed example sizes.
// ignore_for_file: avoid-returning-widgets
// Required: Widgetbook stories use helper functions that return widgets.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_workspace/knobs/padding.dart';

@widgetbook.UseCase(name: 'Basic Container', type: AuraContainer)
Widget basicContainerUseCase(BuildContext context) {
  return AuraContainer(
    child: const AuraText(
      child: Text('Basic Container'),
      style: AuraTextStyle.body,
    ),
    padding: context.knobs.padding(),
    margin: context.knobs.padding(label: 'margin'),
    backgroundColor: AuraColorVariant.surfaceVariant,
    borderRadius: 8,
    shadow: context.knobs.object.dropdown(
      label: 'shadow',
      options: AuraContainerShadow.values,
      labelBuilder: (value) => value.name,
    ),
  );
}
