import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'auravibes_avatar.stories.g.dart';

const meta = Meta(AuraAvatar.new);

final $Example = _Story(
  name: 'AuraAvatar',
  setup: (context, child, args) => SizedBox(width: 320, child: child),
  args: _Args(
    child: .fixed(const Text('AL')),
    semanticLabel: NullableStringArg('Alex Lee'),
    size: EnumArg(AuraSpacing.xl2, values: AuraSpacing.values),
    tint: EnumArg(AuraTint.primary, values: AuraTint.values),
  ),
);
