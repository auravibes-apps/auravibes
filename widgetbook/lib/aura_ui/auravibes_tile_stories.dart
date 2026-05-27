// ignore_for_file: avoid-returning-widgets
// Required: Widgetbook stories use helper functions that return widgets.
// ignore_for_file: no-empty-block
// Required: Widgetbook stories use intentional no-op callbacks.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'AuraTile', type: AuraTile)
Widget primaryTileUseCase(BuildContext context) {
  return AuraTile(
    child: Text(
      context.knobs.string(label: 'Child Text', initialValue: 'This is a tile'),
    ),
    onTap: () {},
    variant: context.knobs.object.dropdown(
      label: 'Variant',
      options: AuraTileVariant.values,
      labelBuilder: (value) => value.name,
    ),
    size: context.knobs.object.dropdown(
      label: 'Size',
      options: AuraTileSize.values,
      labelBuilder: (value) => value.name,
    ),
    isLoading: context.knobs.boolean(label: 'Is Loading', initialValue: false),
    leading:
        context.knobs.boolean(label: 'Show Leading Icon', initialValue: false)
        ? const Icon(Icons.info)
        : null,
    trailing:
        context.knobs.boolean(label: 'Show Trailing Icon', initialValue: false)
        ? const Icon(Icons.chevron_right)
        : null,
    enabled: context.knobs.boolean(label: 'Enabled', initialValue: true),
  );
}
