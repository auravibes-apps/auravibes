// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'auravibes_loading_overlay.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component =
    Component<LoadingOverlayDemo, StoryArgs<LoadingOverlayDemo>>;
typedef _Scenario = LoadingOverlayDemoScenario;
typedef _Defaults = LoadingOverlayDemoDefaults;
typedef _Story = LoadingOverlayDemoStory;
typedef _Args = _LoadingOverlayInputArgs;
final LoadingOverlayDemoComponent =
    Component<LoadingOverlayDemo, StoryArgs<LoadingOverlayDemo>>(
      name: component.name ?? 'LoadingOverlayDemo',
      path: component.path ?? 'aura_ui',
      docsBuilder: component.docsBuilder,
      docComment: r'''Demonstrates loading content with an optional message and accessible state.''',
      stories: [$LoadingOverlay..$generatedName = 'LoadingOverlay'],
    );
typedef LoadingOverlayDemoScenario =
    Scenario<LoadingOverlayDemo, _LoadingOverlayInputArgs>;
typedef LoadingOverlayDemoDefaults =
    Defaults<LoadingOverlayDemo, _LoadingOverlayInputArgs>;

class LoadingOverlayDemoStory
    extends Story<LoadingOverlayDemo, _LoadingOverlayInputArgs> {
  LoadingOverlayDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    _LoadingOverlayInputArgs? args,
    StoryWidgetBuilder<LoadingOverlayDemo, _LoadingOverlayInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? _LoadingOverlayInputArgs(),
         builder: builder ?? loadingOverlayDefaults.builder!,
       );
}

class _LoadingOverlayInputArgs extends StoryArgs<LoadingOverlayDemo> {
  _LoadingOverlayInputArgs({Arg<bool>? isLoading, Arg<String?>? message})
    : this.isLoadingArg = $initArg('isLoading', isLoading, BoolArg(false))!,
      this.messageArg = $initArg('message', message, NullableStringArg(null))!;

  _LoadingOverlayInputArgs.fixed({
    bool isLoading = false,
    String? message = null,
  }) : this.isLoadingArg = $initArg('isLoading', Arg.fixed(isLoading), null)!,
       this.messageArg = $initArg(
         'message',
         message == null ? null : Arg.fixed(message),
         null,
       );

  final Arg<bool> isLoadingArg;

  final Arg<String?>? messageArg;

  bool get isLoading => isLoadingArg.value;

  String? get message => messageArg?.value;

  @override
  List<Arg?> get list => [isLoadingArg, messageArg];
}
