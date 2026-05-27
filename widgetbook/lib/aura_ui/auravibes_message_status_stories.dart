// ignore_for_file: avoid-returning-widgets
// Required: Widgetbook stories use helper functions that return widgets.
// ignore_for_file: prefer-moving-to-variable
// Required: Existing code repeats lookups where extraction adds noise.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Sending Status', type: AuraMessageStatus)
Widget sendingStatusUseCase(BuildContext context) {
  return AuraMessageStatus(
    status: context.knobs.object.dropdown(
      label: 'Status',
      options: AuraMessageDeliveryStatus.values,
      labelBuilder: (value) => value.name,
    ),
    size: context.knobs.object.dropdown(
      label: 'Size',
      options: AuraMessageStatusSize.values,
      labelBuilder: (value) => value.name,
    ),
    showAnimation: context.knobs.boolean(
      label: 'Show Animation',
      initialValue: true,
    ),
  );
}
