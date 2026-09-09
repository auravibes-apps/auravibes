// Required: Widgetbook stories use fixed example sizes.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

part 'auravibes_container.stories.bridge.g.dart';
part 'auravibes_container.stories.g.dart';

class const _ContainerInput({
  required final AuraEdgeInsetsGeometry padding,
  required final AuraEdgeInsetsGeometry margin,
  required final AuraContainerShadow shadow,
});

const _meta = Meta(AuraContainer.new, argsType: _ContainerInput.new);

final _Defaults _containerDefaults = _Defaults(
  builder: (context, args) => AuraContainer(
    child: const AuraText(child: Text('Basic Container'), style: .body),
    padding: args.padding,
    margin: args.margin,
    variant: .surfaceVariant,
    borderRadius: 8,
    shadow: args.shadow,
  ),
);

abstract final class _StorybookDefinitions {
  static final $BasicContainer = _Story(
    name: 'Basic Container',
    args: _Args(
      padding: SingleArg(
        AuraEdgeInsetsGeometry.medium,
        values: const [
          AuraEdgeInsetsGeometry.none,
          AuraEdgeInsetsGeometry.small,
          AuraEdgeInsetsGeometry.medium,
          AuraEdgeInsetsGeometry.large,
        ],
        labelBuilder: (value) => switch (value) {
          .none => 'none',
          .small => 'Small',
          .medium => 'Medium',
          .large => 'Large',
          _ => value.toString(),
        },
      ),
      margin: SingleArg(
        AuraEdgeInsetsGeometry.none,
        name: 'margin',
        values: const [
          AuraEdgeInsetsGeometry.none,
          AuraEdgeInsetsGeometry.small,
          AuraEdgeInsetsGeometry.medium,
          AuraEdgeInsetsGeometry.large,
        ],
        labelBuilder: (value) => switch (value) {
          .none => 'none',
          .small => 'Small',
          .medium => 'Medium',
          .large => 'Large',
          _ => value.toString(),
        },
      ),
      shadow: EnumArg(
        AuraContainerShadow.values.first,
        values: AuraContainerShadow.values,
      ),
    ),
  );
}
