// Required: Widgetbook stories use fixed example sizes.
import 'package:auravibes_ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';

part 'auravibes_spinner.stories.g.dart';

class const _SpinnerInput({
  required final AuraSpinnerSize size,
  required final AuraTint? tint,
  required final double strokeWidth,
  required final String semanticLabel,
});

const meta = Meta(AuraSpinner.new, argsType: _SpinnerInput.new);

final _Defaults spinnerDefaults = _Defaults(
  builder: (context, args) => AuraSpinner(
    size: args.size,
    tint: args.tint,
    strokeWidth: args.strokeWidth,
    semanticLabel: args.semanticLabel,
  ),
);

final $AuraSpinner = _Story(
  name: 'AuraSpinner',
  args: _Args(
    size: EnumArg(AuraSpinnerSize.values.first, values: AuraSpinnerSize.values),
    tint: NullableEnumArg(null, name: 'Tint', values: AuraTint.values),
    strokeWidth: DoubleArg(
      4,
      name: 'strokeWidth',
      style: const SliderDoubleArgStyle(min: 1, max: 10, divisions: 9),
    ),
    semanticLabel: StringArg('Loading', name: 'Semantic Label'),
  ),
);
