import 'dart:async';

import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_setup_preflight.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_setup_preflight_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
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

class const WorkspaceSetupPreflightScreen({
  required final String workspaceId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(workspaceSetupPreflightProvider(workspaceId));

    return AppScreen(
      appBar: const AuraAppBarWithDrawer(
        title: TextLocale('workspace_setup_preflight.title'),
      ),
      child: switch (result) {
        AsyncData(:final value) => _PreflightContent(
          workspaceId: workspaceId,
          result: value,
        ),
        AsyncLoading() => const Center(child: AuraSpinner()),
        AsyncError() => _PreflightUnavailable(workspaceId: workspaceId),
      },
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AuraCard(
          style: .border,
          tint: _outcomeTint(result.outcome),
          child: AuraColumn(
            crossAxisAlignment: .start,
            children: [
              AuraText(
                child: TextLocale(_outcomeKey(result.outcome)),
                style: .heading6,
              ),
              const TextLocale('workspace_setup_preflight.saved_configuration_only'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AuraButton(
                    onPressed: () => _refresh(ref, workspaceId),
                    child: TextLocale(
                      isCloud
                          ? 'workspace_setup_preflight.refresh_saved_cloud'
                          : 'workspace_setup_preflight.refresh_local',
                    ),
                    variant: .ghost,
                    key: const ValueKey('workspace_setup_preflight_refresh'),
                  ),
                  AuraButton(
                    onPressed: () => _copySupportSummary(context, result),
                    child: const TextLocale(
                      'workspace_setup_preflight.copy_summary',
                    ),
                    variant: .ghost,
                    key: const ValueKey('workspace_setup_preflight_copy'),
                  ),
                ],
              ),
            ],
          ),
        ),
        for (final checkId in WorkspaceSetupPreflightCheckId.values)
          _PreflightCheckCard(
            workspaceId: workspaceId,
            check: result.check(checkId),
          ),
      ],
    );
  }
}

class const _PreflightCheckCard({
  required final String workspaceId,
  required final WorkspaceSetupPreflightCheck check,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final capabilities = check.modelCapabilities;

    return AuraCard(
      style: .border,
      tint: _statusTint(check.status),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: '${_checkTitle(check.id).tr(context: context)}. '
            '${check.messageKey.tr(context: context)}',
        child: AuraColumn(
          crossAxisAlignment: .start,
          children: [
            AuraText(child: TextLocale(_checkTitle(check.id)), style: .heading6),
            Row(
              children: [
                Icon(_statusIcon(check.status), size: 18),
                const SizedBox(width: 8),
                TextLocale(_statusKey(check.status)),
              ],
            ),
            TextLocale(check.messageKey),
            if (capabilities != null)
              _ModelCapabilitiesView(capabilities: capabilities),
            if (check.recovery case final action?)
              AuraButton(
                onPressed: () => _openRecovery(context, workspaceId, action),
                child: TextLocale(_recoveryLabel(action)),
                variant: .ghost,
                key: ValueKey('workspace_setup_preflight_recovery_${check.id.name}'),
              ),
          ],
        ),
      ),
    );
  }
}

class const _ModelCapabilitiesView({
  required final WorkspaceSetupModelCapabilities capabilities,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    crossAxisAlignment: .start,
    children: [
      AuraText(child: Text(capabilities.modelName), style: .bodySmall),
      TextLocale(
        'workspace_setup_preflight.model_modalities',
        args: [
          _modalityLabel(context, capabilities.inputModalities),
          _modalityLabel(context, capabilities.outputModalities),
        ],
      ),
      TextLocale(
        capabilities.supportsToolCalls
            ? 'workspace_setup_preflight.model_tools_supported'
            : 'workspace_setup_preflight.model_tools_unsupported',
      ),
      TextLocale(
        capabilities.supportsReasoning
            ? 'workspace_setup_preflight.model_reasoning_supported'
            : 'workspace_setup_preflight.model_reasoning_unsupported',
      ),
    ],
  );

  String _modalityLabel(BuildContext context, List<String> values) {
    if (values.isEmpty) {
      return 'workspace_setup_preflight.model_modality_unknown'.tr(
        context: context,
      );
    }

    return values
        .map((value) => switch (value) {
          'text' || 'image' || 'audio' || 'video' =>
            'workspace_setup_preflight.modality.$value'.tr(context: context),
          _ => 'workspace_setup_preflight.model_modality_unknown'.tr(
            context: context,
          ),
        })
        .join(', ');
  }
}

class const _PreflightUnavailable({
  required final String workspaceId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: AuraColumn(
      crossAxisAlignment: .center,
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

String _outcomeKey(WorkspaceSetupPreflightOutcome outcome) => switch (outcome) {
  .ready => 'workspace_setup_preflight.outcome.ready',
  .needsSetup => 'workspace_setup_preflight.outcome.needs_setup',
  .blocked => 'workspace_setup_preflight.outcome.blocked',
  .unverified => 'workspace_setup_preflight.outcome.unverified',
};

String _recoveryLabel(WorkspaceSetupPreflightRecovery action) => switch (action) {
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

AuraTint? _outcomeTint(WorkspaceSetupPreflightOutcome outcome) => switch (outcome) {
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
    .openConnections => ServiceConnectionsRoute(workspaceId: workspaceId).location,
  };
  unawaited(FeatureDestinations.push<void>(context, destination));
}

Future<void> _copySupportSummary(
  BuildContext context,
  WorkspaceSetupPreflight result,
) async {
  final labels = (
    overallLabel: 'workspace_setup_preflight.summary.overall'.tr(context: context),
    outcomes: {
      for (final outcome in WorkspaceSetupPreflightOutcome.values)
        outcome: _outcomeKey(outcome).tr(context: context),
    },
    checks: {
      for (final check in WorkspaceSetupPreflightCheckId.values)
        check: _checkTitle(check).tr(context: context),
    },
    statuses: {
      for (final status in WorkspaceSetupPreflightStatus.values)
        status: _statusKey(status).tr(context: context),
    },
    generatedAt: 'workspace_setup_preflight.summary.generated_at'.tr(
      context: context,
    ),
    appVersion: 'workspace_setup_preflight.summary.app_version'.tr(
      context: context,
    ),
  );
  final unavailableVersion = 'workspace_setup_preflight.summary.unavailable'.tr(
    context: context,
  );
  String appVersion;
  try {
    appVersion = (await PackageInfo.fromPlatform()).version;
  } on Object {
    appVersion = unavailableVersion;
  }
  if (!context.mounted) return;
  final summary = const BuildWorkspaceSetupPreflightUsecase()
      .formatSupportSummary(
        result: result,
        generatedAt: DateTime.now().toUtc(),
        appVersion: appVersion,
        labels: labels,
      );
  try {
    await Clipboard.setData(ClipboardData(text: summary));
  } on Object {
    if (!context.mounted) return;
    final _ = AuraSnackBars.show(
      context: context,
      content: const TextLocale('workspace_setup_preflight.summary_copy_error'),
      variant: .error,
    );
    return;
  }
  if (!context.mounted) return;
  final _ = AuraSnackBars.show(
    context: context,
    content: const TextLocale('workspace_setup_preflight.summary_copied'),
    variant: .success,
  );
}
