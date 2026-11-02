import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/workspace_agent_hook_settings.dart';
import 'package:auravibes_app/features/settings/models/workspace_agent_hook_config_review.dart';
import 'package:auravibes_app/features/settings/providers/workspace_agent_hook_settings_provider.dart';
import 'package:auravibes_app/features/settings/providers/workspace_agent_hook_settings_usecase_provider.dart';
import 'package:auravibes_app/features/settings/usecases/workspace_agent_hook_settings_usecase.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceAgentLifecycleHooksSection({
  required final String workspaceId,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<WorkspaceAgentLifecycleHooksSection> createState() =>
      _WorkspaceAgentLifecycleHooksSectionState();
}

class _WorkspaceAgentLifecycleHooksSectionState
    extends ConsumerState<WorkspaceAgentLifecycleHooksSection> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(
      workspaceAgentHookSettingsProvider(widget.workspaceId),
    );
    final trust = ref.watch(
      workspaceAgentHookTrustStatusProvider(widget.workspaceId),
    );

    return switch (settings) {
      AsyncData(:final value) => _WorkspaceHookSettingsView(
        settings: value,
        trustStatus: trust.value,
        busy: _busy,
        onChoose: _choosePressed,
        onReview: _reviewPressed,
        onRevoke: _revokePressed,
        onEnabled: _enabledChanged,
      ),
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncError() => _WorkspaceHookLoadFailure(onRetry: _retry),
    };
  }

  void _retry() {
    ref
      ..invalidate(workspaceAgentHookSettingsProvider(widget.workspaceId))
      ..invalidate(workspaceAgentHookTrustStatusProvider(widget.workspaceId));
  }

  void _choosePressed() => unawaited(_chooseConfig());
  void _reviewPressed(String path) => unawaited(_trustConfig(path));
  void _revokePressed() => unawaited(_revokeTrust());
  void _enabledChanged(bool enabled) => unawaited(_setEnabled(enabled));

  Future<void> _chooseConfig() async {
    await _runBusy(() async {
      final file = await FilePicker.pickFile(
        type: .custom,
        allowedExtensions: const ['json'],
      );
      if (file == null) return;
      final path = file.path;
      if (path == null) {
        _showMessage(
          const TextLocale('agent_lifecycle_hooks.file_unavailable'),
        );

        return;
      }

      await ref
          .read(workspaceAgentHookSettingsUsecaseProvider)
          .selectConfig(widget.workspaceId, path);
      _refresh();
    });
  }

  Future<void> _trustConfig(String path) async {
    await _runBusy(() async {
      final usecase = ref.read(workspaceAgentHookSettingsUsecaseProvider);
      final review = await usecase.reviewConfig(widget.workspaceId, path);
      if (!mounted) return;
      final shouldTrust = await _confirmTrust(review);
      if (shouldTrust != true || !mounted) return;

      await usecase.trustReviewedConfig(widget.workspaceId, review);
      _refresh();
    });
  }

  Future<bool?> _confirmTrust(WorkspaceAgentHookConfigReview review) =>
      AuraDialogs.confirm(
        context: context,
        title: const TextLocale('agent_lifecycle_hooks.trust_title'),
        message: AuraColumn(
          children: [
            const TextLocale('agent_lifecycle_hooks.trust_warning'),
            AuraSelectableText(review.canonicalPath),
            const TextLocale('agent_lifecycle_hooks.commands'),
            if (review.commands.isEmpty)
              const TextLocale('agent_lifecycle_hooks.no_hooks'),
            for (final command in review.commands)
              AuraColumn(
                children: [
                  TextLocale(
                    command.event == WorkspaceAgentHookEvent.beforeTool
                        ? 'agent_lifecycle_hooks.before_tool'
                        : 'agent_lifecycle_hooks.after_tool',
                  ),
                  AuraSelectableText(command.canonicalCommandPath),
                  const TextLocale('agent_lifecycle_hooks.arguments'),
                  AuraSelectableText(jsonEncode(command.arguments)),
                ],
                spacing: .xs,
                crossAxisAlignment: .start,
              ),
            if (review.sourceFiles.isNotEmpty) ...[
              const TextLocale('agent_lifecycle_hooks.source_files'),
              for (final sourceFile in review.sourceFiles)
                AuraSelectableText(sourceFile),
            ],
            AuraSelectableText(
              'agent_lifecycle_hooks.digest_value'.tr(args: [review.digest]),
            ),
          ],
          spacing: .sm,
          crossAxisAlignment: .start,
        ),
        actions: const AuraConfirmDialogActions(
          confirmLabel: TextLocale('agent_lifecycle_hooks.trust_confirm'),
          cancelLabel: TextLocale('settings_screen.actions.cancel'),
        ),
      );

  Future<void> _setEnabled(bool enabled) async {
    await _runBusy(() async {
      await ref
          .read(workspaceAgentHookSettingsUsecaseProvider)
          .setEnabled(widget.workspaceId, enabled: enabled);
      _refresh();
    });
  }

  Future<void> _revokeTrust() async {
    await _runBusy(() async {
      await ref
          .read(workspaceAgentHookSettingsUsecaseProvider)
          .revokeTrust(widget.workspaceId);
      _refresh();
    });
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on WorkspaceAgentHookSettingsException catch (error) {
      if (mounted) {
        _showMessage(
          _WorkspaceHookSettingsErrorText(
            localizationKey: error.localizationKey,
          ),
        );
      }
    } on Object {
      if (mounted) {
        _showMessage(const TextLocale('agent_lifecycle_hooks.error'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refresh() {
    ref
      ..invalidate(workspaceAgentHookSettingsProvider(widget.workspaceId))
      ..invalidate(workspaceAgentHookTrustStatusProvider(widget.workspaceId));
  }

  void _showMessage(Widget content) {
    if (!mounted) return;
    final _ = AuraSnackBars.show(
      context: context,
      content: content,
      variant: .error,
    );
  }
}

class const _WorkspaceHookSettingsView({
  required final WorkspaceAgentHookSettings settings,
  required final WorkspaceAgentHookTrustStatus? trustStatus,
  required final bool busy,
  required final VoidCallback onChoose,
  required final void Function(String) onReview,
  required final VoidCallback onRevoke,
  required final ValueChanged<bool> onEnabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final status = trustStatus ?? WorkspaceAgentHookTrustStatus.trustRequired;
    final isSupported =
        status != WorkspaceAgentHookTrustStatus.unsupportedPlatform &&
        status != WorkspaceAgentHookTrustStatus.unsupportedWorkspace;
    final canEnable = status == WorkspaceAgentHookTrustStatus.trusted;
    final digest = settings.trustedDigest;

    return AuraCard(
      child: AuraColumn(
        children: [
          const AuraText(
            child: TextLocale('agent_lifecycle_hooks.title'),
            style: .heading6,
          ),
          const AuraText(
            child: TextLocale('agent_lifecycle_hooks.description'),
            style: .bodySmall,
          ),
          AuraRow(
            children: [
              const Expanded(child: TextLocale('agent_lifecycle_hooks.enable')),
              AuraSwitch(
                value: settings.enabled,
                onChanged: busy || (!settings.enabled && !canEnable)
                    ? null
                    : onEnabled,
              ),
            ],
          ),
          AuraText(
            child: switch (status) {
              .notConfigured => const TextLocale(
                'agent_lifecycle_hooks.status_not_configured',
              ),
              .trustRequired => const TextLocale(
                'agent_lifecycle_hooks.status_trust_required',
              ),
              .trusted => const TextLocale(
                'agent_lifecycle_hooks.status_trusted',
              ),
              .changed => const TextLocale(
                'agent_lifecycle_hooks.status_changed',
              ),
              .invalid => const TextLocale(
                'agent_lifecycle_hooks.status_invalid',
              ),
              .unsupportedPlatform => const TextLocale(
                'agent_lifecycle_hooks.status_unsupported_platform',
              ),
              .unsupportedWorkspace => const TextLocale(
                'agent_lifecycle_hooks.status_unsupported_workspace',
              ),
            },
            style: .bodySmall,
          ),
          if (!isSupported)
            const AuraText(
              child: TextLocale('agent_lifecycle_hooks.recovery_local_desktop'),
              style: .bodySmall,
            ),
          if (settings.configPath case final String path) ...[
            AuraSelectableText(path),
            AuraText(
              child: TextLocale(
                'agent_lifecycle_hooks.trusted_digest',
                args: [
                  if (digest != null)
                    digest.characters.take(12).toString()
                  else
                    '',
                ],
              ),
              style: .bodySmall,
            ),
          ],
          Wrap(
            spacing: context.auraTheme.fromSpacing(.sm),
            runSpacing: context.auraTheme.fromSpacing(.sm),
            children: [
              AuraButton(
                onPressed: onChoose,
                child: const TextLocale('agent_lifecycle_hooks.choose_config'),
                disabled: busy || !isSupported,
              ),
              if (settings.configPath case final String path)
                AuraButton(
                  onPressed: () => onReview(path),
                  child: const TextLocale('agent_lifecycle_hooks.trust_config'),
                  disabled: busy || !isSupported,
                ),
              if (settings.isTrusted)
                AuraButton(
                  onPressed: onRevoke,
                  child: const TextLocale('agent_lifecycle_hooks.revoke_trust'),
                  disabled: busy,
                ),
            ],
          ),
        ],
        spacing: .md,
        crossAxisAlignment: .stretch,
      ),
    );
  }
}

class const _WorkspaceHookLoadFailure({required final VoidCallback onRetry})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const TextLocale('agent_lifecycle_hooks.load_error'),
      AuraButton(
        onPressed: onRetry,
        child: const TextLocale('agent_lifecycle_hooks.retry'),
      ),
    ],
  );
}

class const _WorkspaceHookSettingsErrorText({
  required final String localizationKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (localizationKey) {
    'agent_lifecycle_hooks.unsupported_platform' => const TextLocale(
      'agent_lifecycle_hooks.unsupported_platform',
    ),
    'agent_lifecycle_hooks.local_only' => const TextLocale(
      'agent_lifecycle_hooks.local_only',
    ),
    'agent_lifecycle_hooks.configuration_changed' => const TextLocale(
      'agent_lifecycle_hooks.configuration_changed',
    ),
    'agent_lifecycle_hooks.invalid_configuration' => const TextLocale(
      'agent_lifecycle_hooks.invalid_configuration',
    ),
    'agent_lifecycle_hooks.trust_required' => const TextLocale(
      'agent_lifecycle_hooks.trust_required',
    ),
    _ => const TextLocale('agent_lifecycle_hooks.error'),
  };
}
