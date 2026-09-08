// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_icon.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraIcon, StoryArgs<AuraIcon>>;
typedef _Scenario = AuraIconScenario;
typedef _Defaults = AuraIconDefaults;
typedef _Story = AuraIconStory;
typedef _Args = _IconInputArgs;
final AuraIconComponent = Component<AuraIcon, StoryArgs<AuraIcon>>(
  name: component.name ?? 'AuraIcon',
  path: component.path ?? 'aura_ui',
  docsBuilder: component.docsBuilder,
  docComment:
      r'''A customizable icon component following the Aura design system.''',
  stories: [$BasicIcons..$generatedName = 'BasicIcons'],
);
typedef AuraIconScenario = Scenario<AuraIcon, _IconInputArgs>;
typedef AuraIconDefaults = Defaults<AuraIcon, _IconInputArgs>;

class AuraIconStory extends Story<AuraIcon, _IconInputArgs> {
  AuraIconStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<AuraIcon, _IconInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(builder: builder ?? iconDefaults.builder!);
}

class _IconInputArgs extends StoryArgs<AuraIcon> {
  _IconInputArgs({required Arg<IconData> icon, Arg<AuraIconSize>? size})
    : this.iconArg = $initArg('icon', icon, null)!,
      this.sizeArg = $initArg(
        'size',
        size,
        EnumArg<AuraIconSize>(
          AuraIconSize.extraSmall,
          values: AuraIconSize.values,
        ),
      )!;

  _IconInputArgs.fixed({
    required IconData icon,
    AuraIconSize size = AuraIconSize.extraSmall,
  }) : this.iconArg = $initArg('icon', Arg.fixed(icon), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!;

  final Arg<IconData> iconArg;

  final Arg<AuraIconSize> sizeArg;

  IconData get icon => iconArg.value;

  AuraIconSize get size => sizeArg.value;

  @override
  List<Arg?> get list => [iconArg, sizeArg];
}
