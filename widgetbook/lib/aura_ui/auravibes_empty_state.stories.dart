import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_empty_state.stories.bridge.g.dart';
part 'auravibes_empty_state.stories.g.dart';

const _meta = Meta(AuraEmptyState.new);

abstract final class _StorybookDefinitions {
  static final $Example = _Story(
    name: 'AuraEmptyState',
    setup: (context, child, args) =>
        StoryHelpers.constrainStoryWidth(child, maxWidth: 320),
    args: _Args(
      title: .fixed(const Text('No items yet')),
      description: .fixed(const Text('New items will appear here.')),
      icon: .fixed(
        const AuraIcon(Icons.inbox_outlined, semanticLabel: 'Inbox'),
      ),
    ),
  );
}
