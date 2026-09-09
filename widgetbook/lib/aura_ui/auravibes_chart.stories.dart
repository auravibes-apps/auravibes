import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'auravibes_chart.stories.g.dart';

const meta = Meta(AuraChart.new);

final $Example = _Story(
  name: 'AuraChart',
  setup: (context, child, args) => SizedBox(width: 320, child: child),
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
