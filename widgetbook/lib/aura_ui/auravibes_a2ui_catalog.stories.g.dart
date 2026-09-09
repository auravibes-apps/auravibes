// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_a2ui_catalog.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<A2uiCatalogShowcase, StoryArgs<A2uiCatalogShowcase>>;
typedef _Scenario = A2uiCatalogShowcaseScenario;
typedef _Defaults = A2uiCatalogShowcaseDefaults;
typedef _Story = A2uiCatalogShowcaseStory;
typedef _Args = A2uiCatalogShowcaseArgs;
final A2uiCatalogShowcaseComponent =
    Component<A2uiCatalogShowcase, StoryArgs<A2uiCatalogShowcase>>(
      name: _component.name ?? 'A2uiCatalogShowcase',
      path: _component.path ?? 'aura_ui',
      docsBuilder: _component.docsBuilder,
      docComment: r'''One visual fixture for the reusable controls exposed to A2UI catalogs.''',
      stories: [$Showcase..$generatedName = 'Showcase'],
    );
typedef A2uiCatalogShowcaseScenario =
    Scenario<A2uiCatalogShowcase, A2uiCatalogShowcaseArgs>;
typedef A2uiCatalogShowcaseDefaults =
    Defaults<A2uiCatalogShowcase, A2uiCatalogShowcaseArgs>;

class A2uiCatalogShowcaseStory
    extends Story<A2uiCatalogShowcase, A2uiCatalogShowcaseArgs> {
  A2uiCatalogShowcaseStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    A2uiCatalogShowcaseArgs? args,
    StoryWidgetBuilder<A2uiCatalogShowcase, A2uiCatalogShowcaseArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? A2uiCatalogShowcaseArgs(),
         builder:
             builder ?? (context, args) => A2uiCatalogShowcase(key: args.key),
       );
}

class A2uiCatalogShowcaseArgs extends StoryArgs<A2uiCatalogShowcase> {
  A2uiCatalogShowcaseArgs({Arg<Key?>? key})
    : this.keyArg = $initArg('key', key, null);

  A2uiCatalogShowcaseArgs.fixed({Key? key})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null);

  final Arg<Key?>? keyArg;

  Key? get key => keyArg?.value;

  @override
  List<Arg?> get list => [keyArg];
}
