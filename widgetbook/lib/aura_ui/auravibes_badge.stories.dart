// Required: Widgetbook stories use fixed example sizes.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

part 'auravibes_badge.stories.g.dart';

class _TextBadgeInput {
  const _TextBadgeInput({
    required this.text,
    required this.variant,
    required this.size,
  });

  final String text;
  final AuraBadgeVariant variant;
  final AuraBadgeSize size;
}

const textMeta = Meta(AuraBadge.text, argsType: _TextBadgeInput.new);
const countMeta = Meta(AuraBadge.count);
const dotMeta = Meta(AuraBadge.dot);
const meta = Meta(AuraBadge.new);

final _TextDefaults textDefaults = _TextDefaults(
  builder: (context, args) => AuraBadge.text(
    child: Text(args.text),
    variant: args.variant,
    size: args.size,
  ),
);

final $TextBadge = _TextStory(
  name: 'Text Badge',
  args: _TextArgs(
    text: StringArg('Badge', name: 'text'),
    variant: EnumArg(
      AuraBadgeVariant.values.first,
      values: AuraBadgeVariant.values,
    ),
    size: EnumArg(AuraBadgeSize.values.first, values: AuraBadgeSize.values),
  ),
);

final $CountBadge = _CountStory(
  name: 'Count Badge',
  args: _CountArgs(
    count: IntArg(5, name: 'count'),
    variant: EnumArg(
      AuraBadgeVariant.values.first,
      values: AuraBadgeVariant.values,
    ),
    size: EnumArg(AuraBadgeSize.values.first, values: AuraBadgeSize.values),
  ),
);

final $DotBadge = _DotStory(
  name: 'Dot Badge',
  args: _DotArgs(
    variant: EnumArg(
      AuraBadgeVariant.values.first,
      values: AuraBadgeVariant.values,
    ),
  ),
);

final $CustomContentBadge = _Story(
  name: 'Custom Content Badge',
  args: _Args(
    child: Arg.fixed(
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16),
          SizedBox(width: 4),
          Text('Premium', style: TextStyle(fontSize: 12)),
        ],
      ),
    ),
    variant: EnumArg(
      AuraBadgeVariant.values.first,
      values: AuraBadgeVariant.values,
    ),
    size: EnumArg(AuraBadgeSize.values.first, values: AuraBadgeSize.values),
  ),
);
