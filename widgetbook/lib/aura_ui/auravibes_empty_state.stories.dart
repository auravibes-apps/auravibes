import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

part 'auravibes_empty_state.stories.bridge.g.dart';
part 'auravibes_empty_state.stories.g.dart';

const _meta = Meta(AuraEmptyState.new);

abstract final class _StorybookDefinitions {
  static final $Example = _Story(
    name: 'AuraEmptyState',
    setup: (context, child, args) => SizedBox(width: 320, child: child),
    args: _Args(
      title: .fixed(const Text('No items yet')),
      description: .fixed(const Text('New items will appear here.')),
      icon: .fixed(
        const AuraIcon(Icons.inbox_outlined, semanticLabel: 'Inbox'),
      ),
    ),
  );
}
