import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_a2ui_catalog.stories.bridge.g.dart';
part 'auravibes_a2ui_catalog.stories.g.dart';

const _a2uiFeedbackWidgets = <Widget>[
  AuraCallout(
    title: 'Review needed',
    description: 'Two items need attention before release.',
    icon: Icons.info_outline,
    tint: .info,
  ),
  AuraStat(
    value: '87%',
    label: 'Sprint completion',
    delta: '+4% this week',
    icon: Icons.trending_up,
    tint: .success,
  ),
  AuraLink(label: 'Read release notes', onPressed: StoryHelpers.noopCallback),
  AuraTooltip(
    message: 'Visible on hover or focus',
    child: AuraIcon(Icons.help_outline),
  ),
];

const _a2uiProgressWidgets = <Widget>[
  AuraAccordion(
    items: [
      AuraAccordionItem(
        title: 'Details',
        child: AuraText(child: Text('Expanded copy')),
      ),
      AuraAccordionItem(
        title: 'History',
        child: AuraText(child: Text('Historical copy')),
      ),
    ],
    initiallyExpanded: {0},
  ),
  AuraStepper(
    steps: [
      AuraStep(title: 'Draft', state: .complete),
      AuraStep(title: 'Review', state: .current),
      AuraStep(title: 'Release'),
    ],
  ),
  AuraTimeline(
    entries: [
      AuraTimelineEntry(title: 'Created', time: '09:30'),
      AuraTimelineEntry(
        title: 'Reviewed',
        description: 'Approved by the release team',
        time: '10:15',
        tint: .success,
      ),
    ],
  ),
  AuraSkeleton(width: 220, height: 24, semanticLabel: 'Loading'),
];

final _a2uiLayoutWidgets = <Widget>[
  const AuraGrid(
    children: [
      AuraCard(child: AuraText(child: Text('Grid item one'))),
      AuraCard(child: AuraText(child: Text('Grid item two'))),
    ],
    minimumItemWidth: 130,
  ),
  AuraWrap(
    children: [
      AuraBadge.text(child: const Text('Planning')),
      AuraBadge.text(child: const Text('Release')),
    ],
  ),
  const AuraRow(
    children: [
      AuraText(child: Text('Left')),
      AuraFlexItem(child: SizedBox()),
      AuraSpacer(size: 8),
      AuraText(child: Text('Right')),
    ],
  ),
];

const _a2uiContentWidgets = <Widget>[
  AuraCodeBlock(code: 'final status = "ready";', language: 'dart'),
  AuraKeyValue(
    entries: [
      AuraKeyValueEntry(label: 'Owner', value: 'Ada'),
      AuraKeyValueEntry(label: 'Status', value: 'Ready'),
    ],
  ),
  AuraSection(
    title: 'Summary',
    child: AuraText(child: Text('Section content')),
    description: 'Reusable display grouping.',
  ),
  AuraFieldset(
    title: 'Form details',
    child: AuraText(child: Text('Fieldset content')),
    description: 'Reusable form grouping.',
  ),
];

/// One visual fixture for the reusable controls exposed to A2UI catalogs.
class const A2uiCatalogShowcase({super.key}) extends StatefulWidget {
  @override
  State<A2uiCatalogShowcase> createState() => _A2uiCatalogShowcaseState();
}

class _A2uiCatalogShowcaseState extends State<A2uiCatalogShowcase> {
  var _rating = 3;
  var _tags = const ['planning', 'release'];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: .stretch,
      spacing: context.auraTheme.spacing.md,
      children: [
        ..._a2uiFeedbackWidgets,
        ..._a2uiProgressWidgets,
        ..._a2uiLayoutWidgets,
        _A2uiRating(value: _rating, onChanged: _setRating),
        _A2uiTagInput(value: _tags, onChanged: _setTags),
        ..._a2uiContentWidgets,
      ],
    ),
  );

  void _setRating(int value) => setState(() => _rating = value);

  void _setTags(List<String> value) => setState(() => _tags = value);
}

class const _A2uiRating({
  required final int value,
  required final ValueChanged<int> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraRating(
    value: value,
    onChanged: onChanged,
    label: 'Release confidence',
  );
}

class const _A2uiTagInput({
  required final List<String> value,
  required final ValueChanged<List<String>> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) => AuraTagInput(
    value: value,
    onChanged: onChanged,
    removeLabel: (tag) => 'Remove $tag',
    label: 'Tags',
    placeholder: 'Add a tag',
  );
}

const _component = ComponentMeta(name: 'A2UI Catalog Components');
const _meta = Meta(A2uiCatalogShowcase.new);

abstract final class _StorybookDefinitions {
  static final $Showcase = _Story(
    name: 'Catalog components',
    setup: (context, child, args) => SizedBox(width: 360, child: child),
    args: _Args(),
    scenarios: [
      _Scenario(
        name: 'Compact phone',
        modes: [ViewportMode(StoryHelpers.compactPhoneViewport)],
      ),
      _Scenario(name: 'Large text', modes: [TextScaleMode(2)]),
    ],
  );
}
