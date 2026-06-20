// Required: Existing UI spacing uses small numeric values.
// Required: Local builders keep this small screen readable.
// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/usecases/disable_skill_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({required this.workspaceId, super.key});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(workspaceSkillsProvider(workspaceId));

    return AuraScreen(
      child: switch (skillsAsync) {
        AsyncData(:final value) => _SkillsScreenBody(
          skills: value,
          onOpenSkill: _openSkill,
          onDeleteSkill: _confirmDeleteSkill,
          onSkillEnabledChanged: (ref, skill, change) =>
              _setSkillEnabled(ref, skill, change.isEnabled),
        ),
        AsyncLoading(:final value?) => _SkillsScreenBody(
          skills: value,
          onOpenSkill: _openSkill,
          onDeleteSkill: _confirmDeleteSkill,
          onSkillEnabledChanged: (ref, skill, change) =>
              _setSkillEnabled(ref, skill, change.isEnabled),
        ),
        AsyncLoading() => const Center(child: AuraSpinner()),
        AsyncError() => const Center(
          child: AuraText(
            child: TextLocale(LocaleKeys.skills_screen_load_error),
          ),
        ),
      },
      appBar: AuraAppBar(
        title: const TextLocale(LocaleKeys.skills_screen_title),
        actions: [
          AuraIconButton(
            icon: Icons.add,
            onPressed: () => _openCreateSkill(context),
            tooltip: LocaleKeys.skills_screen_create.tr(context: context),
          ),
        ],
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _openCreateSkill(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final result = await context.push<bool>(
      '/workspaces/$workspaceId/more/skills/new',
    );
    if (result == true) {
      _scheduleWorkspaceSkillsRefresh(container);
    }
  }

  Future<void> _openSkill(
    BuildContext context,
    String skillId,
  ) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final result = await context.push<bool>(
      '/workspaces/$workspaceId/more/skills/$skillId',
    );
    if (result == true) {
      _scheduleWorkspaceSkillsRefresh(container);
    }
  }

  void _scheduleWorkspaceSkillsRefresh(ProviderContainer container) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshWorkspaceSkillsAfterFrame(container));
    });
  }

  Future<void> _refreshWorkspaceSkillsAfterFrame(
    ProviderContainer container,
  ) async {
    await container.pump();
    container.invalidate(workspaceSkillsProvider(workspaceId));
  }

  Future<void> _setSkillEnabled(
    WidgetRef ref,
    WorkspaceSkill skill,
    bool isEnabled,
  ) async {
    final usecase = ref.read(disableSkillUsecaseProvider);
    await usecase.call(
      workspaceId: workspaceId,
      source: skill.source,
      skillId: skill.id,
      isEnabled: isEnabled,
    );
    ref.invalidate(workspaceSkillsProvider(workspaceId));
  }

  Future<void> _confirmDeleteSkill(
    BuildContext context,
    WidgetRef ref,
    WorkspaceSkill skill,
  ) async {
    if (skill.source != SkillSource.user) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AuraConfirmDialog(
        title: const TextLocale(LocaleKeys.skills_screen_delete),
        message: const TextLocale(LocaleKeys.skills_screen_delete_confirm),
        confirmLabel: Text(LocaleKeys.common_delete.tr(context: context)),
        cancelLabel: Text(LocaleKeys.common_cancel.tr(context: context)),
        isDestructive: true,
      ),
    );
    if (shouldDelete != true) return;

    final _ = await ref.read(skillsRepositoryProvider).deleteSkill(skill.id);
    ref.invalidate(workspaceSkillsProvider(workspaceId));
  }
}

class _SkillsScreenBody extends ConsumerWidget {
  const _SkillsScreenBody({
    required this.skills,
    required this.onOpenSkill,
    required this.onDeleteSkill,
    required this.onSkillEnabledChanged,
  });

  final List<WorkspaceSkill> skills;
  final Future<void> Function(BuildContext context, String skillId) onOpenSkill;
  final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    WorkspaceSkill skill,
  )
  onDeleteSkill;
  final Future<void> Function(
    WidgetRef ref,
    WorkspaceSkill skill,
    ({bool isEnabled}) change,
  )
  onSkillEnabledChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (skills.isEmpty) {
      return const Center(
        child: AuraColumn(
          children: [
            Icon(Icons.psychology_alt_outlined, size: 48),
            AuraText(
              child: TextLocale(LocaleKeys.skills_screen_empty_title),
              style: AuraTextStyle.heading4,
            ),
            AuraText(
              child: TextLocale(LocaleKeys.skills_screen_empty_subtitle),
              textAlign: TextAlign.center,
              color: AuraColorVariant.onSurfaceVariant,
            ),
          ],
          mainAxisSize: MainAxisSize.min,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final skill = skills[index];

        return _SkillTile(
          skill: skill,
          onOpen: () => onOpenSkill(context, skill.id),
          onDelete: () => onDeleteSkill(context, ref, skill),
          onChanged: (value) =>
              onSkillEnabledChanged(ref, skill, (isEnabled: value)),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemCount: skills.length,
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({
    required this.skill,
    required this.onOpen,
    required this.onDelete,
    required this.onChanged,
  });

  final WorkspaceSkill skill;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: AuraTile(
        child: AuraColumn(
          children: [
            AuraText(
              child: switch (skill.titleKey) {
                null => Text(skill.title),
                final titleKey => TextLocale(titleKey),
              },
            ),
            if (skill.descriptionKey case final descriptionKey?)
              AuraText(
                child: TextLocale(descriptionKey),
                color: AuraColorVariant.onSurfaceVariant,
              )
            else if (skill.description.isNotEmpty)
              AuraText(
                child: Text(skill.description),
                color: AuraColorVariant.onSurfaceVariant,
              ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _SkillChip(label: _sourceLabel(context)),
                _SkillChip(label: _kindLabel(context)),
                _SkillChip(label: skill.slug),
              ],
            ),
          ],
          spacing: AuraSpacing.xs,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        onTap: onOpen,
        variant: AuraTileVariant.ghost,
        leading: AuraIcon(_icon),
        trailing: AuraRow(
          children: [
            AuraSwitch(value: skill.isEnabled, onChanged: onChanged),
            if (skill.source == SkillSource.user)
              AuraPopupMenuButton(
                items: [
                  AuraPopupMenuItem(
                    title: Text(LocaleKeys.common_edit.tr(context: context)),
                    onTap: onOpen,
                  ),
                  AuraPopupMenuItem(
                    title: Text(LocaleKeys.common_delete.tr(context: context)),
                    onTap: onDelete,
                    variant: AuraTileVariant.error,
                  ),
                ],
                tooltip: LocaleKeys.common_show_more.tr(context: context),
              ),
          ],
          mainAxisSize: MainAxisSize.min,
        ),
      ),
      onTap: onOpen,
    );
  }

  IconData get _icon {
    return switch (skill.source) {
      SkillSource.user => Icons.psychology_alt_outlined,
      SkillSource.app => Icons.auto_awesome_outlined,
    };
  }

  String _sourceLabel(BuildContext context) {
    return switch (skill.source) {
      SkillSource.user => LocaleKeys.skills_screen_source_user.tr(
        context: context,
      ),
      SkillSource.app => LocaleKeys.skills_screen_source_app.tr(
        context: context,
      ),
    };
  }

  String _kindLabel(BuildContext context) {
    return switch (skill.kind) {
      SkillKind.template => LocaleKeys.skills_screen_kind_template.tr(
        context: context,
      ),
      SkillKind.native => LocaleKeys.skills_screen_kind_native.tr(
        context: context,
      ),
    };
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final chipTextStyle = auraResolveTextStyle(
      style: AuraTextStyle.caption,
      colors: auraColors,
    ).copyWith(color: auraColors.onSurfaceVariant);

    return Chip(
      label: Text(label, style: chipTextStyle),
      side: BorderSide(color: auraColors.outline),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      backgroundColor: auraColors.surfaceVariant,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
