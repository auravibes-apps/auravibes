import 'dart:async';

import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_app/features/skills/providers/refresh_skill_access.dart';
import 'package:auravibes_app/features/skills/providers/skill_access_summary_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/feature_destinations.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show ConnectorDefinition, connectorDefinitions;
import 'package:auravibes_ui/ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef _SkillAccessRecoveryResult = ({bool? result});
typedef _SkillAccessRoute = ({
  SkillToolAccess? missingTool,
});
typedef _SkillAccessSetupRequest = ({
  SkillAccessStatusView view,
  BuildContext context,
  WidgetRef ref,
  SkillAccessSummary summary,
});
typedef _SkillAccessSetup = VoidCallback Function(SkillAccessSummary summary);

class const SkillAccessStatusView({
  required final String workspaceId,
  required final String skillId,
  final bool showDependencies = false,
  final bool isAppSkill = false,
  final VoidCallback? onChanged,
  final bool recoveryEnabled = true,
  final String? connectorSetupSemanticLabel,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(skillAccessSummaryProvider(workspaceId, skillId));

    return _SkillAccessStatusContent(
      summary: summary,
      showDependencies: showDependencies,
      recoveryEnabled: recoveryEnabled,
      onSetup: (value) => _setupAccess((
        view: this,
        context: context,
        ref: ref,
        summary: value,
      )),
      connectorSetupSemanticLabel: connectorSetupSemanticLabel,
    );
  }

  Future<void> _openAccess(
    BuildContext context,
    WidgetRef ref,
    SkillAccessSummary summary,
  ) async {
    final recovery = await _openAccessRoute(context, ref, summary);
    if (recovery == null || !context.mounted) return;

    _refreshAfterAccessRoute(context, ref, recovery);
    onChanged?.call();
  }

  Future<_SkillAccessRecoveryResult?> _openAccessRoute(
    BuildContext context,
    WidgetRef ref,
    SkillAccessSummary summary,
  ) async {
    final route = _skillAccessRoute(summary, isAppSkill);
    final tool = route.missingTool;
    if (tool == null) return null;

    return _skillAccessRecoveryResult(
      await _openConnectorAccess(context, tool.id),
      route,
    );
  }

  Future<bool?> _openConnectorAccess(BuildContext context, String toolId) {
    final target = _connectorTarget(toolId);
    final location = target == null
        ? ServiceConnectionsRoute(
            workspaceId: workspaceId,
            view: 'connectors',
          ).location
        : ServiceConnectionCreateRoute(
            workspaceId: workspaceId,
            type: target.modelProviderId == null
                ? 'connector'
                : 'modelProvider',
            connectorId: target.connectorId,
            modelProviderId: target.modelProviderId,
          ).location;

    return FeatureDestinations.push<bool>(context, location);
  }

  void _refreshAfterAccessRoute(
    BuildContext context,
    WidgetRef ref,
    _SkillAccessRecoveryResult recovery,
  ) {
    if (recovery.result == true) {
      RefreshSkillAccess.refresh(
        ProviderScope.containerOf(context, listen: false),
          (workspaceId: workspaceId, skillId: skillId),
      );

      return;
    }

    ref.invalidate(skillAccessSummaryProvider(workspaceId, skillId));
  }
}

VoidCallback _setupAccess(_SkillAccessSetupRequest request) =>
    () => unawaited(
      request.view._openAccess(request.context, request.ref, request.summary),
    );

_SkillAccessRecoveryResult _skillAccessRecoveryResult(
  bool? result,
  _SkillAccessRoute route,
) => (
  result: result,
);

_SkillAccessRoute _skillAccessRoute(
  SkillAccessSummary summary,
  bool _,
) {
  final missingTool = summary.tools
      .where((tool) => tool.status == .missing)
      .firstOrNull;

  return (missingTool: missingTool);
}

({String? connectorId, String? modelProviderId})? _connectorTarget(
  String toolId,
) {
  final parts = toolId.split('/');
  if (parts.length != 3 || parts.first != 'connector') return null;
  for (final ConnectorDefinition connector in connectorDefinitions) {
    if (connector.identifier != parts[1]) continue;
    if (connector.compatibleModelProviderIds.isEmpty) {
      return (connectorId: connector.identifier, modelProviderId: null);
    }

    return (
      connectorId: null,
      modelProviderId: connector.compatibleModelProviderIds.first,
    );
  }

  return null;
}

class const _SkillAccessStatusContent({
  required final AsyncValue<SkillAccessSummary?> summary,
  required final bool showDependencies,
  required final bool recoveryEnabled,
  required final _SkillAccessSetup onSetup,
  final String? connectorSetupSemanticLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (summary) {
    AsyncData(value: final value?) => _SkillAccessSummaryContent(
      summary: value,
      showDependencies: showDependencies,
      recoveryEnabled: recoveryEnabled,
      onSetup: onSetup(value),
      connectorSetupSemanticLabel: connectorSetupSemanticLabel,
    ),
    AsyncLoading() => const TextLocale(LocaleKeys.skill_access_checking),
    AsyncData() ||
    AsyncError() => const TextLocale(LocaleKeys.skill_access_unknown),
  };
}

String _accessKey(SkillAccessStatus status) => switch (status) {
  .notRequired => LocaleKeys.skill_access_not_required,
  .saved => LocaleKeys.skill_access_saved,
  .missing => LocaleKeys.skill_access_missing,
  .partial => LocaleKeys.skill_access_partial,
  .unknown => LocaleKeys.skill_access_unknown,
};

class const _SkillAccessSummaryContent({
  required final SkillAccessSummary summary,
  required final bool showDependencies,
  required final bool recoveryEnabled,
  required final VoidCallback onSetup,
  final String? connectorSetupSemanticLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      TextLocale(_accessKey(summary.status)),
      if (showDependencies)
        _SkillAccessDependencies(
          summary: summary,
          recoveryEnabled: recoveryEnabled,
          onSetup: onSetup,
          connectorSetupSemanticLabel: connectorSetupSemanticLabel,
        ),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _SkillAccessDependencies({
  required final SkillAccessSummary summary,
  required final bool recoveryEnabled,
  required final VoidCallback onSetup,
  final String? connectorSetupSemanticLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const TextLocale(LocaleKeys.skill_access_verification_hint),
      for (final tool in summary.tools)
        if (tool.status != .available) _SkillAccessDependency(tool: tool),
      if (_requiresSetup(summary))
        _SkillAccessSetupButton(
          recoveryEnabled: recoveryEnabled,
          onPressed: onSetup,
          semanticLabel: connectorSetupSemanticLabel,
        ),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

bool _requiresSetup(SkillAccessSummary summary) =>
    summary.status == .missing || summary.status == .partial;

class const _SkillAccessSetupButton({
  required final bool recoveryEnabled,
  required final VoidCallback onPressed,
  final String? semanticLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale(LocaleKeys.skills_selector_connector_setup),
    variant: .text,
    disabled: !recoveryEnabled,
    semanticLabel: semanticLabel,
  );
}

class const _SkillAccessDependency({required final SkillToolAccess tool})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      Expanded(child: Text(tool.title)),
      TextLocale(switch (tool.status) {
        .disabled => LocaleKeys.skill_access_tool_disabled,
        .missing => LocaleKeys.skill_access_tool_missing,
        .unknown => LocaleKeys.skill_access_unknown,
        .available => LocaleKeys.skill_access_saved,
      }),
    ],
    spacing: .sm,
  );
}
