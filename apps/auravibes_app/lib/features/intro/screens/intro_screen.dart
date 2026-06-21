// Required: Existing thresholds and limits use numeric values.
import 'dart:async';

import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_create_screen.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/usecases/create_workspace_use_case.dart';
import 'package:auravibes_app/features/workspaces/usecases/validate_workspace_name_use_case.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  final _workspaceNameController = TextEditingController();
  _IntroSlide _slide = _IntroSlide.welcome;
  WorkspaceEntity? _createdWorkspace;
  String? _workspaceErrorText;
  bool _isCreatingWorkspace = false;

  @override
  void dispose() {
    _workspaceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspaceErrorText = _workspaceErrorText;

    return AuraScreen(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProgressIndicator(activeSlide: _slide),
                  const Spacer(),
                  _SlideContent(
                    titleKey: _titleKey,
                    bodyKey: _bodyKey,
                  ),
                  if (_slide == _IntroSlide.workspaceName) ...[
                    const SizedBox(height: 24),
                    AuraInput(
                      controller: _workspaceNameController,
                      label: const TextLocale(
                        LocaleKeys.intro_flow_workspace_name_label,
                      ),
                      hint: const TextLocale(
                        LocaleKeys.intro_flow_workspace_name_helper,
                      ),
                      error: workspaceErrorText == null
                          ? null
                          : AuraText(child: Text(workspaceErrorText)),
                      isRequired: true,
                      state: workspaceErrorText == null
                          ? AuraInputState.normal
                          : AuraInputState.error,
                      textInputAction: TextInputAction.done,
                      autofocus: true,
                      onSubmitted: (_) => unawaited(_createWorkspace()),
                    ),
                  ],
                  const Spacer(),
                  _SlideActions(
                    slide: _slide,
                    isCreatingWorkspace: _isCreatingWorkspace,
                    onBack: _back,
                    onContinue: _continue,
                    onCreateWorkspace: () => unawaited(_createWorkspace()),
                    onConnectAi: _connectAi,
                    onSkipAi: _startChat,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      variant: AuraScreenVariation.aurora,
    );
  }

  String get _titleKey {
    return switch (_slide) {
      _IntroSlide.welcome => LocaleKeys.intro_flow_welcome_title,
      _IntroSlide.workspaceContext =>
        LocaleKeys.intro_flow_workspace_context_title,
      _IntroSlide.workspaceName => LocaleKeys.intro_flow_workspace_title,
      _IntroSlide.ready => LocaleKeys.intro_flow_ready_title,
    };
  }

  String get _bodyKey {
    return switch (_slide) {
      _IntroSlide.welcome => LocaleKeys.intro_flow_welcome_body,
      _IntroSlide.workspaceContext =>
        LocaleKeys.intro_flow_workspace_context_body,
      _IntroSlide.workspaceName => LocaleKeys.intro_flow_workspace_body,
      _IntroSlide.ready => LocaleKeys.intro_flow_ready_body,
    };
  }

  void _continue() {
    final next = _slide.next;
    if (next == null) return;
    setState(() => _slide = next);
  }

  void _back() {
    final previous = _slide.previous;
    if (previous == null) return;
    setState(() => _slide = previous);
  }

  Future<void> _createWorkspace() async {
    if (_isCreatingWorkspace) return;

    setState(() {
      _isCreatingWorkspace = true;
      _workspaceErrorText = null;
    });

    try {
      final usecase = ref.read(createWorkspaceUseCaseProvider);
      final createdWorkspace = await usecase.call(
        name: _workspaceNameController.text,
      );
      if (!mounted) return;
      ref.invalidate(allWorkspacesProvider);
      setState(() {
        _createdWorkspace = createdWorkspace;
        _slide = _IntroSlide.ready;
        _isCreatingWorkspace = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _workspaceErrorText = _workspaceErrorMessage(error);
        _isCreatingWorkspace = false;
      });

      return;
    }
  }

  String _workspaceErrorMessage(Object error) {
    if (error is WorkspaceException) {
      final localizationKey = error.localizationKey;
      if (localizationKey != null) {
        return localizationKey.tr(
          namedArgs: {
            'min': '${ValidateWorkspaceNameUseCase.minLength}',
            'max': '${ValidateWorkspaceNameUseCase.maxLength}',
          },
        );
      }

      return error.message;
    }

    return LocaleKeys.workspace_management_unexpected_error.tr();
  }

  void _connectAi() {
    final workspace = _createdWorkspace;
    if (workspace == null) return;

    context.go(
      _serviceConnectionCreateLocation(workspace.id),
    );
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
  workspaceName,
  ready;

  static const count = 4;

  _IntroSlide? get next {
    if (this == ready) return null;

    return values[index + 1];
  }

  _IntroSlide? get previous {
    if (this == welcome || this == ready) return null;

    return values[index - 1];
  }
}

String _newChatLocation(String workspaceId) {
  return NewChatRoute(workspaceId: workspaceId).location;
}

String _serviceConnectionCreateLocation(String workspaceId) {
  return '/workspaces/${Uri.encodeComponent(workspaceId)}/more/'
      'service-connections/new?type=${ServiceConnectionCreateType.modelProvider.name}';
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.activeSlide});

  final _IntroSlide activeSlide;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    return Row(
      children: [
        for (var index = 0; index < _IntroSlide.count; index++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == _IntroSlide.count - 1 ? 0 : 8,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: index <= activeSlide.index
                      ? auraColors.primary
                      : auraColors.surfaceVariant,
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

class _SlideContent extends StatelessWidget {
  const _SlideContent({
    required this.titleKey,
    required this.bodyKey,
  });

  final String titleKey;
  final String bodyKey;

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

class _SlideActions extends StatelessWidget {
  const _SlideActions({
    required this.slide,
    required this.isCreatingWorkspace,
    required this.onBack,
    required this.onContinue,
    required this.onCreateWorkspace,
    required this.onConnectAi,
    required this.onSkipAi,
  });

  final _IntroSlide slide;
  final bool isCreatingWorkspace;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onCreateWorkspace;
  final VoidCallback onConnectAi;
  final VoidCallback onSkipAi;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (slide == _IntroSlide.workspaceContext ||
            slide == _IntroSlide.workspaceName)
          Expanded(
            child: AuraButton(
              onPressed: onBack,
              child: const TextLocale(LocaleKeys.intro_flow_back),
              key: const Key('intro_back_button'),
              variant: AuraButtonVariant.outlined,
            ),
          ),
        if (slide == _IntroSlide.workspaceContext ||
            slide == _IntroSlide.workspaceName)
          const SizedBox(width: 8),
        Expanded(
          child: switch (slide) {
            _IntroSlide.workspaceName => AuraButton(
              onPressed: onCreateWorkspace,
              child: const TextLocale(
                LocaleKeys.intro_flow_workspace_create,
              ),
              key: const Key('intro_create_workspace_button'),
              isLoading: isCreatingWorkspace,
            ),
            _IntroSlide.ready => AuraButton(
              onPressed: onConnectAi,
              child: const TextLocale(LocaleKeys.intro_flow_connect_primary),
              key: const Key('intro_connect_ai_button'),
            ),
            _IntroSlide.welcome || _IntroSlide.workspaceContext => AuraButton(
              onPressed: onContinue,
              child: const TextLocale(LocaleKeys.intro_flow_continue),
              key: const Key('intro_continue_button'),
            ),
          },
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
