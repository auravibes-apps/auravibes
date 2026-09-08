// Required: Widgetbook stories use intentional no-op callbacks.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_tile.stories.g.dart';

class const _TileInput({
  required final String childText,
  required final AuraTileVariant variant,
  required final AuraTileSize size,
  required final bool isLoading,
  required final bool showLeadingIcon,
  required final bool showTrailingIcon,
  required final bool enabled,
});

const meta = Meta(AuraTile.new, argsType: _TileInput.new);

final _Defaults tileDefaults = _Defaults(
  builder: (context, args) => AuraTile(
    child: Text(args.childText),
    onTap: noopCallback,
    variant: args.variant,
    size: args.size,
    isLoading: args.isLoading,
    leading: args.showLeadingIcon ? const Icon(Icons.info) : null,
    trailing: args.showTrailingIcon ? const Icon(Icons.chevron_right) : null,
    enabled: args.enabled,
  ),
);

final $AuraTile = _Story(
  name: 'AuraTile',
  setup: (context, child, args) => constrainStoryWidth(child),
  args: _Args(
    childText: StringArg('This is a tile', name: 'Child Text'),
    variant: EnumArg(
      AuraTileVariant.values.first,
      name: 'Variant',
      values: AuraTileVariant.values,
    ),
    size: EnumArg(
      AuraTileSize.values.first,
      name: 'Size',
      values: AuraTileSize.values,
    ),
    isLoading: BoolArg(false, name: 'Is Loading'),
    showLeadingIcon: BoolArg(false, name: 'Show Leading Icon'),
    showTrailingIcon: BoolArg(false, name: 'Show Trailing Icon'),
    enabled: BoolArg(true, name: 'Enabled'),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(name: 'Large Text', modes: [TextScaleMode(2)]),
    _Scenario(
      name: 'Tapped',
      run: (tester, args) async {
        await tester.tap(find.byType(AuraTile));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);
