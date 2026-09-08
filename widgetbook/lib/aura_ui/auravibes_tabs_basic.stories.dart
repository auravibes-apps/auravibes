import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_tabs_basic.stories.g.dart';

const component = ComponentMeta(name: 'AuraTabs');
const meta = Meta(AuraTabs.new);

final $BasicTabs = _Story<void>(
  name: 'Basic Tabs',
  setup: (context, child, args) => SizedBox(
    width: 320,
    height: 320,
    child: constrainStoryWidth(child, maxWidth: 320),
  ),
  args: _Args<void>(
    items: Arg.fixed(const [
      AuraTabItem(
        title: Text('Overview'),
        child: Center(child: AuraText(child: Text('Overview content'))),
        semanticLabel: 'Overview',
      ),
      AuraTabItem(
        title: Text('Details'),
        child: Center(child: AuraText(child: Text('Details content'))),
        semanticLabel: 'Details',
      ),
      AuraTabItem(
        title: Text('Activity'),
        child: Center(child: AuraText(child: Text('Activity content'))),
        semanticLabel: 'Activity',
      ),
    ]),
    initialIndex: IntArg(
      0,
      name: 'Initial index',
      style: const SliderIntArgStyle(min: 0, max: 2, divisions: 2),
    ),
  ),
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
