import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_create_screen.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/screens/create_workspace_screen.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const IntroScreen({super.key}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  static const _slideButtonSpacing = 8.0;
  _IntroSlide _slide = .welcome;
  WorkspaceEntity? _createdWorkspace;

  String get _titleKey => switch (_slide) {
    .welcome => LocaleKeys.intro_flow_welcome_title,
    .workspaceContext => LocaleKeys.intro_flow_workspace_context_title,
    .workspaceChoice => LocaleKeys.intro_flow_choice_title,
    .ready => LocaleKeys.intro_flow_ready_title,
  };

  String get _bodyKey => switch (_slide) {
    .welcome => LocaleKeys.intro_flow_welcome_body,
    .workspaceContext => LocaleKeys.intro_flow_workspace_context_body,
    .workspaceChoice => LocaleKeys.intro_flow_choice_body,
    .ready => LocaleKeys.intro_flow_ready_body,
  };

  WorkspaceEntity? get _existingWorkspace =>
      switch (ref.watch(allWorkspacesProvider)) {
        AsyncData(:final value) => value.firstOrNull,
        AsyncLoading() || AsyncError() => null,
      };

  @override
  Widget build(BuildContext context) {
    _redirectIfExistingWorkspace();

    return _IntroFrame(this);
  }

  void _continue() {
    final next = _slide.next;
    if (next != null) setState(() => _slide = next);
  }

  void _back() {
    final previous = _slide.previous;
    if (previous != null) setState(() => _slide = previous);
  }

  void _workspaceCreated(WorkspaceEntity workspace) {
    setState(() {
      _createdWorkspace = workspace;
      _slide = .ready;
    });
  }
}

extension on _IntroScreenState {
  void _redirectIfExistingWorkspace() {
    if (_slide != _IntroSlide.workspaceChoice) return;
    final workspace = _existingWorkspace;
    if (workspace == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(_newChatLocation(workspace.id));
    });
  }

  void _connectAi() {
    final workspace = _createdWorkspace;
    if (workspace == null) return;
    context.go(_serviceConnectionCreateLocation(workspace.id));
  }

  void _startChat() {
    final workspace = _createdWorkspace;
    if (workspace == null) return;
    context.go(_newChatLocation(workspace.id));
  }
}

class _IntroFrame extends StatelessWidget {
  new(_IntroScreenState state)
    : _content = _IntroContent(
        slide: state._slide,
        titleKey: state._titleKey,
        bodyKey: state._bodyKey,
        onCreated: state._workspaceCreated,
        onBack: state._back,
        onContinue: state._continue,
        onConnectAi: state._connectAi,
        onSkipAi: state._startChat,
      );

  final _IntroContent _content;

  @override
  Widget build(BuildContext context) =>
      AuraScreen(child: _content, variant: .aurora);
}

class const _IntroContent({
  required final _IntroSlide slide,
  required final String titleKey,
  required final String bodyKey,
  required final ValueChanged<WorkspaceEntity> onCreated,
  required final VoidCallback onBack,
  required final VoidCallback onContinue,
  required final VoidCallback onConnectAi,
  required final VoidCallback onSkipAi,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SafeArea(
    child: _IntroContentContainer(
      slide: slide,
      titleKey: titleKey,
      bodyKey: bodyKey,
      onCreated: onCreated,
      onBack: onBack,
      onContinue: onContinue,
      onConnectAi: onConnectAi,
      onSkipAi: onSkipAi,
    ),
  );
}

class const _IntroContentContainer({
  required final _IntroSlide slide,
  required final String titleKey,
  required final String bodyKey,
  required final ValueChanged<WorkspaceEntity> onCreated,
  required final VoidCallback onBack,
  required final VoidCallback onContinue,
  required final VoidCallback onConnectAi,
  required final VoidCallback onSkipAi,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _IntroContentLayout(content: this);
}

class const _IntroContentLayout({required final _IntroContentContainer content})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: _IntroContentList(content: content),
    ),
  );
}

class _IntroContentList extends StatelessWidget {
  new({required _IntroContentContainer content})
    : _children = [
        _ProgressIndicator(activeSlide: content.slide),
        const SizedBox(height: 32),
        _SlideContent(titleKey: content.titleKey, bodyKey: content.bodyKey),
        if (content.slide == _IntroSlide.workspaceChoice) ...[
          const SizedBox(height: 24),
          CreateWorkspaceForm(onCreated: content.onCreated),
        ],
        const SizedBox(height: 32),
        _SlideActions(
          slide: content.slide,
          onBack: content.onBack,
          onContinue: content.onContinue,
          onConnectAi: content.onConnectAi,
          onSkipAi: content.onSkipAi,
        ),
      ];

  final List<Widget> _children;

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(24), children: _children);
}

enum _IntroSlide {
  welcome,
  workspaceContext,
  workspaceChoice,
  ready;

  _IntroSlide? get next => this == ready ? null : values[index + 1];

  _IntroSlide? get previous => this == welcome ? null : values[index - 1];
}

String _newChatLocation(String workspaceId) {
  return NewChatRoute(workspaceId: workspaceId).location;
}

String _serviceConnectionCreateLocation(String workspaceId) {
  return '/workspaces/${Uri.encodeComponent(workspaceId)}/more/'
      'service-connections/new?type=${ServiceConnectionCreateType.modelProvider.name}';
}

class const _ProgressIndicator({required final _IntroSlide activeSlide})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;

    return Row(
      children: [
        for (var index = 0; index < _IntroSlide.values.length; index++)
          _ProgressStep(
            index: index,
            activeSlide: activeSlide,
            activeColor: colors.primary,
            inactiveColor: colors.outlineVariant,
          ),
      ],
    );
  }
}

class const _ProgressStep({
  required final int index,
  required final _IntroSlide activeSlide,
  required final Color activeColor,
  required final Color inactiveColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    child: _ProgressStepPadding(
      index: index,
      activeSlide: activeSlide,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
    ),
  );
}

class const _ProgressStepPadding({
  required final int index,
  required final _IntroSlide activeSlide,
  required final Color activeColor,
  required final Color inactiveColor,
}) extends StatelessWidget {
  EdgeInsets get _padding => EdgeInsets.only(
    right: index == _IntroSlide.values.length - 1
        ? 0
        : _IntroScreenState._slideButtonSpacing,
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: _padding,
    child: _ProgressStepDecorated(
      index: index,
      activeSlide: activeSlide,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
    ),
  );
}

class const _ProgressStepDecorated({
  required final int index,
  required final _IntroSlide activeSlide,
  required final Color activeColor,
  required final Color inactiveColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: ValueKey('intro_progress_step_$index'),
    decoration: BoxDecoration(
      color: index <= activeSlide.index ? activeColor : inactiveColor,
      borderRadius: const BorderRadius.all(.circular(4)),
    ),
    child: const SizedBox(height: 4),
  );
}

class const _SlideContent({
  required final String titleKey,
  required final String bodyKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        AuraText(child: TextLocale(titleKey), style: .heading3),
        const SizedBox(height: 12),
        AuraText(child: TextLocale(bodyKey), style: .bodyLarge),
      ],
    );
  }
}

class const _SlideActions({
  required final _IntroSlide slide,
  required final VoidCallback onBack,
  required final VoidCallback onContinue,
  required final VoidCallback onConnectAi,
  required final VoidCallback onSkipAi,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (slide == _IntroSlide.workspaceChoice) return const SizedBox.shrink();

    return _SlideActionRow(
      slide: slide,
      onBack: onBack,
      onContinue: onContinue,
      onConnectAi: onConnectAi,
      onSkipAi: onSkipAi,
    );
  }
}

class const _SlideActionRow({
  required final _IntroSlide slide,
  required final VoidCallback onBack,
  required final VoidCallback onContinue,
  required final VoidCallback onConnectAi,
  required final VoidCallback onSkipAi,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SlideActionButtons(
    slide: slide,
    onBack: onBack,
    onContinue: onContinue,
    onConnectAi: onConnectAi,
    onSkipAi: onSkipAi,
  );
}

class _SlideActionButtons extends StatelessWidget {
  new({
    required this.slide,
    required this.onBack,
    required this.onContinue,
    required this.onConnectAi,
    required this.onSkipAi,
  }) : _children = [
         if (slide == _IntroSlide.workspaceContext) ...[
           _SlideActionButton(
             onPressed: onBack,
             label: LocaleKeys.intro_flow_back,
             outlined: true,
             key: const Key('intro_back_button'),
           ),
           const SizedBox(width: 8),
         ],
         _SlideActionButton(
           onPressed: slide == _IntroSlide.ready ? onConnectAi : onContinue,
           label: slide == _IntroSlide.ready
               ? LocaleKeys.intro_flow_connect_primary
               : LocaleKeys.intro_flow_continue,
           key: .new(
             slide == _IntroSlide.ready
                 ? 'intro_connect_ai_button'
                 : 'intro_continue_button',
           ),
         ),
         if (slide == _IntroSlide.ready) ...[
           const SizedBox(width: 8),
           _SlideActionButton(
             onPressed: onSkipAi,
             label: LocaleKeys.intro_flow_connect_skip,
             outlined: true,
             key: const Key('intro_skip_ai_button'),
           ),
         ],
       ];

  final _IntroSlide slide;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onConnectAi;
  final VoidCallback onSkipAi;
  final List<Widget> _children;

  @override
  Widget build(BuildContext context) => Row(children: _children);
}

class const _SlideActionButton({
  required final VoidCallback onPressed,
  required final String label,
  final bool outlined = false,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    child: AuraButton(
      onPressed: onPressed,
      child: TextLocale(label),
      variant: outlined ? .outlined : .primary,
    ),
  );
}
