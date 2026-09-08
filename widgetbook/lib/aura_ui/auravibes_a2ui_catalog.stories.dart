import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_a2ui_catalog.stories.g.dart';

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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.auraTheme.spacing.md,
      children: [
        const AuraCallout(
          title: 'Review needed',
          description: 'Two items need attention before release.',
          icon: Icons.info_outline,
          tint: AuraTint.info,
        ),
        const AuraStat(
          value: '87%',
          label: 'Sprint completion',
          delta: '+4% this week',
          icon: Icons.trending_up,
          tint: AuraTint.success,
        ),
        const AuraLink(label: 'Read release notes', onPressed: noopCallback),
        const AuraTooltip(
          message: 'Visible on hover or focus',
          child: AuraIcon(Icons.help_outline),
        ),
        const AuraAccordion(
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
        const AuraStepper(
          steps: [
            AuraStep(title: 'Draft', state: AuraStepState.complete),
            AuraStep(title: 'Review', state: AuraStepState.current),
            AuraStep(title: 'Release'),
          ],
        ),
        const AuraTimeline(
          entries: [
            AuraTimelineEntry(title: 'Created', time: '09:30'),
            AuraTimelineEntry(
              title: 'Reviewed',
              description: 'Approved by the release team',
              time: '10:15',
              tint: AuraTint.success,
            ),
          ],
        ),
        const AuraSkeleton(width: 220, height: 24, semanticLabel: 'Loading'),
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
        AuraRating(
          value: _rating,
          onChanged: (value) => setState(() => _rating = value),
          label: 'Release confidence',
        ),
        AuraTagInput(
          value: _tags,
          onChanged: (value) => setState(() => _tags = value),
          removeLabel: (tag) => 'Remove $tag',
          label: 'Tags',
          placeholder: 'Add a tag',
        ),
        const AuraCodeBlock(code: 'final status = "ready";', language: 'dart'),
        const AuraKeyValue(
          entries: [
            AuraKeyValueEntry(label: 'Owner', value: 'Ada'),
            AuraKeyValueEntry(label: 'Status', value: 'Ready'),
          ],
        ),
        const AuraSection(
          title: 'Summary',
          child: AuraText(child: Text('Section content')),
          description: 'Reusable display grouping.',
        ),
        const AuraFieldset(
          title: 'Form details',
          child: AuraText(child: Text('Fieldset content')),
          description: 'Reusable form grouping.',
        ),
      ],
    ),
  );
}

const component = ComponentMeta(name: 'A2UI Catalog Components');
const meta = Meta(A2uiCatalogShowcase.new);

final $Showcase = _Story(
  name: 'Catalog components',
  setup: (context, child, args) => SizedBox(width: 360, child: child),
  args: _Args(),
  scenarios: [
    _Scenario(
      name: 'Compact phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'Large text', modes: [TextScaleMode(2)]),
  ],
);
