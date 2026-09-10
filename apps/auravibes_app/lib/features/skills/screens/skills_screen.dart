// Required: Existing UI spacing uses small numeric values.
// Required: Local builders keep this small screen readable.
// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/usecases/delete_cloud_routed_skill_usecases.dart';
import 'package:auravibes_app/features/skills/usecases/disable_skill_usecase.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _skillScreenIconSize = 48.0;
const _skillScreenListPadding = 8.0;
const _skillScreenRunSpacing = 4.0;
const _skillScreenSpacing = 8.0;

class const SkillsScreen({required final String workspaceId, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _SkillsScreenScaffold(workspaceId: workspaceId);
}

class const _SkillsScreenScaffold({required final String workspaceId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(workspaceSkillsProvider(workspaceId));

    return _SkillsScreenScaffoldView(
      skillsAsync: skillsAsync,
      onCreateSkill: _openCreateSkill,
      onOpenSkill: _openSkill,
      onDeleteSkill: _confirmDeleteSkill,
      onSkillEnabledChanged: (ref, skill, change) =>
          _setSkillEnabled(ref, skill, change.isEnabled),
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

  Future<void> _openSkill(BuildContext context, String skillId) async {
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
    final usecase = ref.read(disableSkillUsecaseProvider(workspaceId));
    await usecase.call((
      workspaceId: workspaceId,
      source: skill.source,
      skillId: skill.id,
      isEnabled: isEnabled,
      slug: skill.slug,
      title: skill.title,
      description: skill.description,
      content: null,
    ));
    ref.invalidate(workspaceSkillsProvider(workspaceId));
  }

  Future<void> _confirmDeleteSkill(
    BuildContext context,
    WidgetRef ref,
    WorkspaceSkill skill,
  ) async {
    if (skill.source != SkillSource.user) return;
    final shouldDelete = await _showDeleteConfirmation(context);
    if (shouldDelete != true) return;

    await _deleteSkill(ref, skill);
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteSkillDialog(),
    );
  }

  Future<void> _deleteSkill(WidgetRef ref, WorkspaceSkill skill) async {
    await ref.read(deleteSkillProvider(workspaceId))(skill.id);
    ref.invalidate(workspaceSkillsProvider(workspaceId));
  }
}

class const _SkillsScreenScaffoldView({
  required final AsyncValue<List<WorkspaceSkill>> skillsAsync,
  required final Future<void> Function(BuildContext context) onCreateSkill,
  required final Future<void> Function(BuildContext context, String skillId)
  onOpenSkill,
  required final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    WorkspaceSkill skill,
  )
  onDeleteSkill,
  required final Future<void> Function(
    WidgetRef ref,
    WorkspaceSkill skill,
    ({bool isEnabled}) change,
  )
  onSkillEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: _SkillsScreenBody(
        skillsAsync: skillsAsync,
        onCreateSkill: onCreateSkill,
        onOpenSkill: onOpenSkill,
        onDeleteSkill: onDeleteSkill,
        onSkillEnabledChanged: onSkillEnabledChanged,
      ),
      appBar: _SkillsScreenAppBar(onCreateSkill: () => onCreateSkill(context)),
    );
  }
}

class const _SkillsScreenAppBar({required final VoidCallback onCreateSkill})
    extends StatelessWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AuraAppBar(
      title: const TextLocale(LocaleKeys.skills_screen_title),
      actions: [
        AuraIconButton(
          icon: Icons.add,
          onPressed: onCreateSkill,
          tooltip: LocaleKeys.skills_screen_create.tr(context: context),
        ),
      ],
      leading: AuraIconButton(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class const _SkillsScreenBody({
  required final AsyncValue<List<WorkspaceSkill>> skillsAsync,
  required final Future<void> Function(BuildContext context) onCreateSkill,
  required final Future<void> Function(BuildContext context, String skillId)
  onOpenSkill,
  required final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    WorkspaceSkill skill,
  )
  onDeleteSkill,
  required final Future<void> Function(
    WidgetRef ref,
    WorkspaceSkill skill,
    ({bool isEnabled}) change,
  )
  onSkillEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillsScreenAsyncContent(
    skillsAsync: skillsAsync,
    onCreateSkill: () => unawaited(onCreateSkill(context)),
    onOpenSkill: (skill) => onOpenSkill(context, skill.id),
    onDeleteSkill: onDeleteSkill,
    onSkillEnabledChanged: onSkillEnabledChanged,
  );
}

class const _SkillsScreenAsyncContent({
  required final AsyncValue<List<WorkspaceSkill>> skillsAsync,
  required final VoidCallback onCreateSkill,
  required final ValueChanged<WorkspaceSkill> onOpenSkill,
  required final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    WorkspaceSkill skill,
  )
  onDeleteSkill,
  required final Future<void> Function(
    WidgetRef ref,
    WorkspaceSkill skill,
    ({bool isEnabled}) change,
  )
  onSkillEnabledChanged,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadedSkills = _loadedSkills();
    if (loadedSkills != null) {
      return _SkillsScreenLoadedAsyncState(
        skills: loadedSkills,
        onCreateSkill: onCreateSkill,
        onOpenSkill: onOpenSkill,
        onDeleteSkill: onDeleteSkill,
        onSkillEnabledChanged: onSkillEnabledChanged,
      );
    }

    return switch (skillsAsync) {
      AsyncLoading() => const Center(child: AuraSpinner()),
      AsyncError(:final error) => _SkillsScreenError(error: error),
      _ => const SizedBox.shrink(),
    };
  }

  List<WorkspaceSkill>? _loadedSkills() => switch (skillsAsync) {
    AsyncData(:final value) => value,
    AsyncLoading(value: final value, hasValue: true) => value,
    _ => null,
  };
}

class const _SkillsScreenLoadedAsyncState({
  required final List<WorkspaceSkill> skills,
  required final VoidCallback onCreateSkill,
  required final ValueChanged<WorkspaceSkill> onOpenSkill,
  required final Future<void> Function(
    BuildContext context,
    WidgetRef ref,
    WorkspaceSkill skill,
  )
  onDeleteSkill,
  required final Future<void> Function(
    WidgetRef ref,
    WorkspaceSkill skill,
    ({bool isEnabled}) change,
  )
  onSkillEnabledChanged,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _SkillsScreenLoadedContent(
        skills: skills,
        onCreateSkill: onCreateSkill,
        onOpenSkill: onOpenSkill,
        onDeleteSkill: (skill) => onDeleteSkill(context, ref, skill),
        onSkillEnabledChanged: (skill, value) =>
            onSkillEnabledChanged(ref, skill, (isEnabled: value)),
      );
}

class const _SkillsScreenError({required this.error}) extends StatelessWidget {
  final Object error;

  @override
  Widget build(BuildContext context) => Center(
    child: AuraText(child: TextLocale(CloudAppErrors.localizationKey(error))),
  );
}

class const _SkillsScreenLoadedContent({
  required final List<WorkspaceSkill> skills,
  required final VoidCallback onCreateSkill,
  required final ValueChanged<WorkspaceSkill> onOpenSkill,
  required final ValueChanged<WorkspaceSkill> onDeleteSkill,
  required final void Function(WorkspaceSkill skill, bool value)
  onSkillEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return _SkillsScreenEmpty(onCreateSkill: onCreateSkill);
    }

    return _SkillsList(
      skills: skills,
      onOpenSkill: onOpenSkill,
      onDeleteSkill: onDeleteSkill,
      onSkillEnabledChanged: onSkillEnabledChanged,
    );
  }
}

class const _SkillsScreenEmpty({required final VoidCallback onCreateSkill})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: AuraColumn(
        children: [
          const Icon(Icons.psychology_alt_outlined, size: _skillScreenIconSize),
          const AuraText(
            child: TextLocale(LocaleKeys.skills_screen_empty_title),
            style: .heading4,
          ),
          const AuraText(
            child: TextLocale(LocaleKeys.skills_screen_empty_subtitle),
            textAlign: .center,
          ),
          AuraButton(
            onPressed: onCreateSkill,
            child: const TextLocale(LocaleKeys.skills_screen_create),
          ),
        ],
        mainAxisSize: .min,
      ),
    );
  }
}

class const _SkillsList({
  required final List<WorkspaceSkill> skills,
  required final ValueChanged<WorkspaceSkill> onOpenSkill,
  required final ValueChanged<WorkspaceSkill> onDeleteSkill,
  required final void Function(WorkspaceSkill skill, bool value)
  onSkillEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillsListView(
    skills: skills,
    itemBuilder: (_, index) => _SkillListItem(
      skill: skills[index],
      onOpenSkill: onOpenSkill,
      onDeleteSkill: onDeleteSkill,
      onSkillEnabledChanged: onSkillEnabledChanged,
    ),
  );
}

class const _SkillsListView({required this.skills, required this.itemBuilder})
    extends StatelessWidget {
  final List<WorkspaceSkill> skills;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(_skillScreenListPadding),
    itemBuilder: itemBuilder,
    separatorBuilder: (_, _) => const SizedBox(height: _skillScreenListPadding),
    itemCount: skills.length,
  );
}

class const _SkillListItem({
  required final WorkspaceSkill skill,
  required final ValueChanged<WorkspaceSkill> onOpenSkill,
  required final ValueChanged<WorkspaceSkill> onDeleteSkill,
  required final void Function(WorkspaceSkill skill, bool value)
  onSkillEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SkillTile(
      skill: skill,
      onOpen: () => onOpenSkill(skill),
      onDelete: () => onDeleteSkill(skill),
      onChanged: (value) => onSkillEnabledChanged(skill, value),
    );
  }
}

class const _SkillTile({
  required final WorkspaceSkill skill,
  required final VoidCallback onOpen,
  required final VoidCallback onDelete,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: _SkillTileRow(
        skill: skill,
        onOpen: onOpen,
        onDelete: onDelete,
        onChanged: onChanged,
      ),
      onTap: onOpen,
      style: .border,
    );
  }
}

class const _SkillTileRow({
  required final WorkspaceSkill skill,
  required final VoidCallback onOpen,
  required final VoidCallback onDelete,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        AuraIcon(_skillIcon(skill)),
        Expanded(child: _SkillTileInfo(skill: skill)),
        _SkillTileActions(
          skill: skill,
          onOpen: onOpen,
          onDelete: onDelete,
          onChanged: onChanged,
        ),
      ],
      spacing: .sm,
    );
  }
}

IconData _skillIcon(WorkspaceSkill skill) => switch (skill.source) {
  .user => Icons.psychology_alt_outlined,
  .app => Icons.auto_awesome_outlined,
};

class const _SkillTileInfo({required final WorkspaceSkill skill})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _SkillTileTitle(skill: skill),
        if (_description(context) case final description?)
          _SkillTileDescription(description: description),
        _SkillTileTags(skill: skill),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
    );
  }

  String? _description(BuildContext context) {
    final description = switch (skill.descriptionKey) {
      null => skill.description,
      final descriptionKey => descriptionKey.tr(context: context),
    };

    if (description.trim().isEmpty) return null;

    return description;
  }
}

class const _SkillTileTitle({required final WorkspaceSkill skill})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(
      child: switch (skill.titleKey) {
        null => Text(skill.title),
        final titleKey => TextLocale(titleKey),
      },
      style: .heading6,
    );
  }
}

class const _SkillTileDescription({required final String description})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GptMarkdown(
      description,
      style: .new(
        color: context.auraColors.onSurfaceVariant,
        fontWeight: context.auraTheme.typography.fontWeightRegular,
      ),
      maxLines: 2,
      overflow: .ellipsis,
    );
  }
}

class const _SkillTileTags({required final WorkspaceSkill skill})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: _skillScreenSpacing,
      runSpacing: _skillScreenRunSpacing,
      children: [
        _SkillChip(label: _sourceLabel(context)),
        _SkillChip(label: _kindLabel(context)),
        _SkillChip(label: skill.slug),
      ],
    );
  }

  String _sourceLabel(BuildContext context) {
    return switch (skill.source) {
      .user => LocaleKeys.skills_screen_source_user.tr(context: context),
      .app => LocaleKeys.skills_screen_source_app.tr(context: context),
    };
  }

  String _kindLabel(BuildContext context) {
    return switch (skill.kind) {
      .template => LocaleKeys.skills_screen_kind_template.tr(context: context),
      .native => LocaleKeys.skills_screen_kind_native.tr(context: context),
    };
  }
}

class const _SkillTileActions({
  required final WorkspaceSkill skill,
  required final VoidCallback onOpen,
  required final VoidCallback onDelete,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        AuraSwitch(value: skill.isEnabled, onChanged: onChanged),
        if (skill.source == SkillSource.user)
          _SkillTileMenu(onOpen: onOpen, onDelete: onDelete),
      ],
      mainAxisSize: .min,
    );
  }
}

class const _SkillTileMenu({
  required final VoidCallback onOpen,
  required final VoidCallback onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraPopupMenuButton(
      items: [
        AuraPopupMenuItem(
          title: Text(LocaleKeys.common_edit.tr(context: context)),
          onTap: onOpen,
        ),
        AuraPopupMenuItem(
          title: Text(LocaleKeys.common_delete.tr(context: context)),
          onTap: onDelete,
          variant: .error,
        ),
      ],
      tooltip: LocaleKeys.common_show_more.tr(context: context),
    );
  }
}

class const _SkillChip({required final String label}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraBadge(
      child: AuraText(child: Text(label), style: .caption),
      variant: .outlined,
      size: .small,
    );
  }
}

class _DeleteSkillDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraConfirmDialog(
      title: const TextLocale(LocaleKeys.skills_screen_delete),
      message: const TextLocale(LocaleKeys.skills_screen_delete_confirm),
      confirmLabel: Text(_label(context, LocaleKeys.common_delete)),
      cancelLabel: Text(_label(context, LocaleKeys.common_cancel)),
      isDestructive: true,
    );
  }

  String _label(BuildContext context, String key) {
    return key.tr(context: context);
  }
}
