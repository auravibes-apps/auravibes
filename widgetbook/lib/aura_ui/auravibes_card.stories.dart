// Required: Widgetbook stories use intentional no-op callbacks.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

part 'auravibes_card.stories.g.dart';

class const _CardInput({
  required final String title,
  required final String description,
  required final AuraEdgeInsetsGeometry padding,
  required final bool enableTap,
  required final String? semanticLabel,
  required final AuraCardStyle style,
});

const component = ComponentMeta(name: 'AuraCard');
const meta = Meta(CardDemo.new, argsType: _CardInput.new);

final _Defaults cardDefaults = _Defaults(
  builder: (context, args) => CardDemo(
    title: args.title,
    description: args.description,
    padding: args.padding,
    enableTap: args.enableTap,
    semanticLabel: args.semanticLabel,
    style: args.style,
  ),
);

final $BasicCard = _Story(
  name: 'Basic Card',
  args: _Args(
    title: StringArg('Card Title', name: 'Title'),
    description: StringArg(
      'This is a basic card with some content inside it. Cards are great for organizing information.',
      name: 'Description',
    ),
    padding: SingleArg(
      AuraEdgeInsetsGeometry.medium,
      name: 'Padding',
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
    enableTap: BoolArg(true, name: 'Enable Tap'),
    semanticLabel: NullableStringArg(null, name: 'Semantic Label'),
    style: EnumArg(AuraCardStyle.values.first, values: AuraCardStyle.values),
  ),
  scenarios: [
    _Scenario(
      name: 'Tapped',
      run: (tester, args) async {
        await tester.tap(find.byType(AuraCard));
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);

/// Demonstrates editable card content and the optional tap callback.
class const CardDemo({
  super.key,
  required final String title,
  required final String description,
  required final AuraEdgeInsetsGeometry padding,
  required final bool enableTap,
  required final String? semanticLabel,
  required final AuraCardStyle style,
}) extends StatefulWidget {
  @override
  State<CardDemo> createState() => _CardDemoState();
}

class _CardDemoState extends State<CardDemo> {
  bool _wasTapped = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuraCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuraText(
                child: Text(widget.title),
                style: AuraTextStyle.heading6,
              ),
              const SizedBox(height: 8),
              AuraText(
                child: Text(widget.description),
                style: AuraTextStyle.body,
              ),
            ],
          ),
          padding: widget.padding,
          onTap: widget.enableTap
              ? () => setState(() => _wasTapped = true)
              : null,
          semanticLabel: widget.semanticLabel,
          style: widget.style,
        ),
        if (_wasTapped) const Text('Card tapped'),
      ],
    );
  }
}
