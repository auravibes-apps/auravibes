// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_popup_menu.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraPopupMenu, StoryArgs<AuraPopupMenu>>;
typedef _Scenario = AuraPopupMenuScenario;
typedef _Defaults = AuraPopupMenuDefaults;
typedef _Story = AuraPopupMenuStory;
typedef _Args = _PopupMenuInputArgs;
final AuraPopupMenuComponent =
    Component<AuraPopupMenu, StoryArgs<AuraPopupMenu>>(
      name: component.name ?? 'AuraPopupMenu',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment: r'''A popup menu widget that displays a list of menu items.

The menu can be controlled programmatically using an
[AuraPopupMenuController].''',
      stories: [$BasicPopupMenu..$generatedName = 'BasicPopupMenu'],
    );
typedef AuraPopupMenuScenario = Scenario<AuraPopupMenu, _PopupMenuInputArgs>;
typedef AuraPopupMenuDefaults = Defaults<AuraPopupMenu, _PopupMenuInputArgs>;

class AuraPopupMenuStory extends Story<AuraPopupMenu, _PopupMenuInputArgs> {
  AuraPopupMenuStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _PopupMenuInputArgs? args,
    StoryWidgetBuilder<AuraPopupMenu, _PopupMenuInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _PopupMenuInputArgs(),
         builder: builder ?? popupMenuDefaults.builder!,
       );
}

class _PopupMenuInputArgs extends StoryArgs<AuraPopupMenu> {
  _PopupMenuInputArgs();

  _PopupMenuInputArgs.fixed();

  @override
  List<Arg?> get list => [];
}
