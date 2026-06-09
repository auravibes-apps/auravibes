
// Required: Widgetbook stories use intentional no-op callbacks.
// Required: Existing code repeats lookups where extraction adds noise.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
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
    onTap: () {
      final _ = Object();
    },
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
