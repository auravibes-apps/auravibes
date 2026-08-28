// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_switch.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<SwitchDemo, StoryArgs<SwitchDemo>>;
typedef _Scenario = SwitchDemoScenario;
typedef _Defaults = SwitchDemoDefaults;
typedef _Story = SwitchDemoStory;
typedef _Args = SwitchDemoArgs;
final SwitchDemoComponent = Component<SwitchDemo, StoryArgs<SwitchDemo>>(
  name: component.name ?? 'SwitchDemo',
  path: component.path ?? 'aura_ui',
  docsBuilder: component.docsBuilder,
  docComment:
      r'''Demonstrates a controlled switch with size, loading, and disabled states.''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef SwitchDemoScenario = Scenario<SwitchDemo, SwitchDemoArgs>;
typedef SwitchDemoDefaults = Defaults<SwitchDemo, SwitchDemoArgs>;

class SwitchDemoStory extends Story<SwitchDemo, SwitchDemoArgs> {
  SwitchDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    SwitchDemoArgs? args,
    StoryWidgetBuilder<SwitchDemo, SwitchDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? SwitchDemoArgs(),
         builder:
             builder ??
             (context, args) => SwitchDemo(
               key: args.key,
               size: args.size,
               disabled: args.disabled,
               isLoading: args.isLoading,
               semanticLabel: args.semanticLabel,
             ),
       );
}

class SwitchDemoArgs extends StoryArgs<SwitchDemo> {
  SwitchDemoArgs({
    Arg<Key?>? key,
    Arg<AuraSwitchSize>? size,
    Arg<bool>? disabled,
    Arg<bool>? isLoading,
    Arg<String>? semanticLabel,
  }) : this.keyArg = $initArg('key', key, null),
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<AuraSwitchSize>(
           AuraSwitchSize.sm,
           values: AuraSwitchSize.values,
         ),
       )!,
       this.disabledArg = $initArg('disabled', disabled, BoolArg(false))!,
       this.isLoadingArg = $initArg('isLoading', isLoading, BoolArg(false))!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         StringArg('Switch'),
       )!;

  SwitchDemoArgs.fixed({
    Key? key,
    AuraSwitchSize size = AuraSwitchSize.sm,
    bool disabled = false,
    bool isLoading = false,
    String semanticLabel = 'Switch',
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.disabledArg = $initArg('disabled', Arg.fixed(disabled), null)!,
       this.isLoadingArg = $initArg('isLoading', Arg.fixed(isLoading), null)!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         Arg.fixed(semanticLabel),
         null,
       )!;

  final Arg<Key?>? keyArg;

  final Arg<AuraSwitchSize> sizeArg;

  final Arg<bool> disabledArg;

  final Arg<bool> isLoadingArg;

  final Arg<String> semanticLabelArg;

  Key? get key => keyArg?.value;

  AuraSwitchSize get size => sizeArg.value;

  bool get disabled => disabledArg.value;

  bool get isLoading => isLoadingArg.value;

  String get semanticLabel => semanticLabelArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    sizeArg,
    disabledArg,
    isLoadingArg,
    semanticLabelArg,
  ];
}
