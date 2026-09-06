// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_avatar.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraAvatar, StoryArgs<AuraAvatar>>;
typedef _Scenario = AuraAvatarScenario;
typedef _Defaults = AuraAvatarDefaults;
typedef _Story = AuraAvatarStory;
typedef _Args = AuraAvatarArgs;
final AuraAvatarComponent = Component<AuraAvatar, StoryArgs<AuraAvatar>>(
  name: 'AuraAvatar',
  path: 'aura_ui',
  docComment: r'''A circular image with caller-provided initials or icon as fallback.''',
  stories: [$Example..$generatedName = 'Example'],
);
typedef AuraAvatarScenario = Scenario<AuraAvatar, AuraAvatarArgs>;
typedef AuraAvatarDefaults = Defaults<AuraAvatar, AuraAvatarArgs>;

class AuraAvatarStory extends Story<AuraAvatar, AuraAvatarArgs> {
  AuraAvatarStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<AuraAvatar, AuraAvatarArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         builder:
             builder ??
             (context, args) => AuraAvatar(
               child: args.child,
               key: args.key,
               imageProvider: args.imageProvider,
               semanticLabel: args.semanticLabel,
               size: args.size,
               tint: args.tint,
             ),
       );
}

class AuraAvatarArgs extends StoryArgs<AuraAvatar> {
  AuraAvatarArgs({
    required Arg<Widget> child,
    Arg<Key?>? key,
    Arg<ImageProvider<Object>?>? imageProvider,
    Arg<String?>? semanticLabel,
    Arg<AuraSpacing>? size,
    Arg<AuraTint>? tint,
  }) : this.childArg = $initArg('child', child, null)!,
       this.keyArg = $initArg('key', key, null),
       this.imageProviderArg = $initArg('imageProvider', imageProvider, null),
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         NullableStringArg(null),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<AuraSpacing>(AuraSpacing.xl2, values: AuraSpacing.values),
       )!,
       this.tintArg = $initArg(
         'tint',
         tint,
         EnumArg<AuraTint>(AuraTint.primary, values: AuraTint.values),
       )!;

  AuraAvatarArgs.fixed({
    required Widget child,
    Key? key,
    ImageProvider<Object>? imageProvider,
    String? semanticLabel = null,
    AuraSpacing size = AuraSpacing.xl2,
    AuraTint tint = AuraTint.primary,
  }) : this.childArg = $initArg('child', Arg.fixed(child), null)!,
       this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.imageProviderArg = $initArg(
         'imageProvider',
         imageProvider == null ? null : Arg.fixed(imageProvider),
         null,
       ),
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel == null ? null : Arg.fixed(semanticLabel),
         null,
       ),
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.tintArg = $initArg('tint', Arg.fixed(tint), null)!;

  final Arg<Widget> childArg;

  final Arg<Key?>? keyArg;

  final Arg<ImageProvider<Object>?>? imageProviderArg;

  final Arg<String?>? semanticLabelArg;

  final Arg<AuraSpacing> sizeArg;

  final Arg<AuraTint> tintArg;

  Widget get child => childArg.value;

  Key? get key => keyArg?.value;

  ImageProvider<Object>? get imageProvider => imageProviderArg?.value;

  String? get semanticLabel => semanticLabelArg?.value;

  AuraSpacing get size => sizeArg.value;

  AuraTint get tint => tintArg.value;

  @override
  List<Arg?> get list => [
    childArg,
    keyArg,
    imageProviderArg,
    semanticLabelArg,
    sizeArg,
    tintArg,
  ];
}
