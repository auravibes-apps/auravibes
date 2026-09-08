// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_text.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraText, StoryArgs<AuraText>>;
typedef _Scenario = AuraTextScenario;
typedef _Defaults = AuraTextDefaults;
typedef _Story = AuraTextStory;
typedef _Args = _TextInputArgs;
final AuraTextComponent = Component<AuraText, StoryArgs<AuraText>>(
  name: 'AuraText',
  path: 'aura_ui',
  docComment:
      r'''A text widget that follows the Aura design system typography scale.

This widget provides consistent typography across the application by using
predefined text styles based on the design tokens.''',
  stories: [$AuraText..$generatedName = 'AuraText'],
);
typedef AuraTextScenario = Scenario<AuraText, _TextInputArgs>;
typedef AuraTextDefaults = Defaults<AuraText, _TextInputArgs>;

class AuraTextStory extends Story<AuraText, _TextInputArgs> {
  AuraTextStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _TextInputArgs? args,
    StoryWidgetBuilder<AuraText, _TextInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _TextInputArgs(),
         builder: builder ?? textDefaults.builder!,
       );
}

class _TextInputArgs extends StoryArgs<AuraText> {
  _TextInputArgs({
    Arg<String>? text,
    Arg<AuraTextStyle>? style,
    Arg<TextAlign?>? textAlign,
    Arg<AuraTint?>? tint,
  }) : this.textArg = $initArg('text', text, StringArg(''))!,
       this.styleArg = $initArg(
         'style',
         style,
         EnumArg<AuraTextStyle>(
           AuraTextStyle.heading1,
           values: AuraTextStyle.values,
         ),
       )!,
       this.textAlignArg = $initArg(
         'textAlign',
         textAlign,
         NullableEnumArg<TextAlign>(null, values: TextAlign.values),
       )!,
       this.tintArg = $initArg(
         'tint',
         tint,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!;

  _TextInputArgs.fixed({
    String text = '',
    AuraTextStyle style = AuraTextStyle.heading1,
    TextAlign? textAlign = null,
    AuraTint? tint = null,
  }) : this.textArg = $initArg('text', Arg.fixed(text), null)!,
       this.styleArg = $initArg('style', Arg.fixed(style), null)!,
       this.textAlignArg = $initArg(
         'textAlign',
         textAlign == null ? null : Arg.fixed(textAlign),
         null,
       ),
       this.tintArg = $initArg(
         'tint',
         tint == null ? null : Arg.fixed(tint),
         null,
       );

  final Arg<String> textArg;

  final Arg<AuraTextStyle> styleArg;

  final Arg<TextAlign?>? textAlignArg;

  final Arg<AuraTint?>? tintArg;

  String get text => textArg.value;

  AuraTextStyle get style => styleArg.value;

  TextAlign? get textAlign => textAlignArg?.value;

  AuraTint? get tint => tintArg?.value;

  @override
  List<Arg?> get list => [textArg, styleArg, textAlignArg, tintArg];
}
