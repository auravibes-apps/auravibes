// Required: Widgetbook stories use fixed example sizes.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_input.stories.g.dart';

const _iconValues = <IconData>[
  Icons.add,
  Icons.edit,
  Icons.favorite,
  Icons.thumb_up,
  Icons.star,
  Icons.info,
  Icons.settings,
  Icons.search,
  Icons.home,
  Icons.person,
  Icons.camera_alt,
  Icons.phone,
  Icons.map,
  Icons.lock,
];

class const _InputControls({
  required final String? initialValue,
  required final String? placeholderText,
  required final String? hintText,
  required final IconData? prefixIcon,
  required final IconData? suffixIcon,
  required final AuraInputSize size,
  required final AuraInputState state,
  required final TextInputType? keyboardType,
  required final bool enabled,
  required final int maxLines,
  required final int? maxLength,
  required final String semanticLabel,
});

const component = ComponentMeta(name: 'AuraInput');
const meta = Meta(AuraInput.new, argsType: _InputControls.new);

final _Defaults inputDefaults = _Defaults(
  builder: (context, args) {
    final placeholderText = args.placeholderText;
    final hintText = args.hintText;

    return AuraInput(
      initialValue: args.initialValue,
      placeholder: placeholderText == null ? null : Text(placeholderText),
      hint: hintText == null ? null : Text(hintText),
      prefixIcon: args.prefixIcon == null ? null : Icon(args.prefixIcon),
      suffixIcon: args.suffixIcon == null ? null : Icon(args.suffixIcon),
      size: args.size,
      state: args.state,
      keyboardType: args.keyboardType,
      enabled: args.enabled,
      maxLines: args.maxLines,
      maxLength: args.maxLength,
      semanticLabel: args.semanticLabel,
    );
  },
);

final $Input = _Story(
  name: 'Input',
  setup: (context, child, args) => constrainStoryWidth(child),
  args: _Args(
    initialValue: NullableStringArg(null, name: 'Initial Value'),
    placeholderText: NullableStringArg('Enter text here', name: 'Placeholder'),
    hintText: NullableStringArg('This is a hint text', name: 'Hint'),
    prefixIcon: NullableSingleArg(
      null,
      name: 'Prefix Icon',
      values: _iconValues,
      labelBuilder: auraIconLabel,
    ),
    suffixIcon: NullableSingleArg(
      null,
      name: 'Suffix Icon',
      values: _iconValues,
      labelBuilder: auraIconLabel,
    ),
    size: EnumArg(AuraInputSize.values.first, values: AuraInputSize.values),
    state: EnumArg(AuraInputState.values.first, values: AuraInputState.values),
    keyboardType: NullableSingleArg(
      null,
      name: 'Keyboard Type',
      values: TextInputType.values,
      labelBuilder: (value) => value.toString(),
    ),
    enabled: BoolArg(true, name: 'Enabled'),
    maxLines: IntArg(
      1,
      name: 'Max Lines',
      style: const SliderIntArgStyle(min: 1, max: 10, divisions: 9),
    ),
    maxLength: NullableIntArg(null, name: 'Max Length'),
    semanticLabel: StringArg('Text input', name: 'Semantic Label'),
  ),
  scenarios: [
    _Scenario(
      name: 'Compact Phone',
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(name: 'Large Text', modes: [TextScaleMode(2)]),
    _Scenario(
      name: 'Enters Text',
      run: (tester, args) async {
        await tester.enterText(find.byType(TextField), 'Widgetbook input');
        await tester.pump(const Duration(milliseconds: 300));
      },
    ),
  ],
);
