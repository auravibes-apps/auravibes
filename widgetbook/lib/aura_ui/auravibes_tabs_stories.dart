import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Basic Tabs', type: AuraTabs)
Widget basicTabsUseCase(BuildContext context) {
  return SizedBox(
    width: 420,
    height: 320,
    child: AuraTabs<void>(
      items: const [
        AuraTabItem(
          title: Text('Overview'),
          child: Center(child: Text('Overview content')),
          semanticLabel: 'Overview',
        ),
        AuraTabItem(
          title: Text('Details'),
          child: Center(child: Text('Details content')),
          semanticLabel: 'Details',
        ),
        AuraTabItem(
          title: Text('Activity'),
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

enum _SelectorTab { overview, details, activity }

@widgetbook.UseCase(name: 'Selector Tabs', type: AuraTabs)
Widget selectorTabsUseCase(BuildContext _) {
  var selected = _SelectorTab.overview;

  return SizedBox(
    width: 420,
    child: StatefulBuilder(
      builder: (context, setState) {
        return AuraTabs<_SelectorTab>.selector(
          options: const [
            AuraTabOption(
              value: _SelectorTab.overview,
              title: Text('Overview'),
              semanticLabel: 'Overview',
            ),
            AuraTabOption(
              value: _SelectorTab.details,
              title: Text('Details'),
              semanticLabel: 'Details',
            ),
            AuraTabOption(
              value: _SelectorTab.activity,
              title: Text('Activity'),
              semanticLabel: 'Activity',
            ),
          ],
          value: selected,
          onChanged: (value) => setState(() => selected = value),
        );
      },
    ),
  );
}
