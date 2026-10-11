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
    return AuraAlertDialog(
      title: _SkillCapabilityPreviewHeader(skill: skill),
      message: _SkillCapabilityPreviewBody(
        summary: ref.watch(skillAccessSummaryProvider(workspaceId, skill.id)),
      ),
      dismissLabel: const TextLocale(LocaleKeys.common_close),
    );
  }
}

class const _SkillCapabilityPreviewHeader({required final AvailableSkill skill})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const AuraText(
        child: TextLocale(LocaleKeys.skills_selector_preview_title),
        style: .heading4,
      ),
      Text(skill.title),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _SkillCapabilityPreviewBody({
  required final AsyncValue<SkillAccessSummary?> summary,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: _previewDialogWidth,
    child: SingleChildScrollView(
      child: _skillCapabilityPreviewContent(summary),
    ),
  );
}

Widget _skillCapabilityPreviewContent(
  AsyncValue<SkillAccessSummary?> summary,
) => switch (summary) {
  AsyncData(value: final value?) => _SkillCapabilitiesPreviewContents(
    summary: value,
  ),
  AsyncLoading() => const TextLocale(
    LocaleKeys.skills_selector_preview_loading,
  ),
  AsyncData() ||
  AsyncError() => const TextLocale(LocaleKeys.skills_selector_preview_error),
};

class const _SkillCapabilitiesPreviewContents({
  required final SkillAccessSummary summary,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _SkillCapabilityConnectionsPreview(status: summary.status),
      _SkillCapabilityToolsPreview(tools: summary.tools),
    ],
    spacing: .md,
    crossAxisAlignment: .start,
  );
}

class const _SkillCapabilityConnectionsPreview({
  required final SkillAccessStatus status,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const AuraText(
        child: TextLocale(LocaleKeys.skills_selector_preview_connections_title),
        style: .heading4,
      ),
      TextLocale(_previewAccessStatusKey(status)),
      const TextLocale(LocaleKeys.skill_access_verification_hint),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _SkillCapabilityToolsPreview({
  required final List<SkillToolAccess> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const AuraText(
        child: TextLocale(LocaleKeys.skills_selector_preview_tools_title),
        style: .heading4,
      ),
      if (tools.isEmpty)
        const TextLocale(LocaleKeys.skills_selector_preview_no_tools)
      else
        for (final tool in tools) _SkillCapabilityPreviewTool(tool: tool),
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );
}

class const _SkillCapabilityPreviewTool({required final SkillToolAccess tool})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: ExcludeSemantics(
      child: _SkillCapabilityPreviewToolContent(tool: tool),
    ),
    container: true,
    label: _skillCapabilityToolSemanticsLabel(context, tool),
  );
}

class const _SkillCapabilityPreviewToolContent({
  required final SkillToolAccess tool,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _SkillCapabilityPreviewToolHeader(tool: tool),
      _skillCapabilityToolDescription(tool),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _SkillCapabilityPreviewToolHeader({
  required final SkillToolAccess tool,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraText(child: _skillCapabilityToolTitle(tool), style: .heading5),
      TextLocale(_previewToolStatusKey(tool.status)),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

Widget _skillCapabilityToolTitle(SkillToolAccess tool) =>
    switch (tool.titleKey) {
      final key? => TextLocale(key),
      null => Text(tool.title),
    };

Widget _skillCapabilityToolDescription(SkillToolAccess tool) {
  if (tool.descriptionKey case final key?) return TextLocale(key);
  final description = tool.description.trim();
  if (description.isNotEmpty) return Text(description);

  return const TextLocale(LocaleKeys.skills_selector_preview_description_empty);
}

String _skillCapabilityToolSemanticsLabel(
  BuildContext context,
  SkillToolAccess tool,
) => [
  _skillCapabilityToolTitleLabel(context, tool),
  _skillCapabilityToolDescriptionLabel(context, tool),
  _previewToolStatusKey(tool.status).tr(context: context),
].join(', ');

String _skillCapabilityToolTitleLabel(
  BuildContext context,
  SkillToolAccess tool,
) => tool.titleKey?.tr(context: context) ?? tool.title;

String _skillCapabilityToolDescriptionLabel(
  BuildContext context,
  SkillToolAccess tool,
) {
  if (tool.descriptionKey case final key?) return key.tr(context: context);
  final description = tool.description.trim();
  if (description.isNotEmpty) return description;

  return LocaleKeys.skills_selector_preview_description_empty.tr(
    context: context,
  );
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
