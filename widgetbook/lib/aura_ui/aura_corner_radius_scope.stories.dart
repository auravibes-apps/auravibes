import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'aura_corner_radius_scope.stories.bridge.g.dart';
part 'aura_corner_radius_scope.stories.g.dart';

class const _RadiusScopeInput({
  required final AuraBorderRadius level,
  required final double delta,
});

const _meta = Meta(RadiusScopeDemo.new, argsType: _RadiusScopeInput.new);

final _Defaults _radiusScopeDefaults = _Defaults(
  builder: (context, args) =>
      RadiusScopeDemo(level: args.level, delta: args.delta),
);

abstract final class _StorybookDefinitions {
  static final $SelectionAndAdjustment = _Story(
    name: 'Selection and Adjustment',
    setup: (context, child, args) => StoryHelpers.constrainStoryWidth(
      Padding(padding: const EdgeInsets.all(16), child: child),
    ),
    args: _Args(
      level: EnumArg(.xl, name: 'Outer level', values: AuraBorderRadius.values),
      delta: DoubleArg(
        4,
        name: 'Radius reduction',
        style: const SliderDoubleArgStyle(min: 0, max: 20, divisions: 20),
      ),
    ),
  );
}

/// Shows a token-selected scope and a nested pixel adjustment.
class const RadiusScopeDemo({
  super.key,
  required final AuraBorderRadius level,
  required final double delta,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCornerRadiusScope.select(
    level: level,
    child: Builder(
      builder: (context) => Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Text('Selected radius: ${AuraCornerRadiusScope.of(context)}dp'),
          const AuraSizedBox(height: .sm),
          const AuraTile(child: Text('Selected scope')),
          const AuraSizedBox(height: .md),
          AuraCornerRadiusScope.adjust(
            delta: delta,
            child: Builder(
              builder: (context) => Column(
                crossAxisAlignment: .stretch,
                children: [
                  Text(
                    'Adjusted radius: ${AuraCornerRadiusScope.of(context)}dp',
                  ),
                  const AuraSizedBox(height: .sm),
                  const AuraTile(child: Text('Nested adjustment')),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
