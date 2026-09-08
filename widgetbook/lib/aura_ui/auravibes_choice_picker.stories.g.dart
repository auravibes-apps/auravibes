// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_choice_picker.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ChoicePickerDemo, StoryArgs<ChoicePickerDemo>>;
typedef _Scenario = ChoicePickerDemoScenario;
typedef _Defaults = ChoicePickerDemoDefaults;
typedef _Story = ChoicePickerDemoStory;
typedef _Args = ChoicePickerDemoArgs;
final ChoicePickerDemoComponent =
    Component<ChoicePickerDemo, StoryArgs<ChoicePickerDemo>>(
      name: component.name ?? 'ChoicePickerDemo',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment: r'''Demonstrates controlled single- and multiple-selection choices.''',
      stories: [$ChoicePicker..$generatedName = 'ChoicePicker'],
    );
typedef ChoicePickerDemoScenario =
    Scenario<ChoicePickerDemo, ChoicePickerDemoArgs>;
typedef ChoicePickerDemoDefaults =
    Defaults<ChoicePickerDemo, ChoicePickerDemoArgs>;

class ChoicePickerDemoStory
    extends Story<ChoicePickerDemo, ChoicePickerDemoArgs> {
  ChoicePickerDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ChoicePickerDemoArgs? args,
    StoryWidgetBuilder<ChoicePickerDemo, ChoicePickerDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ChoicePickerDemoArgs(),
         builder:
             builder ??
             (context, args) => ChoicePickerDemo(
               key: args.key,
               variant: args.variant,
               tint: args.tint,
               presentation: args.presentation,
             ),
       );
}

class ChoicePickerDemoArgs extends StoryArgs<ChoicePickerDemo> {
  ChoicePickerDemoArgs({
    Arg<Key?>? key,
    Arg<AuraChoicePickerVariant>? variant,
    Arg<AuraTint?>? tint,
    Arg<AuraChoicePickerPresentation>? presentation,
  }) : this.keyArg = $initArg('key', key, null),
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<AuraChoicePickerVariant>(
           AuraChoicePickerVariant.mutuallyExclusive,
           values: AuraChoicePickerVariant.values,
         ),
       )!,
       this.tintArg = $initArg(
         'tint',
         tint,
         NullableEnumArg<AuraTint>(null, values: AuraTint.values),
       )!,
       this.presentationArg = $initArg(
         'presentation',
         presentation,
         EnumArg<AuraChoicePickerPresentation>(
           AuraChoicePickerPresentation.list,
           values: AuraChoicePickerPresentation.values,
         ),
       )!;

  ChoicePickerDemoArgs.fixed({
    Key? key,
    AuraChoicePickerVariant variant = AuraChoicePickerVariant.mutuallyExclusive,
    AuraTint? tint = null,
    AuraChoicePickerPresentation presentation =
        AuraChoicePickerPresentation.list,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.tintArg = $initArg(
         'tint',
         tint == null ? null : Arg.fixed(tint),
         null,
       ),
       this.presentationArg = $initArg(
         'presentation',
         Arg.fixed(presentation),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<AuraChoicePickerVariant> variantArg;

  final Arg<AuraTint?>? tintArg;

  final Arg<AuraChoicePickerPresentation> presentationArg;

  Key? get key => keyArg?.value;

  AuraChoicePickerVariant get variant => variantArg.value;

  AuraTint? get tint => tintArg?.value;

  AuraChoicePickerPresentation get presentation => presentationArg.value;

  @override
  List<Arg?> get list => [keyArg, variantArg, tintArg, presentationArg];
}
