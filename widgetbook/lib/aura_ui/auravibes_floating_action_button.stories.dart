// Required: Widgetbook stories use intentional no-op callbacks.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_floating_action_button.stories.g.dart';

const _iconValues = <IconData>[
  Icons.add,
  Icons.edit,
  Icons.favorite,
  Icons.thumb_up,
  Icons.star,
  Icons.info,
  Icons.settings,
  Icons.search,
  Icons.home,
  Icons.person,
  Icons.camera_alt,
  Icons.phone,
  Icons.map,
  Icons.lock,
];

const meta = Meta(AuraFloatingActionButton.new);
const extendedMeta = Meta(AuraFloatingActionButton.extended);

final $RegularFAB = _Story(
  name: 'Regular FAB',
  args: _Args(
    onPressed: Arg.fixed(noopCallback),
    icon: SingleArg(
      Icons.add,
      name: 'Icon',
      values: _iconValues,
      labelBuilder: auraIconLabel,
    ),
    size: EnumArg(AuraFABSize.regular, values: AuraFABSize.values),
    semanticLabel: StringArg('Create item', name: 'Semantic Label'),
    tooltip: NullableStringArg('Tooltip', name: 'Tooltip'),
  ),
  scenarios: [
    _Scenario(
      name: 'Pressed',
      run: (tester, args) async {
        await tester.tap(find.byType(AuraFloatingActionButton));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

final $ExtendedFAB = _ExtendedStory(
  name: 'Extended FAB',
  args: _ExtendedArgs(
    onPressed: Arg.fixed(noopCallback),
    icon: SingleArg(
      Icons.add,
      name: 'Icon',
      values: _iconValues,
      labelBuilder: auraIconLabel,
    ),
    text: StringArg('Create New', name: 'Text'),
    semanticLabel: StringArg('Create item', name: 'Semantic Label'),
    tooltip: NullableStringArg('Tooltip', name: 'Tooltip'),
  ),
  scenarios: [
    _ExtendedScenario(
      name: 'Pressed',
      run: (tester, args) async {
        await tester.tap(find.byType(AuraFloatingActionButton));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);
