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

    return _workspaceHookSectionContent((
      settings: settings,
      trust: trust.value,
      state: this,
    ));
  }

  void _retry() {
    ref
      ..invalidate(workspaceAgentHookSettingsProvider(widget.workspaceId))
      ..invalidate(workspaceAgentHookTrustStatusProvider(widget.workspaceId));
  }

  Future<void> _chooseConfig() async {
    await _runBusy(() async {
      final path = await _chooseConfigPath();
      if (path == null) return;
      await ref
          .read(workspaceAgentHookSettingsUsecaseProvider)
          .selectConfig(widget.workspaceId, path);
      _retry();
    });
  }

  Future<void> _trustConfig(String path) async {
    await _runBusy(() => _reviewAndTrust(path));
  }

  Future<String?> _chooseConfigPath() async {
    final file = await FilePicker.pickFile(
      type: .custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    final path = file.path;
    if (path == null) {
      _showHookMessage(
        context,
        mounted,
        const TextLocale('agent_lifecycle_hooks.file_unavailable'),
      );
    }

    return path;
  }

  Future<void> _reviewAndTrust(String path) async {
    final usecase = ref.read(workspaceAgentHookSettingsUsecaseProvider);
    final review = await usecase.reviewConfig(widget.workspaceId, path);
    if (!mounted) return;
    await _confirmAndPersistTrust(usecase, review);
  }

  Future<void> _confirmAndPersistTrust(
    WorkspaceAgentHookSettingsUsecase usecase,
    WorkspaceAgentHookConfigReview review,
  ) async {
    final shouldTrust = await _confirmHookTrust(context, review);
    if (shouldTrust != true || !mounted) return;

    await usecase.trustReviewedConfig(widget.workspaceId, review);
    _retry();
  }

  Future<void> _runSettingsMutation(
    Future<void> Function(WorkspaceAgentHookSettingsUsecase) action,
  ) => _runBusy(
    () => action(ref.read(workspaceAgentHookSettingsUsecaseProvider))
      ..then((_) => _retry()),
  );

  Future<void> _setEnabled(bool enabled) => _runSettingsMutation(
    (usecase) => usecase.setEnabled(widget.workspaceId, enabled: enabled),
  );

  Future<void> _revokeTrust() => _runSettingsMutation(
    (usecase) => usecase.revokeTrust(widget.workspaceId),
  );

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on WorkspaceAgentHookSettingsException catch (error) {
      if (mounted) {
        _showHookMessage(
          context,
          mounted,
          _WorkspaceHookSettingsErrorText(
            localizationKey: error.localizationKey,
          ),
        );
      }
    } on Object {
      if (mounted) {
        _showHookMessage(
          context,
          mounted,
          const TextLocale('agent_lifecycle_hooks.error'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

}

typedef _WorkspaceHookSectionContentRequest = ({
  AsyncValue<WorkspaceAgentHookSettings> settings,
  WorkspaceAgentHookTrustStatus? trust,
  _WorkspaceAgentLifecycleHooksSectionState state,
});

Widget _workspaceHookSectionContent(
  _WorkspaceHookSectionContentRequest request,
) => switch (request.settings) {
  AsyncData(:final value) => _workspaceHookReadyContent(
    value,
    request.trust,
    request.state,
  ),
  AsyncLoading() => const Center(child: AuraSpinner()),
  AsyncError() => _WorkspaceHookLoadFailure(onRetry: request.state._retry),
};

Widget _workspaceHookReadyContent(
  WorkspaceAgentHookSettings settings,
  WorkspaceAgentHookTrustStatus? trust,
  _WorkspaceAgentLifecycleHooksSectionState state,
) => _WorkspaceHookSettingsView(
  settings: settings,
  trustStatus: trust,
  busy: state._busy,
  onChoose: state._chooseConfig,
  onReview: state._trustConfig,
  onRevoke: state._revokeTrust,
  onEnabled: state._setEnabled,
);

Future<bool?> _confirmHookTrust(
  BuildContext context,
  WorkspaceAgentHookConfigReview review,
) => AuraDialogs.confirm(
  context: context,
  title: const TextLocale('agent_lifecycle_hooks.trust_title'),
  message: _WorkspaceHookReviewBody(review: review),
  actions: const AuraConfirmDialogActions(
    confirmLabel: TextLocale('agent_lifecycle_hooks.trust_confirm'),
    cancelLabel: TextLocale('settings_screen.actions.cancel'),
  ),
);

void _showHookMessage(BuildContext context, bool mounted, Widget content) {
  if (!mounted) return;
  final _ = AuraSnackBars.show(
    context: context,
    content: content,
    variant: .error,
  );
}

class const _WorkspaceHookReviewBody({
  required final WorkspaceAgentHookConfigReview review,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: _reviewChildren(),
    spacing: .sm,
    crossAxisAlignment: .start,
  );

  List<Widget> _reviewChildren() => [
    ..._reviewSummary(),
    ..._commandWidgets(),
    ..._sourceFileWidgets(),
    _digestWidget(),
  ];

  List<Widget> _reviewSummary() => [
      const TextLocale('agent_lifecycle_hooks.trust_warning'),
      AuraSelectableText(review.canonicalPath),
      const TextLocale('agent_lifecycle_hooks.commands'),
      if (review.commands.isEmpty)
        const TextLocale('agent_lifecycle_hooks.no_hooks'),
  ];

  List<Widget> _commandWidgets() => [
    for (final command in review.commands)
      _WorkspaceHookCommandDetails(command: command),
  ];

  List<Widget> _sourceFileWidgets() => review.sourceFiles.isEmpty
      ? const []
      : [
        const TextLocale('agent_lifecycle_hooks.source_files'),
        for (final sourceFile in review.sourceFiles)
          AuraSelectableText(sourceFile),
      ];

  Widget _digestWidget() => AuraSelectableText(
    'agent_lifecycle_hooks.digest_value'.tr(args: [review.digest]),
  );
}

class const _WorkspaceHookCommandDetails({
  required final WorkspaceAgentHookCommandReview command,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
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
  );
}

const _statusLabels = <WorkspaceAgentHookTrustStatus, TextLocale>{
  .notConfigured: TextLocale('agent_lifecycle_hooks.status_not_configured'),
  .trustRequired: TextLocale('agent_lifecycle_hooks.status_trust_required'),
  .trusted: TextLocale('agent_lifecycle_hooks.status_trusted'),
  .changed: TextLocale('agent_lifecycle_hooks.status_changed'),
  .invalid: TextLocale('agent_lifecycle_hooks.status_invalid'),
  .unsupportedPlatform: TextLocale(
    'agent_lifecycle_hooks.status_unsupported_platform',
  ),
  .unsupportedWorkspace: TextLocale(
    'agent_lifecycle_hooks.status_unsupported_workspace',
  ),
};
const _trustedDigestPreviewLength = 12;

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
    final isSupported = _isSupportedStatus(status);

    return AuraCard(
      child: AuraColumn(
        children: _settingsChildren(status, isSupported),
        spacing: .md,
        crossAxisAlignment: .stretch,
      ),
    );
  }

  bool _isSupportedStatus(WorkspaceAgentHookTrustStatus status) =>
      status != WorkspaceAgentHookTrustStatus.unsupportedPlatform &&
      status != WorkspaceAgentHookTrustStatus.unsupportedWorkspace;

  List<Widget> _settingsChildren(
    WorkspaceAgentHookTrustStatus status,
    bool isSupported,
  ) => [
    ..._primarySettingsChildren(status, isSupported),
    ..._configuredPathChildren(),
    _WorkspaceHookActions(view: this, isSupported: isSupported),
  ];

  List<Widget> _primarySettingsChildren(
    WorkspaceAgentHookTrustStatus status,
    bool isSupported,
  ) => [
    const _WorkspaceHookTitle(),
    const _WorkspaceHookDescription(),
    _WorkspaceHookToggle(view: this, status: status),
    _WorkspaceHookStatus(status: status),
    if (!isSupported) const _WorkspaceHookRecovery(),
  ];

  List<Widget> _configuredPathChildren() {
    final path = settings.configPath;
    if (path == null) return const [];

    return [
      AuraSelectableText(path),
      _WorkspaceHookTrustedDigest(digest: settings.trustedDigest),
    ];
  }
}

class const _WorkspaceHookTitle() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale('agent_lifecycle_hooks.title'),
    style: .heading6,
  );
}

class const _WorkspaceHookDescription() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale('agent_lifecycle_hooks.description'),
    style: .bodySmall,
  );
}

class const _WorkspaceHookToggle({
  required final _WorkspaceHookSettingsView view,
  required final WorkspaceAgentHookTrustStatus status,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final enabled = view.settings.enabled;
    final canEnable = status == WorkspaceAgentHookTrustStatus.trusted;

    return AuraRow(
      children: [
        const Expanded(child: TextLocale('agent_lifecycle_hooks.enable')),
        AuraSwitch(
          value: enabled,
          onChanged: view.busy || (!enabled && !canEnable)
              ? null
              : view.onEnabled,
        ),
      ],
    );
  }
}

class const _WorkspaceHookRecovery() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraText(
    child: TextLocale('agent_lifecycle_hooks.recovery_local_desktop'),
    style: .bodySmall,
  );
}

class const _WorkspaceHookStatus({
  required final WorkspaceAgentHookTrustStatus status,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child:
        _statusLabels[status] ??
        const TextLocale('agent_lifecycle_hooks.status_trust_required'),
    style: .bodySmall,
  );
}

class const _WorkspaceHookTrustedDigest({required final String? digest})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final value = digest;

    return AuraText(
      child: TextLocale(
        'agent_lifecycle_hooks.trusted_digest',
        args: [
          if (value != null)
            value.characters.take(_trustedDigestPreviewLength).toString()
          else
            '',
        ],
      ),
      style: .bodySmall,
    );
  }
}

class const _WorkspaceHookActions({
  required final _WorkspaceHookSettingsView view,
  required final bool isSupported,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = view.settings;
    final disabled = view.busy || !isSupported;

    return Wrap(
      spacing: context.auraTheme.fromSpacing(.sm),
      runSpacing: context.auraTheme.fromSpacing(.sm),
      children: _actionChildren(settings, disabled),
    );
  }

  List<Widget> _actionChildren(
    WorkspaceAgentHookSettings settings,
    bool disabled,
  ) => [
    _WorkspaceHookChooseAction(onPressed: view.onChoose, disabled: disabled),
    if (settings.configPath case final String path)
      _WorkspaceHookReviewAction(
        path: path,
        onReview: view.onReview,
        disabled: disabled,
      ),
    if (settings.isTrusted)
      _WorkspaceHookRevokeAction(
        onPressed: view.onRevoke,
        disabled: view.busy,
      ),
  ];
}

class const _WorkspaceHookChooseAction({
  required final VoidCallback onPressed,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale('agent_lifecycle_hooks.choose_config'),
    disabled: disabled,
  );
}

class const _WorkspaceHookReviewAction({
  required final String path,
  required final void Function(String) onReview,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => onReview(path),
    child: const TextLocale('agent_lifecycle_hooks.trust_config'),
    disabled: disabled,
  );
}

class const _WorkspaceHookRevokeAction({
  required final VoidCallback onPressed,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale('agent_lifecycle_hooks.revoke_trust'),
    disabled: disabled,
  );
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
