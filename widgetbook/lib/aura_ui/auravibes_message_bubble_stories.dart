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

@widgetbook.UseCase(name: 'Aura Message Bubble', type: AuraMessageBubble)
Widget userTextMessageUseCase(BuildContext context) {
  return AuraMessageBubble(
    content: context.knobs.string(
      label: 'Content',
      initialValue: 'Hello! How can you help me with my Flutter project today?',
    ),
    isUser: context.knobs.boolean(label: 'Is User', initialValue: true),
    status: context.knobs.object.dropdown(
      label: 'Status',
      options: AuraMessageDeliveryStatus.values,
      labelBuilder: (value) => value.name,
    ),
    timestamp: context.knobs.dateTimeOrNull(
      label: 'Show Timestamp',
      initialValue: DateTime.now().subtract(const Duration(minutes: 2)),
      start: DateTime(2023, 1, 1),
      end: DateTime.now(),
    ),
    contentType: context.knobs.object.dropdown(
      label: 'Content Type',
      options: AuraMessageContentType.values,
      labelBuilder: (value) => value.name,
    ),
  );
}
