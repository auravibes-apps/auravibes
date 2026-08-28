import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_tabs_selector.stories.g.dart';

const component = ComponentMeta(name: 'AuraTabs');
const meta = Meta(SelectorTabsDemo.new);

final $SelectorTabs = _Story(
  name: 'Selector Tabs',
  args: _Args(),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
      run: (tester, args) async {
        await tester.ensureVisible(find.text('Activity').first);
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(
      name: 'Selects Details',
      run: (tester, args) async {
        await tester.tap(find.text('Details'));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

enum _SelectorTab { overview, details, activity }

/// Demonstrates selector tabs whose selected value is owned by the caller.
class SelectorTabsDemo extends StatefulWidget {
  const SelectorTabsDemo({super.key});

  @override
  State<SelectorTabsDemo> createState() => _SelectorTabsDemoState();
}

class _SelectorTabsDemoState extends State<SelectorTabsDemo> {
  _SelectorTab _selected = _SelectorTab.overview;

  @override
  Widget build(BuildContext context) {
    return constrainStoryWidth(
      AuraTabs<_SelectorTab>.selector(
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
        value: _selected,
        onChanged: (value) => setState(() => _selected = value),
      ),
      maxWidth: 320,
    );
  }
}
