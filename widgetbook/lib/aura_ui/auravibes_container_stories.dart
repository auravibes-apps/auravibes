import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_workspace/knobs/padding.dart';

@widgetbook.UseCase(name: 'Basic Container', type: AuraContainer)
Widget basicContainerUseCase(BuildContext context) {
  return AuraContainer(
    backgroundColor: AuraColorVariant.surfaceVariant,
    padding: context.knobs.padding(),
    margin: context.knobs.padding(label: 'margin'),
    borderRadius: 8.0,
    shadow: context.knobs.object.dropdown(
      label: 'shadow',
      options: AuraContainerShadow.values,
      labelBuilder: (value) => value.name,
    ),
    child: const AuraText(
      style: AuraTextStyle.body,
      child: Text('Basic Container'),
    ),
  );
}
