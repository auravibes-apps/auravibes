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

    return switch (summary) {
      AsyncData(value: final value?) => AuraColumn(
        children: [
          TextLocale(_accessKey(value.status)),
          if (showDependencies) ...[
            const TextLocale(LocaleKeys.skill_access_verification_hint),
            for (final tool in value.tools)
              if (tool.status != .available) _SkillAccessDependency(tool: tool),
            if (_needsAccess(value))
              AuraButton(
                onPressed: () => unawaited(_openAccess(context, ref, value)),
                child: const TextLocale(
                  LocaleKeys.skills_selector_credential_setup,
                ),
                variant: .text,
                disabled: !recoveryEnabled,
              ),
          ],
        ],
        spacing: .xs,
        crossAxisAlignment: .start,
      ),
      AsyncLoading() => const TextLocale(LocaleKeys.skill_access_checking),
      AsyncData() ||
      AsyncError() => const TextLocale(LocaleKeys.skill_access_unknown),
    };
  }

  bool _needsAccess(SkillAccessSummary summary) =>
      summary.status == .missing || summary.status == .partial;

  Future<void> _openAccess(
    BuildContext context,
    WidgetRef ref,
    SkillAccessSummary summary,
  ) async {
    final missing = summary.tools.where((tool) => tool.status == .missing);
    final definitionId =
        missing.firstOrNull?.credentialDefinitionId ??
        summary.credentialDefinitionId;
    final bool? result;
    final toolsChanged = !isAppSkill && definitionId == null;
    if (toolsChanged) {
      final tool = missing.firstOrNull;
      if (tool == null) return;
      result = await SkillToolEditRoute(
        workspaceId: workspaceId,
        skillId: skillId,
        toolId: tool.id,
      ).push<bool>(context);
    } else if (isAppSkill) {
      final appSkill = ref
          .read(appSkillRegistryProvider)
          .getByIdentifier(skillId);
      if (appSkill == null) return;
      final location = ServiceConnectionCreateRoute(
        workspaceId: workspaceId,
        type: appSkill.compatibleModelProviderIds.isEmpty
            ? 'appSkillCredential'
            : 'modelProvider',
      ).location;
      final uri = Uri.parse(location);
      result = await context.push<bool>(
        uri
            .replace(
              queryParameters: {
                ...uri.queryParameters,
                if (appSkill.compatibleModelProviderIds.isEmpty)
                  'appSkillId': skillId,
              },
            )
            .toString(),
      );
    } else {
      result = await ServiceConnectionCreateRoute(
        workspaceId: workspaceId,
        type: 'skillCredential',
        credentialDefinitionId: definitionId,
      ).push<bool>(context);
    }
    if (!context.mounted) return;
    if (result == true) {
      refreshSkillAccess(
        ProviderScope.containerOf(context, listen: false),
        workspaceId: workspaceId,
        skillId: skillId,
        credentialDefinitionId: definitionId,
        toolsChanged: toolsChanged,
      );
    } else {
      ref.invalidate(skillAccessSummaryProvider(workspaceId, skillId));
    }
    onChanged?.call();
  }
}

String _accessKey(SkillAccessStatus status) => switch (status) {
  .notRequired => LocaleKeys.skill_access_not_required,
  .saved => LocaleKeys.skill_access_saved,
  .missing => LocaleKeys.skill_access_missing,
  .partial => LocaleKeys.skill_access_partial,
  .unknown => LocaleKeys.skill_access_unknown,
};

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
