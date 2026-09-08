// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_input.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraInput, StoryArgs<AuraInput>>;
typedef _Scenario = AuraInputScenario;
typedef _Defaults = AuraInputDefaults;
typedef _Story = AuraInputStory;
typedef _Args = _InputControlsArgs;
final AuraInputComponent = Component<AuraInput, StoryArgs<AuraInput>>(
  name: component.name ?? 'AuraInput',
  path: component.path ?? 'aura_ui',
  docsBuilder: component.docsBuilder,
  docComment:
      r'''A customizable input field component following the Aura design system.

This input field supports multiple sizes, validation states, and provides
consistent styling across the application by using the AuraFieldWrapper.''',
  stories: [$Input..$generatedName = 'Input'],
);
typedef AuraInputScenario = Scenario<AuraInput, _InputControlsArgs>;
typedef AuraInputDefaults = Defaults<AuraInput, _InputControlsArgs>;

class AuraInputStory extends Story<AuraInput, _InputControlsArgs> {
  AuraInputStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _InputControlsArgs? args,
    StoryWidgetBuilder<AuraInput, _InputControlsArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _InputControlsArgs(),
         builder: builder ?? inputDefaults.builder!,
       );
}

class _InputControlsArgs extends StoryArgs<AuraInput> {
  _InputControlsArgs({
    Arg<String?>? initialValue,
    Arg<String?>? placeholderText,
    Arg<String?>? hintText,
    Arg<IconData?>? prefixIcon,
    Arg<IconData?>? suffixIcon,
    Arg<AuraInputSize>? size,
    Arg<AuraInputState>? state,
    Arg<TextInputType?>? keyboardType,
    Arg<bool>? enabled,
    Arg<int>? maxLines,
    Arg<int?>? maxLength,
    Arg<String>? semanticLabel,
  }) : this.initialValueArg = $initArg(
         'initialValue',
         initialValue,
         NullableStringArg(null),
       )!,
       this.placeholderTextArg = $initArg(
         'placeholderText',
         placeholderText,
         NullableStringArg(null),
       )!,
       this.hintTextArg = $initArg(
         'hintText',
         hintText,
         NullableStringArg(null),
       )!,
       this.prefixIconArg = $initArg('prefixIcon', prefixIcon, null),
       this.suffixIconArg = $initArg('suffixIcon', suffixIcon, null),
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<AuraInputSize>(
           AuraInputSize.small,
           values: AuraInputSize.values,
         ),
       )!,
       this.stateArg = $initArg(
         'state',
         state,
         EnumArg<AuraInputState>(
           AuraInputState.normal,
           values: AuraInputState.values,
         ),
       )!,
       this.keyboardTypeArg = $initArg('keyboardType', keyboardType, null),
       this.enabledArg = $initArg('enabled', enabled, BoolArg(false))!,
       this.maxLinesArg = $initArg('maxLines', maxLines, IntArg(0))!,
       this.maxLengthArg = $initArg(
         'maxLength',
         maxLength,
         NullableIntArg(null),
       )!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         StringArg(''),
       )!;

  _InputControlsArgs.fixed({
    String? initialValue = null,
    String? placeholderText = null,
    String? hintText = null,
    IconData? prefixIcon,
    IconData? suffixIcon,
    AuraInputSize size = AuraInputSize.small,
    AuraInputState state = AuraInputState.normal,
    TextInputType? keyboardType,
    bool enabled = false,
    int maxLines = 0,
    int? maxLength = null,
    String semanticLabel = '',
  }) : this.initialValueArg = $initArg(
         'initialValue',
         initialValue == null ? null : Arg.fixed(initialValue),
         null,
       ),
       this.placeholderTextArg = $initArg(
         'placeholderText',
         placeholderText == null ? null : Arg.fixed(placeholderText),
         null,
       ),
       this.hintTextArg = $initArg(
         'hintText',
         hintText == null ? null : Arg.fixed(hintText),
         null,
       ),
       this.prefixIconArg = $initArg(
         'prefixIcon',
         prefixIcon == null ? null : Arg.fixed(prefixIcon),
         null,
       ),
       this.suffixIconArg = $initArg(
         'suffixIcon',
         suffixIcon == null ? null : Arg.fixed(suffixIcon),
         null,
       ),
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.stateArg = $initArg('state', Arg.fixed(state), null)!,
       this.keyboardTypeArg = $initArg(
         'keyboardType',
         keyboardType == null ? null : Arg.fixed(keyboardType),
         null,
       ),
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.maxLinesArg = $initArg('maxLines', Arg.fixed(maxLines), null)!,
       this.maxLengthArg = $initArg(
         'maxLength',
         maxLength == null ? null : Arg.fixed(maxLength),
         null,
       ),
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         Arg.fixed(semanticLabel),
         null,
       )!;

  final Arg<String?>? initialValueArg;

  final Arg<String?>? placeholderTextArg;

  final Arg<String?>? hintTextArg;

  final Arg<IconData?>? prefixIconArg;

  final Arg<IconData?>? suffixIconArg;

  final Arg<AuraInputSize> sizeArg;

  final Arg<AuraInputState> stateArg;

  final Arg<TextInputType?>? keyboardTypeArg;

  final Arg<bool> enabledArg;

  final Arg<int> maxLinesArg;

  final Arg<int?>? maxLengthArg;

  final Arg<String> semanticLabelArg;

  String? get initialValue => initialValueArg?.value;

  String? get placeholderText => placeholderTextArg?.value;

  String? get hintText => hintTextArg?.value;

  IconData? get prefixIcon => prefixIconArg?.value;

  IconData? get suffixIcon => suffixIconArg?.value;

  AuraInputSize get size => sizeArg.value;

  AuraInputState get state => stateArg.value;

  TextInputType? get keyboardType => keyboardTypeArg?.value;

  bool get enabled => enabledArg.value;

  int get maxLines => maxLinesArg.value;

  int? get maxLength => maxLengthArg?.value;

  String get semanticLabel => semanticLabelArg.value;

  @override
  List<Arg?> get list => [
    initialValueArg,
    placeholderTextArg,
    hintTextArg,
    prefixIconArg,
    suffixIconArg,
    sizeArg,
    stateArg,
    keyboardTypeArg,
    enabledArg,
    maxLinesArg,
    maxLengthArg,
    semanticLabelArg,
  ];
}
