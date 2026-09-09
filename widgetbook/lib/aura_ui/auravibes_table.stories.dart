import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'auravibes_table.stories.bridge.g.dart';
part 'auravibes_table.stories.g.dart';

const _meta = Meta(AuraTable.new);

abstract final class _StorybookDefinitions {
  static final $Example = _Story(
    name: 'AuraTable',
    setup: (context, child, args) => SizedBox(width: 320, child: child),
    args: _Args(
      columns: .fixed(const ['Name', 'Count', 'Available', 'Notes']),
      rows: .fixed(const <List<Object?>>[
        [
          'Sample A',
          12,
          true,
          'A longer note demonstrates horizontal scrolling',
        ],
        ['Sample B', 0, false, null],
      ]),
    ),
  );
}
