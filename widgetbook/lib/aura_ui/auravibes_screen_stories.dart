import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Aura Screen', type: AuraScreen)
Widget defaultAuraScreenUseCase(BuildContext context) {
  return AuraScreen(
    appBar: AppBar(
      title: const Text('Aura Screen'),
      backgroundColor: context.auraColors.primary,
    ),
    variant: context.knobs.object.dropdown(
      label: 'variant',
      options: AuraScreenVariation.values,
      labelBuilder: (value) => value.name,
    ),
    child: const Center(
      child: AuraPadding(
        padding: .large,
        child: AuraCard(
          style: .glass,
          child: SizedBox(
            height: 300,
            width: 300,
            child: AuraText(child: Text('Hello, Aura Screen!')),
          ),
        ),
      ),
    ),
  );
}
