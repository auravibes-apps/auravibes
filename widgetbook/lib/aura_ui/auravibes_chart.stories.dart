import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_chart.stories.bridge.g.dart';
part 'auravibes_chart.stories.g.dart';

const _meta = Meta(AuraChart.new);

abstract final class _StorybookDefinitions {
  static final $Example = _Story(
    name: 'AuraChart',
    setup: (context, child, args) =>
        StoryHelpers.constrainStoryWidth(child, maxWidth: 320),
    args: _Args(
      labels: .fixed(const ['A', 'B', 'C', 'D', 'E']),
      series: .fixed(const [
        AuraChartSeries(label: 'Samples', values: [2, -1, 4, 3, 7]),
        AuraChartSeries(
          label: 'Comparison',
          values: [1, 2, 3, 2, 4],
          tint: .secondary,
        ),
      ]),
      semanticLabel: StringArg('Five samples: 2, minus 1, 4, 3, and 7 units.'),
      type: EnumArg(AuraChartType.line, values: AuraChartType.values),
    ),
  );
}
