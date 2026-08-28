// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_image.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraImage, StoryArgs<AuraImage>>;
typedef _Scenario = AuraImageScenario;
typedef _Defaults = AuraImageDefaults;
typedef _Story = AuraImageStory;
typedef _Args = AuraImageArgs;
final AuraImageComponent = Component<AuraImage, StoryArgs<AuraImage>>(
  name: 'AuraImage',
  path: 'aura_ui',
  docComment:
      r'''Displays an image loaded from [url] with Aura loading and error states.''',
  stories: [$BasicImage..$generatedName = 'BasicImage'],
);
typedef AuraImageScenario = Scenario<AuraImage, AuraImageArgs>;
typedef AuraImageDefaults = Defaults<AuraImage, AuraImageArgs>;

class AuraImageStory extends Story<AuraImage, AuraImageArgs> {
  AuraImageStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    AuraImageArgs? args,
    StoryWidgetBuilder<AuraImage, AuraImageArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? AuraImageArgs(),
         builder:
             builder ??
             (context, args) => AuraImage(
               url: args.url,
               key: args.key,
               fit: args.fit,
               semanticLabel: args.semanticLabel,
               imageProvider: args.imageProvider,
               errorSemanticLabel: args.errorSemanticLabel,
             ),
       );
}

class AuraImageArgs extends StoryArgs<AuraImage> {
  AuraImageArgs({
    Arg<String>? url,
    Arg<Key?>? key,
    Arg<BoxFit>? fit,
    Arg<String?>? semanticLabel,
    Arg<ImageProvider<Object>?>? imageProvider,
    Arg<String?>? errorSemanticLabel,
  }) : this.urlArg = $initArg('url', url, StringArg(''))!,
       this.keyArg = $initArg('key', key, null),
       this.fitArg = $initArg(
         'fit',
         fit,
         EnumArg<BoxFit>(BoxFit.fill, values: BoxFit.values),
       )!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel,
         NullableStringArg(null),
       )!,
       this.imageProviderArg = $initArg('imageProvider', imageProvider, null),
       this.errorSemanticLabelArg = $initArg(
         'errorSemanticLabel',
         errorSemanticLabel,
         NullableStringArg('Image failed to load'),
       )!;

  AuraImageArgs.fixed({
    String url = '',
    Key? key,
    BoxFit fit = BoxFit.fill,
    String? semanticLabel = null,
    ImageProvider<Object>? imageProvider,
    String? errorSemanticLabel = 'Image failed to load',
  }) : this.urlArg = $initArg('url', Arg.fixed(url), null)!,
       this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.fitArg = $initArg('fit', Arg.fixed(fit), null)!,
       this.semanticLabelArg = $initArg(
         'semanticLabel',
         semanticLabel == null ? null : Arg.fixed(semanticLabel),
         null,
       ),
       this.imageProviderArg = $initArg(
         'imageProvider',
         imageProvider == null ? null : Arg.fixed(imageProvider),
         null,
       ),
       this.errorSemanticLabelArg = $initArg(
         'errorSemanticLabel',
         errorSemanticLabel == null ? null : Arg.fixed(errorSemanticLabel),
         null,
       );

  final Arg<String> urlArg;

  final Arg<Key?>? keyArg;

  final Arg<BoxFit> fitArg;

  final Arg<String?>? semanticLabelArg;

  final Arg<ImageProvider<Object>?>? imageProviderArg;

  final Arg<String?>? errorSemanticLabelArg;

  String get url => urlArg.value;

  Key? get key => keyArg?.value;

  BoxFit get fit => fitArg.value;

  String? get semanticLabel => semanticLabelArg?.value;

  ImageProvider<Object>? get imageProvider => imageProviderArg?.value;

  String? get errorSemanticLabel => errorSemanticLabelArg?.value;

  @override
  List<Arg?> get list => [
    urlArg,
    keyArg,
    fitArg,
    semanticLabelArg,
    imageProviderArg,
    errorSemanticLabelArg,
  ];
}
