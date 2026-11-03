import 'dart:async';

import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_setup_preflight.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_setup_preflight_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/build_workspace_setup_preflight_usecase.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/feature_destinations.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _summaryActionSpacing = 8.0;
const _statusIconSize = 18.0;

class const WorkspaceSetupPreflightScreen({
  required final String workspaceId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(workspaceSetupPreflightProvider(workspaceId));

    return AppScreen(
      child: switch (result) {
        AsyncData(:final value) => _PreflightContent(
          workspaceId: workspaceId,
          result: value,
        ),
        AsyncLoading() => const Center(child: AuraSpinner()),
        AsyncError() => _PreflightUnavailable(workspaceId: workspaceId),
      },
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale('workspace_setup_preflight.title'),
      ),
    );
  }
}

class const _PreflightContent({
  required final String workspaceId,
  required final WorkspaceSetupPreflight result,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(workspaceSessionForRouteProvider(workspaceId));
    final isCloud = session.asData?.value.cloud != null;

    return _preflightList(isCloud);
  }

  Widget _preflightList(bool isCloud) => ListView(
    padding: const EdgeInsets.all(16),
    children: _preflightCards(isCloud),
  );

  List<Widget> _preflightCards(bool isCloud) => [
    _PreflightSummaryCard(
      workspaceId: workspaceId,
      result: result,
      isCloud: isCloud,
    ),
    for (final id in WorkspaceSetupPreflightCheckId.values)
      _PreflightCheckCard(
        workspaceId: workspaceId,
        check: result.check(id),
      ),
  ];
}

class const _PreflightSummaryCard({
  required final String workspaceId,
  required final WorkspaceSetupPreflight result,
  required final bool isCloud,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: AuraColumn(
      children: [
        AuraText(
          child: TextLocale(_outcomeKey(result.outcome)),
          style: .heading6,
        ),
        const TextLocale('workspace_setup_preflight.saved_configuration_only'),
        _SummaryActions(
          workspaceId: workspaceId,
          result: result,
          isCloud: isCloud,
        ),
      ],
      crossAxisAlignment: .start,
    ),
    style: .border,
    tint: _outcomeTint(result.outcome),
  );
}

class const _SummaryActions({
  required final String workspaceId,
  required final WorkspaceSetupPreflight result,
  required final bool isCloud,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    spacing: _summaryActionSpacing,
    runSpacing: _summaryActionSpacing,
    children: [
      _RefreshSavedConfigurationButton(
        workspaceId: workspaceId,
        isCloud: isCloud,
      ),
      _CopySupportSummaryButton(result: result),
    ],
  );
}

class const _RefreshSavedConfigurationButton({
  required final String workspaceId,
  required final bool isCloud,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraButton(
    onPressed: () => _refresh(ref, workspaceId),
    child: TextLocale(
      isCloud
          ? 'workspace_setup_preflight.refresh_saved_cloud'
          : 'workspace_setup_preflight.refresh_local',
    ),
    key: const ValueKey('workspace_setup_preflight_refresh'),
    variant: .ghost,
  );
}

class const _CopySupportSummaryButton({
  required final WorkspaceSetupPreflight result,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => _copySupportSummary(context, result),
    child: const TextLocale('workspace_setup_preflight.copy_summary'),
    key: const ValueKey('workspace_setup_preflight_copy'),
    variant: .ghost,
  );
}

class const _PreflightCheckCard({
  required final String workspaceId,
  required final WorkspaceSetupPreflightCheck check,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: _PreflightCheckSemantics(workspaceId: workspaceId, check: check),
    style: .border,
    tint: _statusTint(check.status),
  );
}

class const _PreflightCheckSemantics({
  required final String workspaceId,
  required final WorkspaceSetupPreflightCheck check,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: _PreflightCheckBody(workspaceId: workspaceId, check: check),
    container: true,
    explicitChildNodes: true,
    label: _checkSemanticsLabel(context, check),
  );
}

class const _PreflightCheckBody({
  required final String workspaceId,
  required final WorkspaceSetupPreflightCheck check,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _CheckTitle(check: check),
      _CheckStatusRow(check: check),
      _CheckMessage(messageKey: check.messageKey),
      if (check.modelCapabilities case final capabilities?)
        _ModelCapabilitiesView(capabilities: capabilities),
      if (check.recovery case final recovery?)
        _RecoveryButton(
          workspaceId: workspaceId,
          recovery: recovery,
          check: check,
        ),
    ],
    crossAxisAlignment: .start,
  );
}

class const _CheckMessage({required final String messageKey})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Text(_localizedCheckMessage(context, messageKey));
}

class const _CheckTitle({required final WorkspaceSetupPreflightCheck check})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraText(child: TextLocale(_checkTitle(check.id)), style: .heading6);
}

class const _CheckStatusRow({required final WorkspaceSetupPreflightCheck check})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(_statusIcon(check.status), size: _statusIconSize),
      const SizedBox(width: _summaryActionSpacing),
      TextLocale(_statusKey(check.status)),
    ],
  );
}

class const _RecoveryButton({
  required final String workspaceId,
  required final WorkspaceSetupPreflightRecovery recovery,
  required final WorkspaceSetupPreflightCheck check,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => _openRecovery(context, workspaceId, recovery),
    child: TextLocale(_recoveryLabel(recovery)),
    key: ValueKey('workspace_setup_preflight_recovery_${check.id.name}'),
    variant: .ghost,
  );
}

class const _ModelCapabilitiesView({
  required final WorkspaceSetupModelCapabilities capabilities,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraText(child: Text(capabilities.modelName), style: .bodySmall),
      TextLocale(
        'workspace_setup_preflight.model_modalities',
        args: [
          _modalityLabel(context, capabilities.inputModalities),
          _modalityLabel(context, capabilities.outputModalities),
        ],
      ),
      TextLocale(_toolSupportKey(capabilities.supportsToolCalls)),
      TextLocale(_reasoningSupportKey(capabilities.supportsReasoning)),
    ],
    crossAxisAlignment: .start,
  );

  String _modalityLabel(BuildContext context, List<String> values) {
    if (values.isEmpty) return _unknownModality(context);

    return values.map((value) => _localizedModality(context, value)).join(', ');
  }

  String _localizedModality(
    BuildContext context,
    String value,
  ) => switch (value) {
    'text' => 'workspace_setup_preflight.modality.text'.tr(context: context),
    'image' => 'workspace_setup_preflight.modality.image'.tr(context: context),
    'audio' => 'workspace_setup_preflight.modality.audio'.tr(context: context),
    'video' => 'workspace_setup_preflight.modality.video'.tr(context: context),
    _ => _unknownModality(context),
  };

  String _unknownModality(BuildContext context) =>
      'workspace_setup_preflight.model_modality_unknown'.tr(context: context);

  String _toolSupportKey(bool supported) => supported
      ? 'workspace_setup_preflight.model_tools_supported'
      : 'workspace_setup_preflight.model_tools_unsupported';

  String _reasoningSupportKey(bool supported) => supported
      ? 'workspace_setup_preflight.model_reasoning_supported'
      : 'workspace_setup_preflight.model_reasoning_unsupported';
}

class const _PreflightUnavailable({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: AuraColumn(
      children: [
        const TextLocale('workspace_setup_preflight.unavailable'),
        AuraButton(
          onPressed: () => _refresh(ref, workspaceId),
          child: const TextLocale('route_state.retry'),
        ),
      ],
    ),
  );
}

String _checkTitle(WorkspaceSetupPreflightCheckId id) => switch (id) {
  .storage => 'workspace_setup_preflight.check.storage',
  .providerCredentials => 'workspace_setup_preflight.check.provider',
  .selectedModel => 'workspace_setup_preflight.check.model',
  .mcpConnections => 'workspace_setup_preflight.check.mcp',
};

String _statusKey(WorkspaceSetupPreflightStatus status) => switch (status) {
  .pass => 'workspace_setup_preflight.status.pass',
  .warning => 'workspace_setup_preflight.status.warning',
  .fail => 'workspace_setup_preflight.status.fail',
  .unknown => 'workspace_setup_preflight.status.unknown',
};

const _checkMessageKeys = {
  'workspace_setup_preflight.storage_available',
  'workspace_setup_preflight.storage_unavailable',
  'workspace_setup_preflight.storage_unverified',
  'workspace_setup_preflight.provider_unverified',
  'workspace_setup_preflight.provider_not_configured',
  'workspace_setup_preflight.provider_credential_missing_optional',
  'workspace_setup_preflight.provider_credential_missing_required',
  'workspace_setup_preflight.provider_for_model_missing',
  'workspace_setup_preflight.provider_saved',
  'workspace_setup_preflight.model_not_selected',
  'workspace_setup_preflight.model_unverified',
  'workspace_setup_preflight.model_missing',
  'workspace_setup_preflight.model_metadata_unavailable',
  'workspace_setup_preflight.model_metadata_available',
  'workspace_setup_preflight.mcp_unverified',
  'workspace_setup_preflight.mcp_not_configured',
  'workspace_setup_preflight.mcp_disabled',
  'workspace_setup_preflight.mcp_not_tested',
  'workspace_setup_preflight.mcp_attention',
  'workspace_setup_preflight.mcp_last_test_passed',
};

String _localizedCheckMessage(BuildContext context, String key) {
  final messageKey = _checkMessageKeys.contains(key)
      ? key
      : 'workspace_setup_preflight.unavailable';

  return messageKey.tr(context: context);
}

String _outcomeKey(WorkspaceSetupPreflightOutcome outcome) => switch (outcome) {
  .ready => 'workspace_setup_preflight.outcome.ready',
  .needsSetup => 'workspace_setup_preflight.outcome.needs_setup',
  .blocked => 'workspace_setup_preflight.outcome.blocked',
  .unverified => 'workspace_setup_preflight.outcome.unverified',
};

String _recoveryLabel(WorkspaceSetupPreflightRecovery action) =>
    switch (action) {
      .addProvider => 'workspace_setup_preflight.recovery.add_provider',
      .reviewProvider => 'workspace_setup_preflight.recovery.review_provider',
      .chooseModel => 'workspace_setup_preflight.recovery.choose_model',
      .openConnections => 'workspace_setup_preflight.recovery.open_connections',
    };

AuraTint? _statusTint(WorkspaceSetupPreflightStatus status) => switch (status) {
  .pass => .success,
  .warning => .warning,
  .fail => .error,
  .unknown => .info,
};

AuraTint? _outcomeTint(WorkspaceSetupPreflightOutcome outcome) =>
    switch (outcome) {
      .ready => .success,
      .needsSetup => .warning,
      .blocked => .error,
      .unverified => .info,
    };

IconData _statusIcon(WorkspaceSetupPreflightStatus status) => switch (status) {
  .pass => Icons.check_circle_outline,
  .warning => Icons.warning_amber,
  .fail => Icons.error_outline,
  .unknown => Icons.help_outline,
};

String _checkSemanticsLabel(
  BuildContext context,
  WorkspaceSetupPreflightCheck check,
) {
  final title = _checkTitle(check.id).tr(context: context);
  final message = _localizedCheckMessage(context, check.messageKey);

  return '$title. $message';
}

void _refresh(WidgetRef ref, String workspaceId) {
  ref
    ..invalidate(workspaceByIdProvider(workspaceId))
    ..invalidate(chatModelConnectionsProvider(workspaceId))
    ..invalidate(modelConnectionStoreProvider(workspaceId))
    ..invalidate(modelSelectionStoreProvider(workspaceId))
    ..invalidate(modelCatalogStoreProvider(workspaceId))
    ..invalidate(serviceConnectionsProvider(workspaceId))
    ..invalidate(workspaceSessionForRouteProvider(workspaceId));
  ref
      .read(workspaceSetupPreflightRefreshProvider(workspaceId).notifier)
      .requestSavedConfigurationRefresh();
}

void _openRecovery(
  BuildContext context,
  String workspaceId,
  WorkspaceSetupPreflightRecovery recovery,
) {
  final destination = switch (recovery) {
    .addProvider => ServiceConnectionCreateRoute(
      workspaceId: workspaceId,
      type: 'modelProvider',
    ).location,
    .reviewProvider => ServiceConnectionsRoute(
      workspaceId: workspaceId,
      view: 'providers',
    ).location,
    .chooseModel => NewChatRoute(workspaceId: workspaceId).location,
    .openConnections => ServiceConnectionsRoute(
      workspaceId: workspaceId,
    ).location,
  };
  unawaited(FeatureDestinations.push<void>(context, destination));
}

Future<void> _copySupportSummary(
  BuildContext context,
  WorkspaceSetupPreflight result,
) async {
  final labels = _summaryLabels(context);
  final appVersion = await _readAppVersion(context);
  if (!context.mounted) return;

  final summary = const BuildWorkspaceSetupPreflightUsecase()
      .formatSupportSummary(
        result: result,
        generatedAt: DateTime.now().toUtc(),
        appVersion: appVersion,
        labels: labels,
      );
  await _copySummary(context, summary);
}

WorkspaceSetupPreflightLabels _summaryLabels(BuildContext context) => (
  overallLabel: 'workspace_setup_preflight.summary.overall'.tr(
    context: context,
  ),
  outcomes: _outcomeLabels(context),
  checks: _checkLabels(context),
  statuses: _statusLabels(context),
  generatedAt: 'workspace_setup_preflight.summary.generated_at'.tr(
    context: context,
  ),
  appVersion: 'workspace_setup_preflight.summary.app_version'.tr(
    context: context,
  ),
);

Map<WorkspaceSetupPreflightOutcome, String> _outcomeLabels(
  BuildContext context,
) => {
  for (final outcome in WorkspaceSetupPreflightOutcome.values)
    outcome: _outcomeKey(outcome).tr(context: context),
};

Map<WorkspaceSetupPreflightCheckId, String> _checkLabels(
  BuildContext context,
) => {
  for (final check in WorkspaceSetupPreflightCheckId.values)
    check: _checkTitle(check).tr(context: context),
};

Map<WorkspaceSetupPreflightStatus, String> _statusLabels(
  BuildContext context,
) => {
  for (final status in WorkspaceSetupPreflightStatus.values)
    status: _statusKey(status).tr(context: context),
};

Future<String> _readAppVersion(BuildContext context) async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } on Object {
    return 'workspace_setup_preflight.summary.unavailable'.tr(context: context);
  }
}

Future<void> _copySummary(BuildContext context, String summary) async {
  try {
    await Clipboard.setData(.new(text: summary));
  } on Object {
    if (context.mounted) _showSummaryCopyResult(context, false);

    return;
  }
  if (context.mounted) _showSummaryCopyResult(context, true);
}

void _showSummaryCopyResult(BuildContext context, bool copied) {
  final _ = AuraSnackBars.show(
    context: context,
    content: TextLocale(
      copied
          ? 'workspace_setup_preflight.summary_copied'
          : 'workspace_setup_preflight.summary_copy_error',
    ),
    variant: copied ? .success : .error,
  );
}
