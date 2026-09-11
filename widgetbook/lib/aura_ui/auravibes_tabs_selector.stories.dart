import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_tabs_selector.stories.bridge.g.dart';
part 'auravibes_tabs_selector.stories.g.dart';

const _component = ComponentMeta(name: 'AuraTabs');
const _meta = Meta(SelectorTabsDemo.new);

abstract final class _StorybookDefinitions {
  static final $SelectorTabs = _Story(
    name: 'Selector Tabs',
    args: _Args(),
    scenarios: [
      _Scenario(
        name: 'Compact Phone',
        modes: [ViewportMode(StoryHelpers.compactPhoneViewport)],
        run: (tester, args) async {
          await tester.ensureVisible(find.text('Activity').first);
          await tester.pump(const Duration(milliseconds: 300));
        },
      ),
      _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(.rtl)]),
      _Scenario(
        name: 'Selects Details',
        run: (tester, args) async {
          await tester.tap(find.text('Details'));
          await tester.pump(const Duration(milliseconds: 300));
        },
      ),
    ],
  );
}

enum _SelectorTab { overview, details, activity }

/// Demonstrates selector tabs whose selected value is owned by the caller.
class const SelectorTabsDemo({super.key}) extends StatefulWidget {
  @override
  State<SelectorTabsDemo> createState() => _SelectorTabsDemoState();
}

class _SelectorTabsDemoState extends State<SelectorTabsDemo> {
  static const List<AuraTabOption<_SelectorTab>> _options = [
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
  ];
  _SelectorTab _selected = .overview;

  @override
  Widget build(BuildContext context) => StoryHelpers.constrainStoryWidth(
    AuraTabs<_SelectorTab>.selector(
      options: _options,
      value: _selected,
      onChanged: _select,
    ),
    maxWidth: 320,
  );

  void _select(_SelectorTab value) => setState(() => _selected = value);
}
