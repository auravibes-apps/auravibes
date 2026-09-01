// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_popup_menu_button.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<PopupMenuButtonDemo, StoryArgs<PopupMenuButtonDemo>>;
typedef _Scenario = PopupMenuButtonDemoScenario;
typedef _Defaults = PopupMenuButtonDemoDefaults;
typedef _Story = PopupMenuButtonDemoStory;
typedef _Args = PopupMenuButtonDemoArgs;
final PopupMenuButtonDemoComponent =
    Component<PopupMenuButtonDemo, StoryArgs<PopupMenuButtonDemo>>(
      name: component.name ?? 'PopupMenuButtonDemo',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment: r'''Demonstrates a labeled popup-menu trigger and its action entries.''',
      stories: [$PopupMenuButton..$generatedName = 'PopupMenuButton'],
    );
typedef PopupMenuButtonDemoScenario =
    Scenario<PopupMenuButtonDemo, PopupMenuButtonDemoArgs>;
typedef PopupMenuButtonDemoDefaults =
    Defaults<PopupMenuButtonDemo, PopupMenuButtonDemoArgs>;

class PopupMenuButtonDemoStory
    extends Story<PopupMenuButtonDemo, PopupMenuButtonDemoArgs> {
  PopupMenuButtonDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    PopupMenuButtonDemoArgs? args,
    StoryWidgetBuilder<PopupMenuButtonDemo, PopupMenuButtonDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? PopupMenuButtonDemoArgs(),
         builder:
             builder ?? (context, args) => PopupMenuButtonDemo(key: args.key),
       );
}

class PopupMenuButtonDemoArgs extends StoryArgs<PopupMenuButtonDemo> {
  PopupMenuButtonDemoArgs({Arg<Key?>? key})
    : this.keyArg = $initArg('key', key, null);

  PopupMenuButtonDemoArgs.fixed({Key? key})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null);

  final Arg<Key?>? keyArg;

  Key? get key => keyArg?.value;

  @override
  List<Arg?> get list => [keyArg];
}
