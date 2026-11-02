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
      AsyncData(:final value) => _section(context, value, trust.value),
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncError() => _loadFailure(),
    };
  }

  Widget _section(
    BuildContext context,
    WorkspaceAgentHookSettings settings,
    WorkspaceAgentHookTrustStatus? trustStatus,
  ) {
    final status = trustStatus ?? WorkspaceAgentHookTrustStatus.trustRequired;
    final isSupported =
        status != WorkspaceAgentHookTrustStatus.unsupportedPlatform &&
        status != WorkspaceAgentHookTrustStatus.unsupportedWorkspace;
    final canEnable = status == WorkspaceAgentHookTrustStatus.trusted;
    final trustKey = _trustStatusKey(status);
    final digest = settings.trustedDigest;

    return AuraCard(
      child: AuraColumn(
        children: [
          AuraText(
            child: const TextLocale('agent_lifecycle_hooks.title'),
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
                onChanged: _busy || (!settings.enabled && !canEnable)
                    ? null
                    : (enabled) => _setEnabled(enabled),
              ),
            ],
          ),
          AuraText(child: TextLocale(trustKey), style: .bodySmall),
          if (settings.configPath case final String path) ...[
            AuraSelectableText(path),
            AuraText(
              child: TextLocale(
                'agent_lifecycle_hooks.trusted_digest',
                args: [
                  digest == null
                      ? ''
                      : digest.substring(0, digest.length < 12 ? digest.length : 12),
                ],
              ),
              style: .bodySmall,
            ),
          ],
          AuraRow(
            children: [
              AuraButton(
                disabled: _busy || !isSupported,
                onPressed: _chooseConfig,
                child: const TextLocale('agent_lifecycle_hooks.choose_config'),
              ),
              if (settings.configPath != null)
                AuraButton(
                  disabled: _busy || !isSupported,
                  onPressed: () => _trustConfig(settings.configPath!),
                  child: const TextLocale('agent_lifecycle_hooks.trust_config'),
                ),
              if (settings.isTrusted)
                AuraButton(
                  disabled: _busy,
                  onPressed: _revokeTrust,
                  child: const TextLocale('agent_lifecycle_hooks.revoke_trust'),
                ),
            ],
          ),
        ],
        spacing: .md,
        crossAxisAlignment: .stretch,
      ),
    );
  }

  Widget _loadFailure() => AuraColumn(
    children: [
      const TextLocale('agent_lifecycle_hooks.load_error'),
      AuraButton(
        onPressed: () {
          ref.invalidate(
            workspaceAgentHookSettingsProvider(widget.workspaceId),
          );
          ref.invalidate(
            workspaceAgentHookTrustStatusProvider(widget.workspaceId),
          );
        },
        child: const TextLocale('agent_lifecycle_hooks.retry'),
      ),
    ],
  );

  Future<void> _chooseConfig() async {
    await _runBusy(() async {
      final file = await FilePicker.pickFile(
        type: .custom,
        allowedExtensions: const ['json'],
      );
      if (file == null) return;
      final path = file.path;
      if (path == null) {
        _showMessage('agent_lifecycle_hooks.file_unavailable');

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
                crossAxisAlignment: .start,
                spacing: .xs,
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
      if (mounted) _showMessage(error.localizationKey);
    } on Object {
      if (mounted) _showMessage('agent_lifecycle_hooks.error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refresh() {
    ref.invalidate(workspaceAgentHookSettingsProvider(widget.workspaceId));
    ref.invalidate(workspaceAgentHookTrustStatusProvider(widget.workspaceId));
  }

  void _showMessage(String key) {
    if (!mounted) return;
    final _ = AuraSnackBars.show(
      context: context,
      content: TextLocale(key),
      variant: .error,
    );
  }
}

String _trustStatusKey(
  WorkspaceAgentHookTrustStatus status,
) => switch (status) {
  .notConfigured => 'agent_lifecycle_hooks.status_not_configured',
  .trustRequired => 'agent_lifecycle_hooks.status_trust_required',
  .trusted => 'agent_lifecycle_hooks.status_trusted',
  .changed => 'agent_lifecycle_hooks.status_changed',
  .invalid => 'agent_lifecycle_hooks.status_invalid',
  .unsupportedPlatform => 'agent_lifecycle_hooks.status_unsupported_platform',
  .unsupportedWorkspace => 'agent_lifecycle_hooks.status_unsupported_workspace',
};
