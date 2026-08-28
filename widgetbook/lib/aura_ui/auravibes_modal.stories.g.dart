// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_modal.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<AuraModal, StoryArgs<AuraModal>>;
typedef _Scenario = AuraModalScenario;
typedef _Defaults = AuraModalDefaults;
typedef _Story = AuraModalStory;
typedef _Args = _ModalInputArgs;
final AuraModalComponent = Component<AuraModal, StoryArgs<AuraModal>>(
  name: component.name ?? 'AuraModal',
  path: component.path ?? 'aura_ui',
  docsBuilder: component.docsBuilder,
  docComment:
      r'''A reusable modal composition with an entry point and arbitrary content.

Tapping or activating [entryPointChild] opens [contentChild] in a modal
route. Content can close itself with `Navigator.of(context).pop()`.''',
  stories: [$Modal..$generatedName = 'Modal'],
);
typedef AuraModalScenario = Scenario<AuraModal, _ModalInputArgs>;
typedef AuraModalDefaults = Defaults<AuraModal, _ModalInputArgs>;

class AuraModalStory extends Story<AuraModal, _ModalInputArgs> {
  AuraModalStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _ModalInputArgs? args,
    StoryWidgetBuilder<AuraModal, _ModalInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _ModalInputArgs(),
         builder: builder ?? modalDefaults.builder!,
       );
}

class _ModalInputArgs extends StoryArgs<AuraModal> {
  _ModalInputArgs();

  _ModalInputArgs.fixed();

  @override
  List<Arg?> get list => [];
}
