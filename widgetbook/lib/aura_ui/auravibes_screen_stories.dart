import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Aura Screen', type: AuraScreen)
Widget defaultAuraScreenUseCase(BuildContext context) {
  return AuraScreen(
    child: const Center(
      child: AuraPadding(
        child: AuraCard(
          child: SizedBox(
            width: 300,
            height: 300,
            child: AuraText(child: Text('Hello, Aura Screen!')),
          ),
          style: .glass,
        ),
        padding: .large,
      ),
    ),
    appBar: AppBar(
      title: const Text('Aura Screen'),
      backgroundColor: context.auraColors.primary,
    ),
    variant: context.knobs.object.dropdown(
      label: 'variant',
      options: AuraScreenVariation.values,
      labelBuilder: (value) => value.name,
    ),
  );
}
