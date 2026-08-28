// Required: Widgetbook stories use intentional no-op callbacks.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_tile.stories.g.dart';

class _TileInput {
  const _TileInput({
    required this.childText,
    required this.variant,
    required this.size,
    required this.isLoading,
    required this.showLeadingIcon,
    required this.showTrailingIcon,
    required this.enabled,
  });

  final String childText;
  final AuraTileVariant variant;
  final AuraTileSize size;
  final bool isLoading;
  final bool showLeadingIcon;
  final bool showTrailingIcon;
  final bool enabled;
}

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
