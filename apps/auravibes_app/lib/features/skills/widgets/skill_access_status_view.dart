import 'dart:async';

import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_app/features/skills/providers/refresh_skill_access.dart';
import 'package:auravibes_app/features/skills/providers/skill_access_summary_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

typedef _SkillAccessRecoveryResult = ({
  bool? result,
  String? definitionId,
  bool toolsChanged,
});
typedef _SkillAccessRoute = ({
  SkillToolAccess? missingTool,
  String? definitionId,
  bool toolsChanged,
});
typedef _AppAccessRouteRequest = ({
  BuildContext context,
  WidgetRef ref,
  _SkillAccessRoute route,
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
    if (route.toolsChanged) return await _openToolAccessRoute(context, route);

    if (isAppSkill) {
      return await _openAppAccess((context: context, ref: ref, route: route));
    }

    return await _openUserAccessRoute(context, route);
  }

  Future<_SkillAccessRecoveryResult?> _openToolAccessRoute(
    BuildContext context,
    _SkillAccessRoute route,
  ) async {
    final tool = route.missingTool;
    if (tool == null) return null;

    return _skillAccessRecoveryResult(
      await _openToolAccess(context, tool.id),
      route,
    );
  }

  Future<_SkillAccessRecoveryResult> _openUserAccessRoute(
    BuildContext context,
    _SkillAccessRoute route,
  ) async => _skillAccessRecoveryResult(
    await _openUserAccess(context, route.definitionId),
    route,
  );

  Future<bool?> _openToolAccess(BuildContext context, String toolId) =>
      SkillToolEditRoute(
        workspaceId: workspaceId,
        skillId: skillId,
        toolId: toolId,
      ).push<bool>(context);

  Future<bool?> _openUserAccess(BuildContext context, String? definitionId) =>
      ServiceConnectionCreateRoute(
        workspaceId: workspaceId,
        type: 'skillCredential',
        credentialDefinitionId: definitionId,
      ).push<bool>(context);

  Future<_SkillAccessRecoveryResult?> _openAppAccess(
    _AppAccessRouteRequest request,
  ) async {
    final appSkill = request.ref
        .read(appSkillRegistryProvider)
        .getByIdentifier(skillId);
    if (appSkill == null) return null;

    final result = await request.context.push<bool>(
      _appAccessLocation(
        workspaceId,
        skillId,
        appSkill.compatibleModelProviderIds.isEmpty,
      ),
    );

    return _skillAccessRecoveryResult(result, request.route);
  }

  void _refreshAfterAccessRoute(
    BuildContext context,
    WidgetRef ref,
    _SkillAccessRecoveryResult recovery,
  ) {
    if (recovery.result == true) {
      RefreshSkillAccess.refresh(
        ProviderScope.containerOf(context, listen: false),
        (
          workspaceId: workspaceId,
          skillId: skillId,
          credentialDefinitionId: recovery.definitionId,
          toolsChanged: recovery.toolsChanged,
        ),
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
  definitionId: route.definitionId,
  toolsChanged: route.toolsChanged,
);

String _appAccessLocation(
  String workspaceId,
  String skillId,
  bool appSkillCredential,
) {
  final location = ServiceConnectionCreateRoute(
    workspaceId: workspaceId,
    type: appSkillCredential ? 'appSkillCredential' : 'modelProvider',
  ).location;
  final uri = Uri.parse(location);

  return uri
      .replace(
        queryParameters: {
          ...uri.queryParameters,
          if (appSkillCredential) 'appSkillId': skillId,
        },
      )
      .toString();
}

_SkillAccessRoute _skillAccessRoute(
  SkillAccessSummary summary,
  bool isAppSkill,
) {
  final missingTool = summary.tools
      .where((tool) => tool.status == .missing)
      .firstOrNull;
  final definitionId =
      missingTool?.credentialDefinitionId ?? summary.credentialDefinitionId;

  return (
    missingTool: missingTool,
    definitionId: definitionId,
    toolsChanged: !isAppSkill && definitionId == null,
  );
}

class const _SkillAccessStatusContent({
  required final AsyncValue<SkillAccessSummary?> summary,
  required final bool showDependencies,
  required final bool recoveryEnabled,
  required final _SkillAccessSetup onSetup,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (summary) {
    AsyncData(value: final value?) => _SkillAccessSummaryContent(
      summary: value,
      showDependencies: showDependencies,
      recoveryEnabled: recoveryEnabled,
      onSetup: onSetup(value),
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
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale(LocaleKeys.skills_selector_credential_setup),
    variant: .text,
    disabled: !recoveryEnabled,
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
