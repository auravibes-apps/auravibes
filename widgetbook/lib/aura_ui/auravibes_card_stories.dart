// ignore_for_file: avoid-returning-widgets
// Required: Widgetbook stories use helper functions that return widgets.

// Required: Widgetbook stories use intentional no-op callbacks.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_workspace/knobs/padding.dart';

@widgetbook.UseCase(name: 'Basic Card', type: AuraCard)
Widget basicCardUseCase(BuildContext context) {
  return AuraCard(
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuraText(child: Text('Card Title'), style: AuraTextStyle.heading6),
        SizedBox(height: 8),
        AuraText(
          child: Text(
            'This is a basic card with some content inside it. Cards are great for organizing information.',
          ),
          style: AuraTextStyle.body,
        ),
      ],
    ),
    padding: context.knobs.padding(),
    onTap: context.knobs.boolean(label: 'Enable Tap')
        ? () {
            final _ = Object();
          }
        : null,
    semanticLabel: context.knobs.stringOrNull(label: 'Semantic Label'),
    style: context.knobs.objectOrNull.dropdown(
      label: 'style',
      options: AuraCardStyle.values,
      labelBuilder: (value) => value.name,
    ),
  );
}
