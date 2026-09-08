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
  _IntroSlide _slide = _IntroSlide.welcome;
  WorkspaceEntity? _createdWorkspace;

  String get _titleKey => switch (_slide) {
    _IntroSlide.welcome => LocaleKeys.intro_flow_welcome_title,
    _IntroSlide.workspaceContext =>
      LocaleKeys.intro_flow_workspace_context_title,
    _IntroSlide.workspaceChoice => LocaleKeys.intro_flow_choice_title,
    _IntroSlide.ready => LocaleKeys.intro_flow_ready_title,
  };

  String get _bodyKey => switch (_slide) {
    _IntroSlide.welcome => LocaleKeys.intro_flow_welcome_body,
    _IntroSlide.workspaceContext =>
      LocaleKeys.intro_flow_workspace_context_body,
    _IntroSlide.workspaceChoice => LocaleKeys.intro_flow_choice_body,
    _IntroSlide.ready => LocaleKeys.intro_flow_ready_body,
  };

  @override
  Widget build(BuildContext context) {
    if (_slide == _IntroSlide.workspaceChoice) {
      final existing = switch (ref.watch(allWorkspacesProvider)) {
        AsyncData(:final value) => value.firstOrNull,
        _ => null,
      };
      if (existing != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(_newChatLocation(existing.id));
        });
      }
    }

    return AuraScreen(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _ProgressIndicator(activeSlide: _slide),
                const SizedBox(height: 32),
                _SlideContent(titleKey: _titleKey, bodyKey: _bodyKey),
                if (_slide == _IntroSlide.workspaceChoice) ...[
                  const SizedBox(height: 24),
                  CreateWorkspaceForm(onCreated: _workspaceCreated),
                ],
                const SizedBox(height: 32),
                _SlideActions(
                  slide: _slide,
                  onBack: _back,
                  onContinue: _continue,
                  onConnectAi: _connectAi,
                  onSkipAi: _startChat,
                ),
              ],
            ),
          ),
        ),
      ),
      variant: AuraScreenVariation.aurora,
    );
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
      _slide = _IntroSlide.ready;
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
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == _IntroSlide.values.length - 1
                    ? 0
                    : _IntroScreenState._slideButtonSpacing,
              ),
              child: DecoratedBox(
                key: ValueKey('intro_progress_step_$index'),
                decoration: BoxDecoration(
                  color: index <= activeSlide.index
                      ? colors.primary
                      : colors.outlineVariant,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                child: const SizedBox(height: 4),
              ),
            ),
          ),
      ],
    );
  }
}

class const _SlideContent({
  required final String titleKey,
  required final String bodyKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuraText(child: TextLocale(titleKey), style: AuraTextStyle.heading3),
        const SizedBox(height: 12),
        AuraText(child: TextLocale(bodyKey), style: AuraTextStyle.bodyLarge),
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

    return Row(
      children: [
        if (slide == _IntroSlide.workspaceContext) ...[
          Expanded(
            child: AuraButton(
              onPressed: onBack,
              child: const TextLocale(LocaleKeys.intro_flow_back),
              key: const Key('intro_back_button'),
              variant: AuraButtonVariant.outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: AuraButton(
            onPressed: slide == _IntroSlide.ready ? onConnectAi : onContinue,
            child: TextLocale(
              slide == _IntroSlide.ready
                  ? LocaleKeys.intro_flow_connect_primary
                  : LocaleKeys.intro_flow_continue,
            ),
            key: Key(
              slide == _IntroSlide.ready
                  ? 'intro_connect_ai_button'
                  : 'intro_continue_button',
            ),
          ),
        ),
        if (slide == _IntroSlide.ready) ...[
          const SizedBox(width: 8),
          Expanded(
            child: AuraButton(
              onPressed: onSkipAi,
              child: const TextLocale(LocaleKeys.intro_flow_connect_skip),
              key: const Key('intro_skip_ai_button'),
              variant: AuraButtonVariant.outlined,
            ),
          ),
        ],
      ],
    );
  }
}
