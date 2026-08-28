// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_message_status.stories.g.dart';

class _MessageStatusInput {
  const _MessageStatusInput({
    required this.status,
    required this.size,
    required this.tint,
    required this.showAnimation,
    required this.semanticLabel,
  });

  final AuraMessageDeliveryStatus status;
  final AuraMessageStatusSize size;
  final AuraTint? tint;
  final bool showAnimation;
  final String? semanticLabel;
}

const meta = Meta(AuraMessageStatus.new, argsType: _MessageStatusInput.new);

final _Defaults messageStatusDefaults = _Defaults(
  builder: (context, args) => AuraMessageStatus(
    status: args.status,
    size: args.size,
    tint: args.tint,
    showAnimation: args.showAnimation,
    semanticLabel: args.semanticLabel,
  ),
);

final $SendingStatus = _Story(
  name: 'Sending Status',
  setup: (context, child, args) => constrainStoryWidth(child),
  args: _Args(
    status: EnumArg(
      AuraMessageDeliveryStatus.values.first,
      name: 'Status',
      values: AuraMessageDeliveryStatus.values,
    ),
    size: EnumArg(
      AuraMessageStatusSize.values.first,
      name: 'Size',
      values: AuraMessageStatusSize.values,
    ),
    tint: NullableEnumArg(null, name: 'Tint', values: AuraTint.values),
    showAnimation: BoolArg(true, name: 'Show Animation'),
    semanticLabel: NullableStringArg(null, name: 'Semantic Label'),
  ),
);
