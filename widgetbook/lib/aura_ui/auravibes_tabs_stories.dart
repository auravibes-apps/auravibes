import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Basic Tabs', type: AuraTabs)
Widget basicTabsUseCase(BuildContext context) {
  return SizedBox(
    width: 420,
    height: 320,
    child: AuraTabs(
      items: const [
        AuraTabItem(
          title: AuraText(child: Text('Overview')),
          child: Center(child: Text('Overview content')),
          semanticLabel: 'Overview',
        ),
        AuraTabItem(
          title: AuraText(child: Text('Details')),
          child: Center(child: Text('Details content')),
          semanticLabel: 'Details',
        ),
        AuraTabItem(
          title: AuraText(child: Text('Activity')),
          child: Center(child: Text('Activity content')),
          semanticLabel: 'Activity',
        ),
      ],
      initialIndex: context.knobs.int.slider(
        label: 'Initial index',
        initialValue: 0,
        min: 0,
        max: 2,
      ),
    ),
  );
}
