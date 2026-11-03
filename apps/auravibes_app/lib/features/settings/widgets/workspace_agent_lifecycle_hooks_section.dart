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

    return _WorkspaceHookSectionContent(
      request: (settings: settings, trust: trust.value, state: this),
    );
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
    if (!mounted) return null;
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

  Future<void> _setEnabled(bool enabled) => _runHookSettingsMutation(
    this,
    (usecase) => usecase.setEnabled(widget.workspaceId, enabled: enabled),
  );

  Future<void> _revokeTrust() => _runHookSettingsMutation(
    this,
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
typedef _WorkspaceHookActionCallbacks = ({
  VoidCallback choose,
  void Function(String) review,
  VoidCallback revoke,
  ValueChanged<bool> setEnabled,
});

class const _WorkspaceHookSectionContent({
  required final _WorkspaceHookSectionContentRequest request,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (request.settings) {
    AsyncData(:final value) => _WorkspaceHookReadyContent(
      settings: value,
      trust: request.trust,
      state: request.state,
    ),
    AsyncLoading() => const Center(child: AuraSpinner()),
    AsyncError() => _WorkspaceHookLoadFailure(onRetry: request.state._retry),
  };
}

class const _WorkspaceHookReadyContent({
  required final WorkspaceAgentHookSettings settings,
  required final WorkspaceAgentHookTrustStatus? trust,
  required final _WorkspaceAgentLifecycleHooksSectionState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _WorkspaceHookSettingsView(
    settings: settings,
    trustStatus: trust,
    busy: state._busy,
    callbacks: _workspaceHookCallbacks(state),
  );
}

_WorkspaceHookActionCallbacks _workspaceHookCallbacks(
  _WorkspaceAgentLifecycleHooksSectionState state,
) => (
  choose: () => unawaited(state._chooseConfig()),
  review: (path) => unawaited(state._trustConfig(path)),
  revoke: () => unawaited(state._revokeTrust()),
  setEnabled: (enabled) => unawaited(state._setEnabled(enabled)),
);

Future<void> _runHookSettingsMutation(
  _WorkspaceAgentLifecycleHooksSectionState state,
  Future<void> Function(WorkspaceAgentHookSettingsUsecase) action,
) => state._runBusy(() async {
  await action(state.ref.read(workspaceAgentHookSettingsUsecaseProvider));
  if (state.mounted) state._retry();
});

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
  Widget build(BuildContext context) {
    final digest = 'agent_lifecycle_hooks.digest_value'.tr(
      args: [review.digest],
    );
    final sourceFiles = review.sourceFiles;
    final children = <Widget>[];
    _appendChildren(children, review, sourceFiles, digest);

    return AuraColumn(
      children: children,
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }

  static void _appendChildren(
    List<Widget> children,
    WorkspaceAgentHookConfigReview review,
    List<String> sourceFiles,
    String digest,
  ) {
    _appendSummary(children, review);
    _appendCommands(children, review.commands);
    _appendSourceFiles(children, sourceFiles);
    children.add(AuraSelectableText(digest));
  }

  static void _appendSummary(
    List<Widget> children,
    WorkspaceAgentHookConfigReview review,
  ) {
    children
      ..add(const TextLocale('agent_lifecycle_hooks.trust_warning'))
      ..add(AuraSelectableText(review.canonicalPath))
      ..add(const TextLocale('agent_lifecycle_hooks.commands'));
    if (review.commands.isEmpty) {
      children.add(const TextLocale('agent_lifecycle_hooks.no_hooks'));
    }
  }

  static void _appendCommands(
    List<Widget> children,
    List<WorkspaceAgentHookCommandReview> commands,
  ) {
    for (final command in commands) {
      children.add(_WorkspaceHookCommandDetails(command: command));
    }
  }

  static void _appendSourceFiles(
    List<Widget> children,
    List<String> sourceFiles,
  ) {
    if (sourceFiles.isEmpty) return;
    children.add(const TextLocale('agent_lifecycle_hooks.source_files'));
    for (final sourceFile in sourceFiles) {
      children.add(AuraSelectableText(sourceFile));
    }
  }
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
  required final _WorkspaceHookActionCallbacks callbacks,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final status = trustStatus ?? WorkspaceAgentHookTrustStatus.trustRequired;
    final isSupported = _isSupportedStatus(status);

    return AuraCard(
      child: _WorkspaceHookSettingsColumn(
        view: this,
        status: status,
        isSupported: isSupported,
      ),
    );
  }

  bool _isSupportedStatus(WorkspaceAgentHookTrustStatus status) =>
      status != WorkspaceAgentHookTrustStatus.unsupportedPlatform &&
      status != WorkspaceAgentHookTrustStatus.unsupportedWorkspace;
}

class const _WorkspaceHookSettingsColumn({
  required final _WorkspaceHookSettingsView view,
  required final WorkspaceAgentHookTrustStatus status,
  required final bool isSupported,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    _appendChildren(children, view, status, isSupported);

    return AuraColumn(
      children: children,
      spacing: .md,
      crossAxisAlignment: .stretch,
    );
  }

  static void _appendChildren(
    List<Widget> children,
    _WorkspaceHookSettingsView view,
    WorkspaceAgentHookTrustStatus status,
    bool isSupported,
  ) {
    _appendHeaderChildren(children, view, status, isSupported);
    _appendConfiguredPathChildren(children, view.settings);
    children.add(_WorkspaceHookActions(view: view, isSupported: isSupported));
  }

  static void _appendHeaderChildren(
    List<Widget> children,
    _WorkspaceHookSettingsView view,
    WorkspaceAgentHookTrustStatus status,
    bool isSupported,
  ) {
    children
      ..add(const _WorkspaceHookTitle())
      ..add(const _WorkspaceHookDescription())
      ..add(_WorkspaceHookToggle(view: view, status: status))
      ..add(_WorkspaceHookStatus(status: status));
    if (!isSupported) children.add(const _WorkspaceHookRecovery());
  }

  static void _appendConfiguredPathChildren(
    List<Widget> children,
    WorkspaceAgentHookSettings settings,
  ) {
    final path = settings.configPath;
    if (path == null) return;
    children
      ..add(AuraSelectableText(path))
      ..add(_WorkspaceHookTrustedDigest(digest: settings.trustedDigest));
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
    return AuraRow(
      children: [
        const Expanded(child: TextLocale('agent_lifecycle_hooks.enable')),
        AuraSwitch(
          value: view.settings.enabled,
          semanticLabel: _hooksEnabledLabel(context),
          onChanged: _hooksEnabledChanged(view, status),
        ),
      ],
    );
  }
}

ValueChanged<bool>? _hooksEnabledChanged(
  _WorkspaceHookSettingsView view,
  WorkspaceAgentHookTrustStatus status,
) {
  final canEnable = status == WorkspaceAgentHookTrustStatus.trusted;
  if (view.busy || (!view.settings.enabled && !canEnable)) return null;

  return view.callbacks.setEnabled;
}

String _hooksEnabledLabel(BuildContext context) =>
    'agent_lifecycle_hooks.enable'.tr(context: context);

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
    final disabled = view.busy || !isSupported;

    return _WorkspaceHookActionsLayout(
      view: view,
      disabled: disabled,
      spacing: context.auraTheme.fromSpacing(.sm),
    );
  }
}

class const _WorkspaceHookActionsLayout({
  required final _WorkspaceHookSettingsView view,
  required final bool disabled,
  required final double spacing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    _appendChildren(children, view, disabled);

    return Wrap(spacing: spacing, runSpacing: spacing, children: children);
  }

  static void _appendChildren(
    List<Widget> children,
    _WorkspaceHookSettingsView view,
    bool disabled,
  ) {
    children.add(
      _WorkspaceHookChooseAction(
        onPressed: view.callbacks.choose,
        disabled: disabled,
      ),
    );
    _appendReviewAction(children, view, disabled);
    _appendRevokeAction(children, view);
  }

  static void _appendReviewAction(
    List<Widget> children,
    _WorkspaceHookSettingsView view,
    bool disabled,
  ) {
    final path = view.settings.configPath;
    if (path == null) return;

    children.add(
      _WorkspaceHookReviewAction(
        path: path,
        onReview: view.callbacks.review,
        disabled: disabled,
      ),
    );
  }

  static void _appendRevokeAction(
    List<Widget> children,
    _WorkspaceHookSettingsView view,
  ) {
    if (!view.settings.isTrusted) return;

    children.add(
      _WorkspaceHookRevokeAction(
        onPressed: view.callbacks.revoke,
        disabled: view.busy,
      ),
    );
  }
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
