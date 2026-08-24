// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/agent_tool_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/agents/usecases/list_agent_tool_overrides_usecase.dart';
import 'package:auravibes_app/features/agents/usecases/list_agents_usecase.dart';
import 'package:auravibes_app/features/agents/usecases/save_agent_tool_overrides_usecase.dart';
import 'package:auravibes_app/features/agents/usecases/save_agent_usecase.dart';
import 'package:auravibes_app/features/markdown/show_markdown_editor.dart';
import 'package:auravibes_app/features/markdown/widgets/markdown_preview_field.dart';
import 'package:auravibes_app/features/skills/models/workspace_skill.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/usecases/disable_skill_usecase.dart';
import 'package:auravibes_app/features/tools/providers/workspace_tools_notifier.dart';
import 'package:auravibes_app/features/tools/widgets/user_tool_type_widgets.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AgentDetailScreen extends ConsumerStatefulWidget {
  const AgentDetailScreen({required this.workspaceId, this.agentId, super.key});

  final String workspaceId;
  final String? agentId;

  @override
  ConsumerState<AgentDetailScreen> createState() => _AgentDetailScreenState();
}

class _AgentDetailScreenState extends ConsumerState<AgentDetailScreen> {
  static const _compactLayoutWidth = 640.0;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _selectedSkills = <AgentSkillRef>{};
  final _toolPermissionModes = <String, AgentToolPermissionMode>{};
  bool _isEnabled = true;
  AgentVisibility _visibility = AgentVisibility.both;
  bool _loaded = false;
  bool _toolOverridesLoaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agentId = widget.agentId;
    if (agentId != null && !_loaded) {
      return FutureBuilder<AgentEntity?>(
        future: ref
            .read(agentRepositoryProvider(widget.workspaceId))
            .getAgentById(agentId),
        builder: (context, snapshot) {
          final agent = snapshot.data;
          if (agent == null) return const Center(child: AuraSpinner());
          _initialize(agent);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
          return const Center(child: AuraSpinner());
        },
      );
    }

    if (agentId != null && !_toolOverridesLoaded) {
      return FutureBuilder<List<AgentToolOverrideEntity>>(
        future: ref
            .read(listAgentToolOverridesUsecaseProvider(widget.workspaceId))
            .call(agentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AuraScreen(child: Center(child: AuraSpinner()));
          }
          _initializeToolOverrides(snapshot.requireData);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
          return const AuraScreen(child: Center(child: AuraSpinner()));
        },
      );
    }
    final skillsAsync = ref.watch(workspaceSkillsProvider(widget.workspaceId));
    final toolsAsync = ref.watch(workspaceToolsProvider(widget.workspaceId));

    return AuraScreen(
      child: switch ((skills: skillsAsync, tools: toolsAsync)) {
        (
          skills: AsyncData(value: final skills),
          tools: AsyncData(value: final tools),
        ) =>
          Column(
            children: [
              Expanded(
                child: _AgentForm(
                  skills: skills,
                  tools: tools,
                  nameController: _nameController,
                  descriptionController: _descriptionController,
                  contentController: _contentController,
                  isEnabled: _isEnabled,
                  visibility: _visibility,
                  selectedSkills: _selectedSkills,
                  toolPermissionModes: _toolPermissionModes,
                  onEnabledChanged: _setEnabled,
                  onVisibilityChanged: _setVisibility,
                  onEditDescription: () => unawaited(_editDescription()),
                  onEditPrompt: () => unawaited(_editPrompt()),
                  onManageSkills: _manageSkills,
                  onManageTools: () =>
                      _showToolPermissionsManager(skills, tools),
                ),
              ),
              _SaveBar(
                isCreate: widget.agentId == null,
                isSaving: _saving,
                onSave: () {
                  if (_saving) return;
                  unawaited(_save());
                },
              ),
            ],
          ),
        (skills: AsyncError(), tools: _) ||
        (skills: _, tools: AsyncError()) => const Center(
          child: AuraText(
            child: TextLocale(LocaleKeys.agents_skills_load_error),
          ),
        ),
        _ => const Center(child: AuraSpinner()),
      },
      appBar: AuraAppBar(
        title: TextLocale(
          widget.agentId == null
              ? LocaleKeys.agents_create
              : LocaleKeys.agents_edit_title,
        ),
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _showSkillsManager({
    required List<WorkspaceSkill> enabledSkills,
    required List<WorkspaceSkill> disabledSkills,
    required List<AgentSkillRef> unavailableRefs,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => _AgentSkillsDialog(
        enabledSkills: enabledSkills,
        disabledSkills: disabledSkills,
        unavailableRefs: unavailableRefs,
        selectedSkills: _selectedSkills,
        onToggle: (skill) {
          setState(() => _toggleSkillValue(skill));
        },
        onEnable: (skill) async {
          await _confirmEnableSkill(skill);
        },
        onRemoveUnavailable: (ref) {
          setState(() {
            final _ = _selectedSkills.remove(ref);
          });
        },
      ),
    );
  }

  void _setEnabled(bool value) => setState(() => _isEnabled = value);

  void _setVisibility(AgentVisibility value) =>
      setState(() => _visibility = value);

  Future<void> _manageSkills({
    required List<WorkspaceSkill> enabledSkills,
    required List<WorkspaceSkill> disabledSkills,
    required List<AgentSkillRef> unavailableRefs,
  }) {
    return _showSkillsManager(
      enabledSkills: enabledSkills,
      disabledSkills: disabledSkills,
      unavailableRefs: unavailableRefs,
    );
  }

  Future<void> _showToolPermissionsManager(
    List<WorkspaceSkill> skills,
    List<WorkspaceToolEntity> tools,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => _AgentToolPermissionsDialog(
        skills: skills,
        selectedSkills: _selectedSkills,
        tools: tools,
        values: _toolPermissionModes,
        onChanged: (toolId, value) {
          setState(() {
            _toolPermissionModes[toolId] = value;
          });
        },
      ),
    );
  }

  void _initialize(AgentEntity agent) {
    _loaded = true;
    _nameController.text = agent.name;
    _descriptionController.text = agent.description;
    _contentController.text = agent.content;
    _isEnabled = agent.isEnabled;
    _visibility = agent.visibility;
    _selectedSkills
      ..clear()
      ..addAll(agent.skills);
  }

  void _initializeToolOverrides(List<AgentToolOverrideEntity> overrides) {
    _toolOverridesLoaded = true;
    _toolPermissionModes
      ..clear()
      ..addEntries(
        overrides.map(
          (override) => MapEntry(
            override.toolId,
            override.permissionMode.agentMode,
          ),
        ),
      );
  }

  void _toggleSkillValue(WorkspaceSkill skill) {
    if (_selectedSkills.contains(skill.ref)) {
      final _ = _selectedSkills.remove(skill.ref);
    } else {
      final _ = _selectedSkills.add(skill.ref);
    }
  }

  Future<void> _editPrompt() async {
    final markdown = await MarkdownEditorLauncher.show(
      context,
      initialMarkdown: _contentController.text,
    );
    if (markdown == null) return;

    _contentController.text = markdown;
  }

  Future<void> _editDescription() async {
    final markdown = await MarkdownEditorLauncher.show(
      context,
      initialMarkdown: _descriptionController.text,
      maxCharacters: AgentLimits.descriptionMaxLength,
    );
    if (markdown == null) return;

    _descriptionController.text = markdown;
  }

  Future<void> _confirmEnableSkill(WorkspaceSkill skill) async {
    final confirmed = await AuraDialogs.confirm(
      context: context,
      title: const TextLocale(LocaleKeys.agents_enable_skill_title),
      message: const TextLocale(LocaleKeys.agents_enable_skill_message),
      actions: const AuraConfirmDialogActions(
        confirmLabel: TextLocale(LocaleKeys.agents_enable_skill_action),
        cancelLabel: TextLocale(LocaleKeys.common_cancel),
      ),
    );
    if (!(confirmed ?? false)) return;

    await ref
        .read(disableSkillUsecaseProvider(widget.workspaceId))
        .call(
          workspaceId: widget.workspaceId,
          source: skill.source,
          skillId: skill.id,
          isEnabled: true,
        );
    final _ = ref.invalidate(workspaceSkillsProvider(widget.workspaceId));
    if (!mounted) return;
    setState(() {
      final _ = _selectedSkills.add(skill.ref);
    });
  }

  Future<void> _save() async {
    final draft = AgentToCreate(
      name: _nameController.text,
      description: _descriptionController.text,
      content: _contentController.text,
      isEnabled: _isEnabled,
      visibility: _visibility,
      skills: _selectedSkills.toList(),
    );
    if (!draft.isValid) {
      final _ = AuraSnackBars.show(
        context: context,
        content: const TextLocale(LocaleKeys.cloud_errors_validation),
        variant: AuraSnackBarVariant.error,
      );

      return;
    }

    setState(() => _saving = true);
    try {
      final usecase = ref.read(saveAgentUsecaseProvider(widget.workspaceId));
      final agentId = widget.agentId;
      final agent = agentId == null
          ? await usecase.create(widget.workspaceId, draft)
          : await usecase.update(
              agentId,
              AgentToUpdate(
                name: _nameController.text,
                description: _descriptionController.text,
                content: _contentController.text,
                isEnabled: _isEnabled,
                visibility: _visibility,
                skills: _selectedSkills.toList(),
              ),
            );
      await _saveToolOverrides(agent.id);
      final _ = ref.invalidate(agentsProvider(widget.workspaceId));
      if (mounted) context.pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveToolOverrides(String agentId) {
    return ref
        .read(saveAgentToolOverridesUsecaseProvider(widget.workspaceId))
        .call(
          agentId: agentId,
          permissionsByToolId: _toolPermissionModes,
        );
  }
}

class _AgentForm extends StatelessWidget {
  const _AgentForm({
    required this.skills,
    required this.tools,
    required this.nameController,
    required this.descriptionController,
    required this.contentController,
    required this.isEnabled,
    required this.visibility,
    required this.selectedSkills,
    required this.toolPermissionModes,
    required this.onEnabledChanged,
    required this.onVisibilityChanged,
    required this.onEditDescription,
    required this.onEditPrompt,
    required this.onManageSkills,
    required this.onManageTools,
  });

  final List<WorkspaceSkill> skills;
  final List<WorkspaceToolEntity> tools;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController contentController;
  final bool isEnabled;
  final AgentVisibility visibility;
  final Set<AgentSkillRef> selectedSkills;
  final Map<String, AgentToolPermissionMode> toolPermissionModes;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<AgentVisibility> onVisibilityChanged;
  final VoidCallback onEditDescription;
  final VoidCallback onEditPrompt;
  final void Function({
    required List<WorkspaceSkill> enabledSkills,
    required List<WorkspaceSkill> disabledSkills,
    required List<AgentSkillRef> unavailableRefs,
  })
  onManageSkills;
  final VoidCallback onManageTools;

  @override
  Widget build(BuildContext context) {
    final enabledSkills = skills.where((skill) => skill.isEnabled).toList();
    final disabledSkills = skills.where((skill) => !skill.isEnabled).toList();
    final unavailableRefs = selectedSkills.where((ref) {
      return !skills.any((skill) => skill.ref == ref);
    }).toList();
    final selectedDisabledCount = disabledSkills
        .where((skill) => selectedSkills.contains(skill.ref))
        .length;
    final overrideCount = toolPermissionModes.entries.where((entry) {
      return entry.value != AgentToolPermissionMode.workspaceDefault &&
          tools.any((tool) => tool.id == entry.key);
    }).length;
    final missingToolOverrideCount = toolPermissionModes.entries.where((entry) {
      return entry.value != AgentToolPermissionMode.workspaceDefault &&
          !tools.any((tool) => tool.id == entry.key);
    }).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PromptCard(
          nameController: nameController,
          descriptionController: descriptionController,
          contentController: contentController,
          isEnabled: isEnabled,
          visibility: visibility,
          onEnabledChanged: onEnabledChanged,
          onVisibilityChanged: onVisibilityChanged,
          onEditDescription: onEditDescription,
          onEditPrompt: onEditPrompt,
        ),
        const SizedBox(height: 16),
        _SkillsSummaryCard(
          selectedCount: selectedSkills.length,
          availableCount: enabledSkills.length,
          disabledSelectedCount: selectedDisabledCount,
          unavailableCount: unavailableRefs.length,
          onManage: () => onManageSkills(
            enabledSkills: enabledSkills,
            disabledSkills: disabledSkills,
            unavailableRefs: unavailableRefs,
          ),
        ),
        const SizedBox(height: 16),
        _ToolPermissionsSummaryCard(
          overrideCount: overrideCount,
          missingOverrideCount: missingToolOverrideCount,
          onManage: onManageTools,
        ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.nameController,
    required this.descriptionController,
    required this.contentController,
    required this.isEnabled,
    required this.visibility,
    required this.onEnabledChanged,
    required this.onVisibilityChanged,
    required this.onEditDescription,
    required this.onEditPrompt,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController contentController;
  final bool isEnabled;
  final AgentVisibility visibility;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<AgentVisibility> onVisibilityChanged;
  final VoidCallback onEditDescription;
  final VoidCallback onEditPrompt;

  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: AuraColumn(
        children: [
          const AuraText(
            child: TextLocale(LocaleKeys.agents_profile_prompt_title),
            style: AuraTextStyle.heading5,
          ),
          const AuraText(
            child: TextLocale(LocaleKeys.agents_profile_prompt_description),
            style: AuraTextStyle.bodySmall,
          ),
          AuraInput(
            controller: nameController,
            label: Text(LocaleKeys.agents_name_label.tr(context: context)),
          ),
          Row(
            children: [
              const Expanded(
                child: AuraColumn(
                  children: [
                    AuraText(
                      child: TextLocale(LocaleKeys.agents_enabled_label),
                    ),
                    AuraText(
                      child: TextLocale(LocaleKeys.agents_enabled_description),
                      style: AuraTextStyle.bodySmall,
                    ),
                  ],
                  spacing: .xs,
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
              ),
              AuraSwitch(value: isEnabled, onChanged: onEnabledChanged),
            ],
          ),
          AuraRadioGroup<AgentVisibility>(
            value: visibility,
            onChanged: (value) {
              if (value == null) return;
              onVisibilityChanged(value);
            },
            options: const [
              AuraRadioOption(
                value: AgentVisibility.chatSelector,
                label: TextLocale(LocaleKeys.agents_visibility_chat_selector),
              ),
              AuraRadioOption(
                value: AgentVisibility.subAgentList,
                label: TextLocale(LocaleKeys.agents_visibility_sub_agent_list),
              ),
              AuraRadioOption(
                value: AgentVisibility.both,
                label: TextLocale(LocaleKeys.agents_visibility_both),
              ),
            ],
            label: const AuraText(
              child: TextLocale(LocaleKeys.agents_visibility_label),
            ),
          ),
          MarkdownPreviewField(
            controller: descriptionController,
            titleKey: LocaleKeys.agents_description_label,
            editKey: LocaleKeys.agents_edit_description,
            emptyKey: LocaleKeys.agents_description_empty,
            onEdit: onEditDescription,
          ),
          MarkdownPreviewField(
            controller: contentController,
            titleKey: LocaleKeys.agents_prompt_label,
            editKey: LocaleKeys.agents_edit_prompt,
            emptyKey: LocaleKeys.agents_prompt_empty,
            onEdit: onEditPrompt,
          ),
        ],
        spacing: .md,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}

class _SkillsSummaryCard extends StatelessWidget {
  const _SkillsSummaryCard({
    required this.selectedCount,
    required this.availableCount,
    required this.disabledSelectedCount,
    required this.unavailableCount,
    required this.onManage,
  });

  final int selectedCount;
  final int availableCount;
  final int disabledSelectedCount;
  final int unavailableCount;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final hasWarning = disabledSelectedCount > 0 || unavailableCount > 0;

    return AuraCard(
      child: AuraColumn(
        children: [
          _CardHeader(
            title: const TextLocale(LocaleKeys.agents_skills_title),
            actionLabel: const TextLocale(LocaleKeys.agents_manage_skills),
            onAction: onManage,
          ),
          AuraText(
            child: Text(
              LocaleKeys.agents_skills_summary.tr(
                namedArgs: {
                  'selected': selectedCount.toString(),
                  'available': availableCount.toString(),
                },
                context: context,
              ),
            ),
            style: AuraTextStyle.bodySmall,
          ),
          if (hasWarning)
            _WarningTile(
              label: LocaleKeys.agents_skills_warning_summary.tr(
                namedArgs: {
                  'disabled': disabledSelectedCount.toString(),
                  'unavailable': unavailableCount.toString(),
                },
                context: context,
              ),
              onTap: onManage,
            ),
        ],
        spacing: .sm,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}

class _ToolPermissionsSummaryCard extends StatelessWidget {
  const _ToolPermissionsSummaryCard({
    required this.overrideCount,
    required this.missingOverrideCount,
    required this.onManage,
  });

  final int overrideCount;
  final int missingOverrideCount;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: AuraColumn(
        children: [
          _CardHeader(
            title: const TextLocale(LocaleKeys.agents_tool_permissions_title),
            actionLabel: const TextLocale(
              LocaleKeys.agents_manage_tool_permissions,
            ),
            onAction: onManage,
          ),
          AuraText(
            child: Text(
              overrideCount == 0
                  ? LocaleKeys.agents_tool_permissions_default_summary.tr(
                      context: context,
                    )
                  : LocaleKeys.agents_tool_permissions_override_summary.tr(
                      namedArgs: {'count': overrideCount.toString()},
                      context: context,
                    ),
            ),
            style: AuraTextStyle.bodySmall,
          ),
          if (missingOverrideCount > 0)
            _WarningTile(
              label: LocaleKeys.agents_tool_permissions_warning_summary.tr(
                namedArgs: {'count': missingOverrideCount.toString()},
                context: context,
              ),
              onTap: onManage,
            ),
        ],
        spacing: .sm,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final Widget title;
  final Widget actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        Expanded(
          child: AuraText(
            child: title,
            style: AuraTextStyle.heading5,
          ),
        ),
        AuraButton(
          onPressed: onAction,
          child: actionLabel,
          variant: AuraButtonVariant.text,
        ),
      ],
      spacing: .sm,
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isCreate,
    required this.isSaving,
    required this.onSave,
  });

  final bool isCreate;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.auraColors.surface,
          border: Border(
            top: BorderSide(color: context.auraColors.outlineVariant),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final button = SizedBox(
              width: constraints.maxWidth < 640 ? double.infinity : 220,
              child: AuraButton(
                onPressed: onSave,
                child: TextLocale(
                  isCreate ? LocaleKeys.agents_create : LocaleKeys.common_save,
                ),
              ),
            );

            return constraints.maxWidth <
                    _AgentDetailScreenState._compactLayoutWidth
                ? button
                : Align(alignment: Alignment.centerRight, child: button);
          },
        ),
      ),
    );
  }
}

class _WarningTile extends StatelessWidget {
  const _WarningTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: Text(label),
      onTap: onTap,
      variant: AuraTileVariant.surface,
      leading: const AuraIcon(Icons.warning_amber_outlined),
      trailing: const AuraIcon(Icons.arrow_forward_ios),
    );
  }
}

class _AgentSkillsDialog extends StatefulWidget {
  const _AgentSkillsDialog({
    required this.enabledSkills,
    required this.disabledSkills,
    required this.unavailableRefs,
    required this.selectedSkills,
    required this.onToggle,
    required this.onEnable,
    required this.onRemoveUnavailable,
  });

  final List<WorkspaceSkill> enabledSkills;
  final List<WorkspaceSkill> disabledSkills;
  final List<AgentSkillRef> unavailableRefs;
  final Set<AgentSkillRef> selectedSkills;
  final ValueChanged<WorkspaceSkill> onToggle;
  final Future<void> Function(WorkspaceSkill skill) onEnable;
  final ValueChanged<AgentSkillRef> onRemoveUnavailable;

  @override
  State<_AgentSkillsDialog> createState() => _AgentSkillsDialogState();
}

class _AgentSkillsDialogState extends State<_AgentSkillsDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final selectedSkills = widget.enabledSkills.where((skill) {
      return widget.selectedSkills.contains(skill.ref);
    }).toList();
    final availableSkills = widget.enabledSkills.where((skill) {
      return !widget.selectedSkills.contains(skill.ref) && skill.matches(query);
    }).toList();
    final disabledSkills = widget.disabledSkills.where((skill) {
      return skill.matches(query);
    }).toList();

    return _AgentManageDialog(
      title: const TextLocale(LocaleKeys.agents_manage_skills_title),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AuraInput(
            controller: _searchController,
            label: Text(
              LocaleKeys.agents_manage_skills_search.tr(context: context),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          _SkillSection(
            title: const TextLocale(LocaleKeys.agents_manage_selected_section),
            empty: const TextLocale(LocaleKeys.agents_manage_selected_empty),
            skills: selectedSkills,
            selectedSkills: widget.selectedSkills,
            onTap: _toggle,
          ),
          _SkillSection(
            title: const TextLocale(LocaleKeys.agents_manage_available_section),
            empty: const TextLocale(LocaleKeys.agents_manage_available_empty),
            skills: availableSkills,
            selectedSkills: widget.selectedSkills,
            onTap: _toggle,
          ),
          _SkillSection(
            title: const TextLocale(LocaleKeys.agents_disabled_skills_title),
            empty: const TextLocale(LocaleKeys.agents_disabled_skills_empty),
            skills: disabledSkills,
            selectedSkills: widget.selectedSkills,
            onTap: (skill) => unawaited(_enable(skill)),
            disabled: true,
          ),
          if (widget.unavailableRefs.isNotEmpty)
            _UnavailableSkillSection(
              refs: widget.unavailableRefs,
              onRemove: (ref) {
                setState(() => widget.onRemoveUnavailable(ref));
              },
            ),
        ],
      ),
    );
  }

  void _toggle(WorkspaceSkill skill) {
    setState(() => widget.onToggle(skill));
  }

  Future<void> _enable(WorkspaceSkill skill) async {
    await widget.onEnable(skill);
    if (mounted) setState(() => _query = _searchController.text);
  }
}

class _AgentToolPermissionsDialog extends StatefulWidget {
  const _AgentToolPermissionsDialog({
    required this.skills,
    required this.selectedSkills,
    required this.tools,
    required this.values,
    required this.onChanged,
  });

  final List<WorkspaceSkill> skills;
  final Set<AgentSkillRef> selectedSkills;
  final List<WorkspaceToolEntity> tools;
  final Map<String, AgentToolPermissionMode> values;
  final void Function(String toolId, AgentToolPermissionMode value) onChanged;

  @override
  State<_AgentToolPermissionsDialog> createState() =>
      _AgentToolPermissionsDialogState();
}

class _AgentToolPermissionsDialogState
    extends State<_AgentToolPermissionsDialog> {
  final _searchController = TextEditingController();
  final _collapsedToolGroups = <String>{};
  final _expandedToolGroups = <String>{};
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final visibleTools = widget.tools
        .where((tool) => tool.matches(query))
        .toList();
    final overrideTools = visibleTools.where((tool) {
      return _value(tool.id) != AgentToolPermissionMode.workspaceDefault;
    }).toList();
    final defaultTools = visibleTools.where((tool) {
      return _value(tool.id) == AgentToolPermissionMode.workspaceDefault;
    }).toList();
    final grouped = _groupDefaultTools(defaultTools, visibleTools);

    return _AgentManageDialog(
      title: const TextLocale(LocaleKeys.agents_manage_tool_permissions_title),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AuraInput(
            controller: _searchController,
            label: Text(
              LocaleKeys.agents_manage_tool_permissions_search.tr(
                context: context,
              ),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          _ToolSection(
            title: const TextLocale(LocaleKeys.agents_manage_overrides_section),
            empty: const TextLocale(LocaleKeys.agents_manage_overrides_empty),
            tools: overrideTools,
            valueOf: _value,
            onChanged: _change,
          ),
          for (final group in grouped.selectedSkillGroups)
            _CollapsibleToolSection(
              title: group.title,
              empty: const TextLocale(
                LocaleKeys.agents_manage_selected_skill_tools_empty,
              ),
              isExpanded: _isGroupExpanded(group, query),
              onToggle: () => _toggleGroup(group, query),
              tools: group.tools,
              valueOf: _value,
              onChanged: _change,
            ),
          for (final group in grouped.otherSkillGroups)
            _CollapsibleToolSection(
              title: group.title,
              empty: const TextLocale(
                LocaleKeys.agents_manage_other_skill_tools_empty,
              ),
              isExpanded: _isGroupExpanded(group, query),
              onToggle: () => _toggleGroup(group, query),
              tools: group.tools,
              valueOf: _value,
              onChanged: _change,
            ),
          _ToolSection(
            title: const TextLocale(
              LocaleKeys.agents_manage_skill_controls_section,
            ),
            empty: const TextLocale(
              LocaleKeys.agents_manage_skill_controls_empty,
            ),
            tools: grouped.skillControls,
            valueOf: _value,
            onChanged: _change,
          ),
          _ToolSection(
            title: const TextLocale(
              LocaleKeys.agents_manage_other_workspace_tools_section,
            ),
            empty: const TextLocale(
              LocaleKeys.agents_manage_other_workspace_tools_empty,
            ),
            tools: grouped.otherWorkspaceTools,
            valueOf: _value,
            onChanged: _change,
          ),
        ],
      ),
    );
  }

  _GroupedTools _groupDefaultTools(
    List<WorkspaceToolEntity> tools,
    List<WorkspaceToolEntity> visibleTools,
  ) {
    final selectedSkillGroups = <_ToolGroup>[];
    final otherSkillGroups = <_ToolGroup>[];
    final skillControls = <WorkspaceToolEntity>[];
    final otherWorkspaceTools = <WorkspaceToolEntity>[];
    final groupByKey = <String, _ToolGroup>{};

    for (final tool in tools) {
      if (_isSkillControlTool(tool.toolId)) {
        skillControls.add(tool);
        continue;
      }

      final parsed = ToolNameFormatter.parseSkillToolName(tool.toolId);
      if (parsed == null) {
        otherWorkspaceTools.add(tool);
        continue;
      }

      final key = '${parsed.source}:${parsed.skillSlug}';
      final group = groupByKey.putIfAbsent(key, () {
        final skill = _findSkill(parsed.source, parsed.skillSlug);
        final selected =
            skill != null && widget.selectedSkills.contains(skill.ref);
        final title = _skillGroupTitle(skill, parsed.skillSlug);
        final created = _ToolGroup(
          key: key,
          title: title,
          tools: [],
          overrideCount: _skillGroupOverrideCount(
            source: parsed.source,
            skillSlug: parsed.skillSlug,
            tools: visibleTools,
          ),
        );
        if (selected) {
          selectedSkillGroups.add(created);
        } else {
          otherSkillGroups.add(created);
        }

        return created;
      });
      group.tools.add(tool);
    }

    return _GroupedTools(
      selectedSkillGroups: selectedSkillGroups,
      otherSkillGroups: otherSkillGroups,
      skillControls: skillControls,
      otherWorkspaceTools: otherWorkspaceTools,
    );
  }

  WorkspaceSkill? _findSkill(String source, String slug) {
    for (final skill in widget.skills) {
      final expectedSource = switch (skill.source) {
        SkillSource.user => 'user',
        SkillSource.app => 'app',
      };
      if (expectedSource == source && skill.slug == slug) return skill;
    }

    return null;
  }

  String _skillGroupTitle(WorkspaceSkill? skill, String fallbackSlug) {
    return skill?.title ?? fallbackSlug.toHumanReadable();
  }

  bool _isSkillControlTool(String toolId) {
    return toolId == 'load_skill' ||
        toolId == 'unload_skill' ||
        toolId == 'list_skill_credentials';
  }

  AgentToolPermissionMode _value(String toolId) {
    return widget.values[toolId] ?? AgentToolPermissionMode.workspaceDefault;
  }

  int _skillGroupOverrideCount({
    required String source,
    required String skillSlug,
    required List<WorkspaceToolEntity> tools,
  }) {
    return tools.where((tool) {
      final parsed = ToolNameFormatter.parseSkillToolName(tool.toolId);

      return parsed?.source == source &&
          parsed?.skillSlug == skillSlug &&
          _value(tool.id) != AgentToolPermissionMode.workspaceDefault;
    }).length;
  }

  bool _isGroupExpanded(_ToolGroup group, String query) {
    if (query.isNotEmpty) return true;
    if (_collapsedToolGroups.contains(group.key)) return false;
    if (_expandedToolGroups.contains(group.key)) return true;

    return group.overrideCount > 0;
  }

  void _toggleGroup(_ToolGroup group, String query) {
    if (query.isNotEmpty) return;

    final isExpanded = _isGroupExpanded(group, query);
    setState(() {
      if (isExpanded) {
        final _ = _expandedToolGroups.remove(group.key);
        final _ = _collapsedToolGroups.add(group.key);
      } else {
        final _ = _collapsedToolGroups.remove(group.key);
        final _ = _expandedToolGroups.add(group.key);
      }
    });
  }

  void _change(String toolId, AgentToolPermissionMode value) {
    setState(() => widget.onChanged(toolId, value));
  }
}

class _GroupedTools {
  const _GroupedTools({
    required this.selectedSkillGroups,
    required this.otherSkillGroups,
    required this.skillControls,
    required this.otherWorkspaceTools,
  });

  final List<_ToolGroup> selectedSkillGroups;
  final List<_ToolGroup> otherSkillGroups;
  final List<WorkspaceToolEntity> skillControls;
  final List<WorkspaceToolEntity> otherWorkspaceTools;
}

class _ToolGroup {
  const _ToolGroup({
    required this.key,
    required this.title,
    required this.tools,
    required this.overrideCount,
  });

  final String key;
  final String title;
  final List<WorkspaceToolEntity> tools;
  final int overrideCount;
}

class _AgentManageDialog extends StatelessWidget {
  const _AgentManageDialog({required this.title, required this.child});

  final Widget title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(context.auraTheme.fromBorderRadius(.xl)),
        ),
      ),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
              child: AuraRow(
                children: [
                  Expanded(
                    child: AuraText(
                      child: title,
                      style: AuraTextStyle.heading5,
                    ),
                  ),
                  AuraIconButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                    semanticLabel: LocaleKeys.common_close_dialog.tr(),
                  ),
                ],
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

class _SkillSection extends StatelessWidget {
  const _SkillSection({
    required this.title,
    required this.empty,
    required this.skills,
    required this.selectedSkills,
    required this.onTap,
    this.disabled = false,
  });

  final Widget title;
  final Widget empty;
  final List<WorkspaceSkill> skills;
  final Set<AgentSkillRef> selectedSkills;
  final ValueChanged<WorkspaceSkill> onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return _DialogSection(
      title: title,
      empty: empty,
      children: [
        for (final skill in skills)
          _AgentSkillTile(
            skill: skill,
            selected: selectedSkills.contains(skill.ref),
            onTap: () => onTap(skill),
            disabled: disabled,
          ),
      ],
      isEmpty: skills.isEmpty,
    );
  }
}

class _UnavailableSkillSection extends StatelessWidget {
  const _UnavailableSkillSection({required this.refs, required this.onRemove});

  final List<AgentSkillRef> refs;
  final ValueChanged<AgentSkillRef> onRemove;

  @override
  Widget build(BuildContext context) {
    return _DialogSection(
      title: const TextLocale(LocaleKeys.agents_unavailable_skills_title),
      empty: const SizedBox.shrink(),
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.agents_disabled_skills_warning),
          style: AuraTextStyle.bodySmall,
        ),
        for (final ref in refs)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AuraTile(
              child: AuraColumn(
                children: [
                  const TextLocale(LocaleKeys.agents_disabled_skill_label),
                  Text(ref.label),
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              onTap: () => onRemove(ref),
              variant: AuraTileVariant.surface,
              leading: const AuraIcon(Icons.warning_amber_outlined),
              trailing: const AuraIcon(Icons.close),
            ),
          ),
      ],
      isEmpty: false,
    );
  }
}

class _ToolSection extends StatelessWidget {
  const _ToolSection({
    required this.title,
    required this.empty,
    required this.tools,
    required this.valueOf,
    required this.onChanged,
  });

  final Widget title;
  final Widget empty;
  final List<WorkspaceToolEntity> tools;
  final AgentToolPermissionMode Function(String toolId) valueOf;
  final void Function(String toolId, AgentToolPermissionMode value) onChanged;

  @override
  Widget build(BuildContext context) {
    return _DialogSection(
      title: title,
      empty: empty,
      children: [
        for (final tool in tools)
          _AgentToolPermissionTile(
            tool: tool,
            value: valueOf(tool.id),
            onChanged: (value) => onChanged(tool.id, value),
          ),
      ],
      isEmpty: tools.isEmpty,
    );
  }
}

class _CollapsibleToolSection extends StatelessWidget {
  const _CollapsibleToolSection({
    required this.title,
    required this.empty,
    required this.isExpanded,
    required this.onToggle,
    required this.tools,
    required this.valueOf,
    required this.onChanged,
  });

  final String title;
  final Widget empty;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<WorkspaceToolEntity> tools;
  final AgentToolPermissionMode Function(String toolId) valueOf;
  final void Function(String toolId, AgentToolPermissionMode value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AuraColumn(
        children: [
          AuraTile(
            child: AuraColumn(
              children: [
                Text(title),
              ],
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
            onTap: onToggle,
            variant: AuraTileVariant.surface,
            leading: AuraIcon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
          ),
          if (isExpanded)
            if (tools.isEmpty)
              AuraText(child: empty, style: AuraTextStyle.bodySmall)
            else
              for (final tool in tools)
                _AgentToolPermissionTile(
                  tool: tool,
                  value: valueOf(tool.id),
                  onChanged: (value) => onChanged(tool.id, value),
                ),
        ],
        spacing: .sm,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}

class _DialogSection extends StatelessWidget {
  const _DialogSection({
    required this.title,
    required this.empty,
    required this.children,
    required this.isEmpty,
  });

  final Widget title;
  final Widget empty;
  final List<Widget> children;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AuraColumn(
        children: [
          AuraText(child: title, style: AuraTextStyle.heading6),
          if (isEmpty)
            AuraText(child: empty, style: AuraTextStyle.bodySmall)
          else
            ...children,
        ],
        spacing: .sm,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}

class _AgentSkillTile extends StatelessWidget {
  const _AgentSkillTile({
    required this.skill,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  final WorkspaceSkill skill;
  final bool selected;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AuraTile(
        child: AuraColumn(
          children: [
            _SkillTitle(skill: skill),
            AuraText(
              child: Text(skill.source.name),
              style: AuraTextStyle.bodySmall,
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        onTap: onTap,
        variant: selected ? AuraTileVariant.selected : AuraTileVariant.surface,
        leading: AuraIcon(
          disabled ? Icons.lock_outline : Icons.psychology_alt_outlined,
        ),
        trailing: AuraIcon(
          selected ? Icons.check_circle : Icons.radio_button_unchecked,
        ),
      ),
    );
  }
}

class _SkillTitle extends StatelessWidget {
  const _SkillTitle({required this.skill});

  final WorkspaceSkill skill;

  @override
  Widget build(BuildContext context) {
    final titleKey = skill.titleKey;

    return titleKey == null ? Text(skill.title) : TextLocale(titleKey);
  }
}

class _AgentToolPermissionTile extends StatelessWidget {
  const _AgentToolPermissionTile({
    required this.tool,
    required this.value,
    required this.onChanged,
  });

  final WorkspaceToolEntity tool;
  final AgentToolPermissionMode value;
  final ValueChanged<AgentToolPermissionMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AuraTile(
        child: AuraColumn(
          children: [
            AuraText(child: tool.getNameWidget()),
            AuraText(
              child: DefaultTextStyle.merge(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                child: tool.getDescriptionWidget(),
              ),
              style: AuraTextStyle.bodySmall,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: AuraButtonGroup<AgentToolPermissionMode>.single(
                items: const [
                  AuraButtonGroupItem(
                    value: AgentToolPermissionMode.workspaceDefault,
                    child: TextLocale(
                      LocaleKeys.agents_tool_permission_workspace_default,
                    ),
                  ),
                  AuraButtonGroupItem(
                    value: AgentToolPermissionMode.alwaysAsk,
                    child: TextLocale(
                      LocaleKeys.tools_screen_permission_always_ask,
                    ),
                  ),
                  AuraButtonGroupItem(
                    value: AgentToolPermissionMode.alwaysAllow,
                    child: TextLocale(
                      LocaleKeys.tools_screen_permission_always_allow,
                    ),
                  ),
                  AuraButtonGroupItem(
                    value: AgentToolPermissionMode.alwaysDeny,
                    child: TextLocale(
                      LocaleKeys.agents_tool_permission_deny,
                    ),
                  ),
                ],
                selectedValue: value,
                onChanged: onChanged,
                size: AuraButtonGroupSize.sm,
              ),
            ),
          ],
          spacing: .xs,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        variant: AuraTileVariant.surface,
        leading: AuraText(child: tool.getIconWidget()),
      ),
    );
  }
}

extension on WorkspaceSkill {
  AgentSkillRef get ref {
    return switch (source) {
      SkillSource.user => AgentSkillRef.user(id),
      SkillSource.app => AgentSkillRef.app(id),
    };
  }

  bool matches(String query) {
    if (query.isEmpty) return true;

    return title.toLowerCase().contains(query) ||
        description.toLowerCase().contains(query) ||
        id.toLowerCase().contains(query);
  }
}

extension on WorkspaceToolEntity {
  bool matches(String query) {
    if (query.isEmpty) return true;

    return toolId.toLowerCase().contains(query) ||
        (description?.toLowerCase().contains(query) ?? false);
  }
}

extension on AgentSkillRef {
  String get label {
    return switch (this) {
      UserAgentSkillRef(:final skillId) => skillId,
      AppAgentSkillRef(:final identifier) => identifier,
    };
  }
}
