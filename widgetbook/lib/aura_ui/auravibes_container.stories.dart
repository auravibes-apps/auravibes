// Required: Widgetbook stories use fixed example sizes.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

part 'auravibes_container.stories.g.dart';

class _ContainerInput {
  const _ContainerInput({
    required this.padding,
    required this.margin,
    required this.shadow,
  });

  final AuraEdgeInsetsGeometry padding;
  final AuraEdgeInsetsGeometry margin;
  final AuraContainerShadow shadow;
}

const meta = Meta(AuraContainer.new, argsType: _ContainerInput.new);

final _Defaults containerDefaults = _Defaults(
  builder: (context, args) => AuraContainer(
    child: const AuraText(
      child: Text('Basic Container'),
      style: AuraTextStyle.body,
    ),
    padding: args.padding,
    margin: args.margin,
    variant: AuraContainerVariant.surfaceVariant,
    borderRadius: 8,
    shadow: args.shadow,
  ),
);

final $BasicContainer = _Story(
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
        AuraEdgeInsetsGeometry.none => 'none',
        AuraEdgeInsetsGeometry.small => 'Small',
        AuraEdgeInsetsGeometry.medium => 'Medium',
        AuraEdgeInsetsGeometry.large => 'Large',
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
        AuraEdgeInsetsGeometry.none => 'none',
        AuraEdgeInsetsGeometry.small => 'Small',
        AuraEdgeInsetsGeometry.medium => 'Medium',
        AuraEdgeInsetsGeometry.large => 'Large',
        _ => value.toString(),
      },
    ),
    shadow: EnumArg(
      AuraContainerShadow.values.first,
      values: AuraContainerShadow.values,
    ),
  ),
);
