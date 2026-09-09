// Required: Widgetbook stories use fixed example sizes.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

part 'auravibes_divider.stories.bridge.g.dart';
part 'auravibes_divider.stories.g.dart';

const _meta = Meta(AuraDivider.new);
const _verticalMeta = Meta(AuraDivider.vertical);
const _withLabelMeta = Meta(AuraDivider.withLabel);

abstract final class _StorybookDefinitions {
  static final $HorizontalDivider = _Story(
    name: 'Horizontal Divider',
    setup: (context, child, args) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 40),
      child: child,
    ),
    args: _Args(
      thickness: DoubleArg(
        1,
        name: 'Thickness',
        style: const SliderDoubleArgStyle(min: 0, max: 10, divisions: 10),
      ),
      indent: DoubleArg(
        0,
        name: 'Indent',
        style: const SliderDoubleArgStyle(min: 0, max: 100, divisions: 100),
      ),
      endIndent: DoubleArg(
        0,
        name: 'End Indent',
        style: const SliderDoubleArgStyle(min: 0, max: 100, divisions: 100),
      ),
    ),
  );

  static final $VerticalDivider = _VerticalStory(
    name: 'Vertical Divider',
    setup: (context, child, args) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 40, maxHeight: 200),
      child: child,
    ),
    args: _VerticalArgs(
      thickness: DoubleArg(
        1,
        name: 'Thickness',
        style: const SliderDoubleArgStyle(min: 0, max: 10, divisions: 10),
      ),
      indent: DoubleArg(
        0,
        name: 'Indent',
        style: const SliderDoubleArgStyle(min: 0, max: 100, divisions: 100),
      ),
      endIndent: DoubleArg(
        0,
        name: 'End Indent',
        style: const SliderDoubleArgStyle(min: 0, max: 100, divisions: 100),
      ),
    ),
  );

  static final $DividerWithLabel = _WithLabelStory(
    name: 'Divider with Label',
    setup: (context, child, args) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 40),
      child: child,
    ),
    args: _WithLabelArgs(
      label: .fixed(const Text('Section 1')),
      thickness: DoubleArg(
        1,
        name: 'Thickness',
        style: const SliderDoubleArgStyle(min: 0, max: 10, divisions: 10),
      ),
      indent: DoubleArg(
        0,
        name: 'Indent',
        style: const SliderDoubleArgStyle(min: 0, max: 100, divisions: 100),
      ),
      endIndent: DoubleArg(
        0,
        name: 'End Indent',
        style: const SliderDoubleArgStyle(min: 0, max: 100, divisions: 100),
      ),
    ),
  );
}
