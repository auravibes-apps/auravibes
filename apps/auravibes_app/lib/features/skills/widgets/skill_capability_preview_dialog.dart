import 'package:auravibes_app/features/skills/models/available_skill.dart';
import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_app/features/skills/providers/skill_access_summary_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const _previewDialogWidth = 520.0;

class const SkillCapabilityPreviewDialog({
  required final String workspaceId,
  required final AvailableSkill skill,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(
      skillAccessSummaryProvider(workspaceId, skill.id),
    );
    final message = switch (summary) {
      AsyncData(value: final value?) => _SkillCapabilitiesPreviewContents(
        summary: value,
      ),
      AsyncLoading() => const TextLocale(
        LocaleKeys.skills_selector_preview_loading,
      ),
      AsyncData() || AsyncError() => const TextLocale(
        LocaleKeys.skills_selector_preview_error,
      ),
    };

    return AuraAlertDialog(
      title: AuraColumn(
        children: [
          const AuraText(
            child: TextLocale(LocaleKeys.skills_selector_preview_title),
            style: .heading4,
          ),
          Text(skill.title),
        ],
        spacing: .xs,
        crossAxisAlignment: .start,
      ),
      message: SizedBox(
        width: _previewDialogWidth,
        child: SingleChildScrollView(child: message),
      ),
      dismissLabel: const TextLocale(LocaleKeys.common_close),
    );
  }
}

class const _SkillCapabilitiesPreviewContents({
  required final SkillAccessSummary summary,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraColumn(
        children: [
          const AuraText(
            child: TextLocale(
              LocaleKeys.skills_selector_preview_connections_title,
            ),
            style: .heading4,
          ),
          TextLocale(_previewAccessStatusKey(summary.status)),
          const TextLocale(LocaleKeys.skill_access_verification_hint),
        ],
        spacing: .xs,
        crossAxisAlignment: .start,
      ),
      AuraColumn(
        children: [
          const AuraText(
            child: TextLocale(LocaleKeys.skills_selector_preview_tools_title),
            style: .heading4,
          ),
          if (summary.tools.isEmpty)
            const TextLocale(LocaleKeys.skills_selector_preview_no_tools)
          else
            for (final tool in summary.tools)
              _SkillCapabilityPreviewTool(tool: tool),
        ],
        spacing: .sm,
        crossAxisAlignment: .start,
      ),
    ],
    spacing: .md,
    crossAxisAlignment: .start,
  );
}

class const _SkillCapabilityPreviewTool({required final SkillToolAccess tool})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = tool.titleKey == null
        ? Text(tool.title)
        : TextLocale(tool.titleKey!);
    final description = tool.description.trim();
    final descriptionWidget = tool.descriptionKey != null
        ? TextLocale(tool.descriptionKey!)
        : description.isEmpty
        ? const TextLocale(LocaleKeys.skills_selector_preview_description_empty)
        : Text(description);
    final statusKey = _previewToolStatusKey(tool.status);

    return Semantics(
      container: true,
      label: [
        tool.titleKey?.tr(context: context) ?? tool.title,
        tool.descriptionKey?.tr(context: context) ??
            (description.isEmpty
                ? LocaleKeys.skills_selector_preview_description_empty.tr(
                    context: context,
                  )
                : description),
        statusKey.tr(context: context),
      ].join(', '),
      child: ExcludeSemantics(
        child: AuraColumn(
          children: [
            AuraRow(
              children: [
                Expanded(
                  child: AuraText(child: title, style: .heading5),
                ),
                TextLocale(statusKey),
              ],
              spacing: .sm,
            ),
            descriptionWidget,
          ],
          spacing: .xs,
          crossAxisAlignment: .start,
        ),
      ),
    );
  }
}

String _previewAccessStatusKey(SkillAccessStatus status) => switch (status) {
  .notRequired => LocaleKeys.skill_access_not_required,
  .saved => LocaleKeys.skill_access_saved,
  .missing => LocaleKeys.skill_access_missing,
  .partial => LocaleKeys.skill_access_partial,
  .unknown => LocaleKeys.skill_access_unknown,
};

String _previewToolStatusKey(SkillToolAccessStatus status) => switch (status) {
  .available => LocaleKeys.skills_selector_preview_tool_available,
  .disabled => LocaleKeys.skills_selector_preview_tool_disabled,
  .missing => LocaleKeys.skills_selector_preview_tool_missing,
  .unknown => LocaleKeys.skills_selector_preview_tool_unknown,
};
