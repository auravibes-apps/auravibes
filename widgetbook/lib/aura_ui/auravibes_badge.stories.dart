// Required: Widgetbook stories use fixed example sizes.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

part 'auravibes_badge.stories.bridge.g.dart';
part 'auravibes_badge.stories.g.dart';

class const _TextBadgeInput({
  required final String text,
  required final AuraBadgeVariant variant,
  required final AuraBadgeSize size,
});

const _textMeta = Meta(AuraBadge.text, argsType: _TextBadgeInput.new);
const _countMeta = Meta(AuraBadge.count);
const _dotMeta = Meta(AuraBadge.dot);
const _meta = Meta(AuraBadge.new);

final _TextDefaults _textDefaults = _TextDefaults(
  builder: (context, args) => AuraBadge.text(
    child: Text(args.text),
    variant: args.variant,
    size: args.size,
  ),
);

abstract final class _StorybookDefinitions {
  static final $TextBadge = _TextStory(
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

  static final $CountBadge = _CountStory(
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

  static final $DotBadge = _DotStory(
    name: 'Dot Badge',
    args: _DotArgs(
      variant: EnumArg(
        AuraBadgeVariant.values.first,
        values: AuraBadgeVariant.values,
      ),
    ),
  );

  static final $CustomContentBadge = _Story(
    name: 'Custom Content Badge',
    args: _Args(
      child: .fixed(
        const Row(
          mainAxisSize: .min,
          children: [
            Icon(Icons.star, size: 16),
            SizedBox(width: 4),
            Text('Premium', style: .new(fontSize: 12)),
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
}
