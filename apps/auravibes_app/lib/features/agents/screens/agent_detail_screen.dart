// Required: Feature widgets keep closely related private widgets together.
import 'dart:async';

import 'package:auravibes_app/domain/entities/agent_entity.dart';
import 'package:auravibes_app/domain/entities/agent_tool_override_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/agents/usecases/list_agent_tool_overrides_usecase.dart';
import 'package:auravibes_app/features/agents/usecases/save_agent_tool_overrides_usecase.dart';
import 'package:auravibes_app/features/agents/usecases/save_agent_usecase.dart';
import 'package:auravibes_app/features/markdown/markdown_editor_launcher.dart';
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

const List<AuraChoiceOption<AgentVisibility>> _agentVisibilityOptions = [
  AuraChoiceOption(
    value: AgentVisibility.chatSelector,
    label: TextLocale(LocaleKeys.agents_visibility_chat_selector),
  ),
  AuraChoiceOption(
    value: AgentVisibility.subAgentList,
    label: TextLocale(LocaleKeys.agents_visibility_sub_agent_list),
  ),
  AuraChoiceOption(
    value: AgentVisibility.both,
    label: TextLocale(LocaleKeys.agents_visibility_both),
  ),
];
const _agentToolPermissionItems =
    <AuraButtonGroupItem<AgentToolPermissionMode>>[
      AuraButtonGroupItem(
        value: AgentToolPermissionMode.workspaceDefault,
        child: TextLocale(LocaleKeys.agents_tool_permission_workspace_default),
      ),
      AuraButtonGroupItem(
        value: AgentToolPermissionMode.alwaysAsk,
        child: TextLocale(LocaleKeys.tools_screen_permission_always_ask),
      ),
      AuraButtonGroupItem(
        value: AgentToolPermissionMode.alwaysAllow,
        child: TextLocale(LocaleKeys.tools_screen_permission_always_allow),
      ),
      AuraButtonGroupItem(
        value: AgentToolPermissionMode.alwaysDeny,
        child: TextLocale(LocaleKeys.agents_tool_permission_deny),
      ),
    ];

typedef _AgentSkillTileData = ({
  WorkspaceSkill skill,
  bool selected,
  VoidCallback onTap,
  bool disabled,
});

typedef _ToolGroupRequest = ({
  String key,
  ({String source, String skillSlug, String toolSlug}) parsed,
  List<WorkspaceToolEntity> visibleTools,
  _ToolGroupBuckets buckets,
});

typedef _NewToolGroupRequest = ({
  String key,
  ({String source, String skillSlug, String toolSlug}) parsed,
  WorkspaceSkill? skill,
  List<WorkspaceToolEntity> visibleTools,
});

class const AgentDetailScreen({
  required final String workspaceId,
  final String? agentId,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<AgentDetailScreen> createState() => _AgentDetailScreenState();
}

abstract class _AgentDetailScreenStateBase
    extends ConsumerState<AgentDetailScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _selectedSkills = <AgentSkillRef>{};
  final _toolPermissionModes = <String, AgentToolPermissionMode>{};
  bool _isEnabled = true;
  AgentVisibility _visibility = .both;
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
}

class _AgentDetailScreenState extends _AgentDetailScreenStateBase
    with
        _AgentDetailDialogs,
        _AgentDetailInitialization,
        _AgentDetailToolOverrides,
        _AgentDetailEditing,
        _AgentDetailSaving,
        _AgentDetailSummaryActions {
  static const _compactLayoutWidth = 640.0;

  @override
  Widget build(BuildContext context) => _AgentDetailScreenView(state: this);
}

mixin _AgentDetailDialogs on _AgentDetailScreenStateBase {
  Future<void> _showSkillsManager({
    required List<WorkspaceSkill> enabledSkills,
    required List<WorkspaceSkill> disabledSkills,
    required List<AgentSkillRef> unavailableRefs,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _AgentSkillsDialog(
        owner: this as _AgentDetailScreenState,
        enabledSkills: enabledSkills,
        disabledSkills: disabledSkills,
        unavailableRefs: unavailableRefs,
      ),
    );
  }

  void _setEnabled(bool value) => setState(() => _isEnabled = value);

  void _setVisibility(AgentVisibility value) =>
      setState(() => _visibility = value);

  void _setToolPermissionMode(String toolId, AgentToolPermissionMode value) {
    setState(() {
      _toolPermissionModes[toolId] = value;
    });
  }

  void _manageSkills({
    required List<WorkspaceSkill> enabledSkills,
    required List<WorkspaceSkill> disabledSkills,
    required List<AgentSkillRef> unavailableRefs,
  }) {
    unawaited(
      _showSkillsManager(
        enabledSkills: enabledSkills,
        disabledSkills: disabledSkills,
        unavailableRefs: unavailableRefs,
      ),
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
        onChanged: _setToolPermissionMode,
      ),
    );
  }

  void _manageSkillsFromSummary(_AgentFormSummary summary) {
    _manageSkills(
      enabledSkills: summary.enabledSkills,
      disabledSkills: summary.disabledSkills,
      unavailableRefs: summary.unavailableRefs,
    );
  }
}

mixin _AgentDetailInitialization on _AgentDetailScreenStateBase {
  void initialize(AgentEntity agent) {
    _loaded = true;
    _initializeAgentFields(agent);
  }

  void _initializeAgentFields(AgentEntity agent) {
    _nameController.text = agent.name;
    _descriptionController.text = agent.description;
    _contentController.text = agent.content;
    _isEnabled = agent.isEnabled;
    _visibility = agent.visibility;
    _initializeSelectedSkills(agent.skills);
  }

  void _initializeSelectedSkills(List<AgentSkillRef> skills) {
    _selectedSkills
      ..clear()
      ..addAll(skills);
  }

  void _removeUnavailableSkill(AgentSkillRef skill) {
    setState(() {
      final _ = _selectedSkills.remove(skill);
    });
  }
}

mixin _AgentDetailToolOverrides on _AgentDetailScreenStateBase {
  void _initializeToolOverrides(List<AgentToolOverrideEntity> overrides) {
    _toolOverridesLoaded = true;
    _toolPermissionModes
      ..clear()
      ..addEntries(
        overrides.map(
          (override) =>
              MapEntry(override.toolId, override.permissionMode.agentMode),
        ),
      );
  }

  void _markAgentLoaded() {
    if (!mounted) return;
    setState(() => _loaded = true);
  }

  void _markToolOverridesLoaded() {
    if (!mounted) return;
    setState(() => _toolOverridesLoaded = true);
  }

  void _toggleSkillValue(WorkspaceSkill skill) {
    if (_selectedSkills.contains(skill.ref)) {
      final _ = _selectedSkills.remove(skill.ref);
    } else {
      final _ = _selectedSkills.add(skill.ref);
    }
  }
}

mixin _AgentDetailEditing on _AgentDetailScreenStateBase {
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
    if (!await _confirmSkillEnable()) return;

    await _enableSkill(skill);
  }

  Future<bool> _confirmSkillEnable() async {
    final confirmed = await AuraDialogs.confirm(
      context: context,
      title: const TextLocale(LocaleKeys.agents_enable_skill_title),
      message: const TextLocale(LocaleKeys.agents_enable_skill_message),
      actions: const AuraConfirmDialogActions(
        confirmLabel: TextLocale(LocaleKeys.agents_enable_skill_action),
        cancelLabel: TextLocale(LocaleKeys.common_cancel),
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _enableSkill(WorkspaceSkill skill) async {
    await _enableSkillInWorkspace(skill);
    if (!mounted) return;
    setState(() {
      final _ = _selectedSkills.add(skill.ref);
    });
  }

  Future<void> _enableSkillInWorkspace(WorkspaceSkill skill) async {
    final workspaceId = widget.workspaceId;
    final usecase = ref.read(disableSkillUsecaseProvider(workspaceId));
    await usecase.call(skill._enableRequest(workspaceId));
    final _ = ref.invalidate(workspaceSkillsProvider(workspaceId));
  }
}

mixin _AgentDetailSaving on _AgentDetailScreenStateBase {
  void _requestSave() {
    if (_saving) return;
    unawaited((this as _AgentDetailScreenState)._save());
  }

  Future<void> _saveToolOverrides(String agentId) {
    return ref
        .read(saveAgentToolOverridesUsecaseProvider(widget.workspaceId))
        .call(agentId: agentId, permissionsByToolId: _toolPermissionModes);
  }
}

mixin _AgentDetailSummaryActions on _AgentDetailScreenStateBase {
  Future<void> _save() async {
    final draft = _agentDraft();
    if (!_validateDraft(draft)) return;

    setState(() => _saving = true);
    try {
      await _completeSave(draft);
    } finally {
      _finishSaving();
    }
  }

  Future<void> _completeSave(AgentToCreate draft) async {
    final agent = await _saveAgent(draft);
    await (this as _AgentDetailScreenState)._saveToolOverrides(agent.id);
    final _ = ref.invalidate(agentsProvider(widget.workspaceId));
    if (mounted) context.pop(true);
  }

  void _finishSaving() {
    if (mounted) setState(() => _saving = false);
  }

  AgentToCreate _agentDraft() {
    return AgentToCreate(
      name: _nameController.text,
      description: _descriptionController.text,
      content: _contentController.text,
      isEnabled: _isEnabled,
      visibility: _visibility,
      skills: _selectedSkills.toList(),
    );
  }

  bool _validateDraft(AgentToCreate draft) {
    if (draft.isValid) return true;

    final _ = AuraSnackBars.show(
      context: context,
      content: const TextLocale(LocaleKeys.cloud_errors_validation),
      variant: .error,
    );

    return false;
  }

  Future<AgentEntity> _saveAgent(AgentToCreate draft) {
    final usecase = ref.read(saveAgentUsecaseProvider(widget.workspaceId));
    final agentId = widget.agentId;
    if (agentId == null) return usecase.create(widget.workspaceId, draft);

    return usecase.update(agentId, _agentUpdate(draft));
  }

  AgentToUpdate _agentUpdate(AgentToCreate draft) {
    return AgentToUpdate(
      name: draft.name,
      description: draft.description,
      content: draft.content,
      isEnabled: draft.isEnabled,
      visibility: draft.visibility,
      skills: draft.skills,
    );
  }
}

class const _AgentDetailScreenView({
  required final _AgentDetailScreenState state,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentId = state.widget.agentId;
    if (agentId == null) return _AgentDetailLoadedView(state: state);
    if (!state._loaded) {
      return _AgentInitialLoader(state: state, agentId: agentId);
    }
    if (!state._toolOverridesLoaded) {
      return _AgentToolOverridesGate(state: state, agentId: agentId);
    }

    return _AgentDetailLoadedView(state: state);
  }
}

class const _AgentInitialLoader({
  required final _AgentDetailScreenState state,
  required final String agentId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AgentLoader(
      future: ref
          .read(agentRepositoryProvider(state.widget.workspaceId))
          .getAgentById(agentId),
      onLoaded: state.initialize,
      onInitialized: state._markAgentLoaded,
    );
  }
}

class const _AgentToolOverridesGate({
  required final _AgentDetailScreenState state,
  required final String agentId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AgentToolOverridesLoader(
      future: ref
          .read(listAgentToolOverridesUsecaseProvider(state.widget.workspaceId))
          .call(agentId),
      onLoaded: state._initializeToolOverrides,
      onInitialized: state._markToolOverridesLoaded,
    );
  }
}

class const _AgentDetailLoadedView({
  required final _AgentDetailScreenState state,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = ref.watch(workspaceSkillsProvider(state.widget.workspaceId));
    final tools = ref.watch(workspaceToolsProvider(state.widget.workspaceId));

    return _AgentDetailScreenLayout(state: state, skills: skills, tools: tools);
  }
}

class const _AgentDetailScreenLayout({
  required final _AgentDetailScreenState state,
  required final AsyncValue<List<WorkspaceSkill>> skills,
  required final AsyncValue<List<WorkspaceToolEntity>> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: _AgentDetailBody(state: state, skills: skills, tools: tools),
      appBar: _AgentDetailAppBar(state: state),
    );
  }
}

class const _AgentDetailAppBar({required final _AgentDetailScreenState state})
    extends StatelessWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AuraAppBar(
      title: TextLocale(
        state.widget.agentId == null
            ? LocaleKeys.agents_create
            : LocaleKeys.agents_edit_title,
      ),
      leading: AuraIconButton(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class const _AgentDetailBody({
  required final _AgentDetailScreenState state,
  required final AsyncValue<List<WorkspaceSkill>> skills,
  required final AsyncValue<List<WorkspaceToolEntity>> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _AgentDetailBodyContent(state: state, skills: skills, tools: tools);
}

class const _AgentDetailBodyContent({
  required final _AgentDetailScreenState state,
  required final AsyncValue<List<WorkspaceSkill>> skills,
  required final AsyncValue<List<WorkspaceToolEntity>> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      switch ((skills: skills, tools: tools)) {
        (
          skills: AsyncData(value: final skillValue),
          tools: AsyncData(value: final toolValue),
        ) =>
          _AgentReadyBody(state: state, skills: skillValue, tools: toolValue),
        (skills: AsyncError(), tools: _) ||
        (skills: _, tools: AsyncError()) => const _AgentDetailError(),
        _ => const _AgentDetailLoading(),
      };
}

class const _AgentDetailError() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: AuraText(child: TextLocale(LocaleKeys.agents_skills_load_error)),
  );
}

class const _AgentDetailLoading() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(child: AuraSpinner());
}

class const _AgentReadyBody({
  required final _AgentDetailScreenState state,
  required final List<WorkspaceSkill> skills,
  required final List<WorkspaceToolEntity> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _AgentForm(state: state, skills: skills, tools: tools),
        ),
        _SaveBar(
          isCreate: state.widget.agentId == null,
          isSaving: state._saving,
          onSave: state._requestSave,
        ),
      ],
    );
  }
}

class const _AgentLoader({
  required final Future<AgentEntity?> future,
  required final ValueChanged<AgentEntity> onLoaded,
  required final VoidCallback onInitialized,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FutureBuilder<AgentEntity?>(
    future: future,
    builder: (context, snapshot) =>
        _AgentLoaderSnapshot(snapshot, onLoaded, onInitialized),
  );
}

class const _AgentLoaderSnapshot(
  final AsyncSnapshot<AgentEntity?> snapshot,
  final ValueChanged<AgentEntity> onLoaded,
  final VoidCallback onInitialized,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final agent = snapshot.data;
    if (agent == null) return const Center(child: AuraSpinner());

    onLoaded(agent);
    WidgetsBinding.instance.addPostFrameCallback((_) => onInitialized());

    return const Center(child: AuraSpinner());
  }
}

class const _AgentToolOverridesLoader({
  required final Future<List<AgentToolOverrideEntity>> future,
  required final ValueChanged<List<AgentToolOverrideEntity>> onLoaded,
  required final VoidCallback onInitialized,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<AgentToolOverrideEntity>>(
        future: future,
        builder: (context, snapshot) =>
            _AgentToolOverridesSnapshot(snapshot, onLoaded, onInitialized),
      );
}

class const _AgentToolOverridesSnapshot(
  final AsyncSnapshot<List<AgentToolOverrideEntity>> snapshot,
  final ValueChanged<List<AgentToolOverrideEntity>> onLoaded,
  final VoidCallback onInitialized,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!snapshot.hasData) {
      return const AuraScreen(child: Center(child: AuraSpinner()));
    }

    onLoaded(snapshot.requireData);
    WidgetsBinding.instance.addPostFrameCallback((_) => onInitialized());

    return const AuraScreen(child: Center(child: AuraSpinner()));
  }
}

class const _AgentForm({
  required final _AgentDetailScreenState state,
  required final List<WorkspaceSkill> skills,
  required final List<WorkspaceToolEntity> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AgentFormLayout(
    state: state,
    skills: skills,
    tools: tools,
    summary: _agentFormSummary(state, skills, tools),
  );
}

class const _AgentFormSummary(
  final List<WorkspaceSkill> enabledSkills,
  final List<WorkspaceSkill> disabledSkills,
  final List<AgentSkillRef> unavailableRefs,
  final int selectedDisabledCount,
  final int overrideCount,
  final int missingToolOverrideCount,
);

class const _AgentFormLayout({
  required final _AgentDetailScreenState state,
  required final List<WorkspaceSkill> skills,
  required final List<WorkspaceToolEntity> tools,
  required final _AgentFormSummary summary,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _PromptCard(state: state),
      const SizedBox(height: 16),
      _AgentFormSummaryCards(
        state: state,
        skills: skills,
        tools: tools,
        summary: summary,
      ),
    ],
  );
}

_AgentFormSummary _agentFormSummary(
  _AgentDetailScreenState state,
  List<WorkspaceSkill> skills,
  List<WorkspaceToolEntity> tools,
) {
  return _AgentFormSummary(
    _enabledAgentSkills(skills),
    _disabledAgentSkills(skills),
    _unavailableAgentSkills(skills, state._selectedSkills),
    _selectedDisabledAgentSkills(skills, state._selectedSkills),
    _agentToolOverrideCount(tools, state._toolPermissionModes),
    _missingAgentToolOverrideCount(tools, state._toolPermissionModes),
  );
}

class const _AgentFormSummaryCards({
  required final _AgentDetailScreenState state,
  required final List<WorkspaceSkill> skills,
  required final List<WorkspaceToolEntity> tools,
  required final _AgentFormSummary summary,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      _AgentSkillsSummarySection(state: state, summary: summary),
      const SizedBox(height: 16),
      _AgentToolsSummarySection(state: state, skills: skills, tools: tools),
    ],
  );
}

class const _AgentSkillsSummarySection({
  required final _AgentDetailScreenState state,
  required final _AgentFormSummary summary,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillsSummaryCard(
    selectedCount: state._selectedSkills.length,
    availableCount: summary.enabledSkills.length,
    disabledSelectedCount: summary.selectedDisabledCount,
    unavailableCount: summary.unavailableRefs.length,
    onManage: () => state._manageSkillsFromSummary(summary),
  );
}

class const _AgentToolsSummarySection({
  required final _AgentDetailScreenState state,
  required final List<WorkspaceSkill> skills,
  required final List<WorkspaceToolEntity> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ToolPermissionsSummaryCard(
    overrideCount: _agentToolOverrideCount(tools, state._toolPermissionModes),
    missingOverrideCount: _missingAgentToolOverrideCount(
      tools,
      state._toolPermissionModes,
    ),
    onManage: () => state._showToolPermissionsManager(skills, tools),
  );
}

List<WorkspaceSkill> _enabledAgentSkills(List<WorkspaceSkill> skills) {
  return skills.where((skill) => skill.isEnabled).toList();
}

List<WorkspaceSkill> _disabledAgentSkills(List<WorkspaceSkill> skills) {
  return skills.where((skill) => !skill.isEnabled).toList();
}

List<AgentSkillRef> _unavailableAgentSkills(
  List<WorkspaceSkill> skills,
  Set<AgentSkillRef> selectedSkills,
) {
  return selectedSkills.where((ref) {
    return !skills.any((skill) => skill.ref == ref);
  }).toList();
}

int _selectedDisabledAgentSkills(
  List<WorkspaceSkill> skills,
  Set<AgentSkillRef> selectedSkills,
) {
  return skills
      .where((skill) => !skill.isEnabled && selectedSkills.contains(skill.ref))
      .length;
}

int _agentToolOverrideCount(
  List<WorkspaceToolEntity> tools,
  Map<String, AgentToolPermissionMode> modes,
) {
  return modes.entries
      .where((entry) => _isKnownAgentToolOverride(entry, tools))
      .length;
}

int _missingAgentToolOverrideCount(
  List<WorkspaceToolEntity> tools,
  Map<String, AgentToolPermissionMode> modes,
) {
  return modes.entries
      .where((entry) => _isMissingAgentToolOverride(entry, tools))
      .length;
}

bool _isKnownAgentToolOverride(
  MapEntry<String, AgentToolPermissionMode> entry,
  List<WorkspaceToolEntity> tools,
) {
  return entry.value != AgentToolPermissionMode.workspaceDefault &&
      tools.any((tool) => tool.id == entry.key);
}

bool _isMissingAgentToolOverride(
  MapEntry<String, AgentToolPermissionMode> entry,
  List<WorkspaceToolEntity> tools,
) {
  return entry.value != AgentToolPermissionMode.workspaceDefault &&
      !tools.any((tool) => tool.id == entry.key);
}

class const _PromptCard({required final _AgentDetailScreenState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: _PromptCardContent(
        state: state,
        onVisibilityChanged: _handleVisibilityChanged,
      ),
    );
  }

  void _handleVisibilityChanged(List<AgentVisibility> values) {
    final selected = values.firstOrNull;
    if (selected == null) return;
    state._setVisibility(selected);
  }
}

class const _PromptCardContent({
  required final _AgentDetailScreenState state,
  required final ValueChanged<List<AgentVisibility>> onVisibilityChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const _PromptCardHeader(),
      _AgentNameField(controller: state._nameController),
      _PromptCardSettings(
        state: state,
        onVisibilityChanged: onVisibilityChanged,
      ),
      _PromptCardMarkdownFields(state: state),
    ],
    spacing: .md,
    crossAxisAlignment: .start,
  );
}

class const _PromptCardSettings({
  required final _AgentDetailScreenState state,
  required final ValueChanged<List<AgentVisibility>> onVisibilityChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _AgentEnabledRow(value: state._isEnabled, onChanged: state._setEnabled),
      _AgentVisibilityField(
        value: state._visibility,
        onChanged: onVisibilityChanged,
      ),
    ],
    spacing: .md,
    crossAxisAlignment: .start,
  );
}

class _PromptCardMarkdownFields({required final _AgentDetailScreenState state})
    extends StatelessWidget {
  final Widget _child = AuraColumn(
    children: [
      _AgentDescriptionField(
        controller: state._descriptionController,
        onEdit: () => unawaited(state._editDescription()),
      ),
      _AgentPromptField(
        controller: state._contentController,
        onEdit: () => unawaited(state._editPrompt()),
      ),
    ],
    spacing: .md,
    crossAxisAlignment: .start,
  );

  @override
  Widget build(BuildContext _) => _child;
}

class const _PromptCardHeader() extends StatelessWidget {
  final Widget _child = const AuraColumn(
    children: [
      AuraText(
        child: TextLocale(LocaleKeys.agents_profile_prompt_title),
        style: .heading5,
      ),
      AuraText(
        child: TextLocale(LocaleKeys.agents_profile_prompt_description),
        style: .bodySmall,
      ),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );

  @override
  Widget build(BuildContext _) => _child;
}

class const _AgentNameField({required final TextEditingController controller})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: controller,
      label: Text(LocaleKeys.agents_name_label.tr(context: context)),
    );
  }
}

class const _AgentEnabledRow({
  required final bool value,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _AgentEnabledDescription()),
        AuraSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class const _AgentEnabledDescription() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AuraColumn(
      children: [
        AuraText(child: TextLocale(LocaleKeys.agents_enabled_label)),
        AuraText(
          child: TextLocale(LocaleKeys.agents_enabled_description),
          style: .bodySmall,
        ),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
    );
  }
}

class const _AgentVisibilityField({
  required final AgentVisibility value,
  required final ValueChanged<List<AgentVisibility>> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraChoicePicker<AgentVisibility>(
      options: _agentVisibilityOptions,
      value: [value],
      onChanged: onChanged,
      label: const AuraText(
        child: TextLocale(LocaleKeys.agents_visibility_label),
      ),
    );
  }
}

class const _AgentDescriptionField({
  required final TextEditingController controller,
  required final VoidCallback onEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MarkdownPreviewField(
      controller: controller,
      titleKey: LocaleKeys.agents_description_label,
      editKey: LocaleKeys.agents_edit_description,
      emptyKey: LocaleKeys.agents_description_empty,
      onEdit: onEdit,
    );
  }
}

class const _AgentPromptField({
  required final TextEditingController controller,
  required final VoidCallback onEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MarkdownPreviewField(
      controller: controller,
      titleKey: LocaleKeys.agents_prompt_label,
      editKey: LocaleKeys.agents_edit_prompt,
      emptyKey: LocaleKeys.agents_prompt_empty,
      onEdit: onEdit,
    );
  }
}

class const _SkillsSummaryCard({
  required final int selectedCount,
  required final int availableCount,
  required final int disabledSelectedCount,
  required final int unavailableCount,
  required final VoidCallback onManage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: _SkillsSummaryContent(
      selectedCount: selectedCount,
      availableCount: availableCount,
      disabledSelectedCount: disabledSelectedCount,
      unavailableCount: unavailableCount,
      onManage: onManage,
    ),
  );
}

class _SkillsSummaryContent({
  required final int selectedCount,
  required final int availableCount,
  required final int disabledSelectedCount,
  required final int unavailableCount,
  required final VoidCallback onManage,
}) extends StatelessWidget {
  final Widget _child = AuraColumn(
    children: [
      _SkillsSummaryHeader(onManage: onManage),
      _SkillsSummaryDetails(
        selectedCount: selectedCount,
        availableCount: availableCount,
        disabledSelectedCount: disabledSelectedCount,
        unavailableCount: unavailableCount,
        onManage: onManage,
      ),
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );

  @override
  Widget build(BuildContext _) => _child;
}

class const _SkillsSummaryHeader({required final VoidCallback onManage})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _CardHeader(
    title: const TextLocale(LocaleKeys.agents_skills_title),
    actionLabel: const TextLocale(LocaleKeys.agents_manage_skills),
    onAction: onManage,
  );
}

class _SkillsSummaryDetails({
  required final int selectedCount,
  required final int availableCount,
  required final int disabledSelectedCount,
  required final int unavailableCount,
  required final VoidCallback onManage,
}) extends StatelessWidget {
  final Widget _child = AuraColumn(
    children: [
      _SkillsSummaryText(
        selectedCount: selectedCount,
        availableCount: availableCount,
      ),
      if (disabledSelectedCount > 0 || unavailableCount > 0)
        _SkillsWarning(
          disabledSelectedCount: disabledSelectedCount,
          unavailableCount: unavailableCount,
          onManage: onManage,
        ),
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );

  @override
  Widget build(BuildContext _) => _child;
}

class const _SkillsSummaryText({
  required final int selectedCount,
  required final int availableCount,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(
      child: Text(
        LocaleKeys.agents_skills_summary.tr(
          namedArgs: {
            'selected': selectedCount.toString(),
            'available': availableCount.toString(),
          },
          context: context,
        ),
      ),
      style: .bodySmall,
    );
  }
}

class const _SkillsWarning({
  required final int disabledSelectedCount,
  required final int unavailableCount,
  required final VoidCallback onManage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _WarningTile(
      label: LocaleKeys.agents_skills_warning_summary.tr(
        namedArgs: {
          'disabled': disabledSelectedCount.toString(),
          'unavailable': unavailableCount.toString(),
        },
        context: context,
      ),
      onTap: onManage,
    );
  }
}

class const _ToolPermissionsSummaryCard({
  required final int overrideCount,
  required final int missingOverrideCount,
  required final VoidCallback onManage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: _ToolPermissionsSummaryContent(
      overrideCount: overrideCount,
      missingOverrideCount: missingOverrideCount,
      onManage: onManage,
    ),
  );
}

class _ToolPermissionsSummaryContent({
  required final int overrideCount,
  required final int missingOverrideCount,
  required final VoidCallback onManage,
}) extends StatelessWidget {
  final Widget _child = AuraColumn(
    children: [
      _CardHeader(
        title: const TextLocale(LocaleKeys.agents_tool_permissions_title),
        actionLabel: const TextLocale(
          LocaleKeys.agents_manage_tool_permissions,
        ),
        onAction: onManage,
      ),
      _ToolPermissionsSummaryText(overrideCount: overrideCount),
      if (missingOverrideCount > 0)
        _ToolPermissionsWarning(
          missingOverrideCount: missingOverrideCount,
          onManage: onManage,
        ),
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );

  @override
  Widget build(BuildContext _) => _child;
}

class const _ToolPermissionsSummaryText({required final int overrideCount})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = overrideCount == 0
        ? LocaleKeys.agents_tool_permissions_default_summary.tr(
            context: context,
          )
        : LocaleKeys.agents_tool_permissions_override_summary.tr(
            namedArgs: {'count': overrideCount.toString()},
            context: context,
          );

    return AuraText(child: Text(text), style: .bodySmall);
  }
}

class const _ToolPermissionsWarning({
  required final int missingOverrideCount,
  required final VoidCallback onManage,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _WarningTile(
      label: LocaleKeys.agents_tool_permissions_warning_summary.tr(
        namedArgs: {'count': missingOverrideCount.toString()},
        context: context,
      ),
      onTap: onManage,
    );
  }
}

class const _CardHeader({
  required final Widget title,
  required final Widget actionLabel,
  required final VoidCallback onAction,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        Expanded(
          child: AuraText(child: title, style: .heading5),
        ),
        AuraButton(onPressed: onAction, child: actionLabel, variant: .text),
      ],
      spacing: .sm,
    );
  }
}

class const _SaveBar({
  required final bool isCreate,
  required final bool isSaving,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: _SaveBarContainer(isCreate: isCreate, onSave: onSave),
  );
}

class const _SaveBarContainer({
  required final bool isCreate,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.auraColors.surface,
        border: Border(top: .new(color: context.auraColors.outlineVariant)),
      ),
      child: _SaveBarButtonLayout(isCreate: isCreate, onSave: onSave),
    );
  }
}

class const _SaveBarButtonLayout({
  required final bool isCreate,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _SaveBarButtonFromConstraints(
        constraints: constraints,
        isCreate: isCreate,
        onSave: onSave,
      ),
    );
  }
}

class const _SaveBarButtonFromConstraints({
  required final BoxConstraints constraints,
  required final bool isCreate,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SaveBarButton(
    width: constraints.maxWidth < _AgentDetailScreenState._compactLayoutWidth
        ? double.infinity
        : 220,
    isCompact:
        constraints.maxWidth < _AgentDetailScreenState._compactLayoutWidth,
    isCreate: isCreate,
    onSave: onSave,
  );
}

class _SaveBarButton({
  required final double width,
  required final bool isCompact,
  required final bool isCreate,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  final Widget _child = isCompact
      ? SizedBox(
          width: width,
          child: AuraButton(
            onPressed: onSave,
            child: TextLocale(
              isCreate ? LocaleKeys.agents_create : LocaleKeys.common_save,
            ),
          ),
        )
      : Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: width,
            child: AuraButton(
              onPressed: onSave,
              child: TextLocale(
                isCreate ? LocaleKeys.agents_create : LocaleKeys.common_save,
              ),
            ),
          ),
        );

  @override
  Widget build(BuildContext _) => _child;
}

class const _WarningTile({
  required final String label,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraTile(
      child: Text(label),
      onTap: onTap,
      variant: .surface,
      leading: const AuraIcon(Icons.warning_amber_outlined),
      trailing: const AuraIcon(Icons.arrow_forward_ios),
    );
  }
}

class const _AgentSkillsDialog({
  required final _AgentDetailScreenState owner,
  required final List<WorkspaceSkill> enabledSkills,
  required final List<WorkspaceSkill> disabledSkills,
  required final List<AgentSkillRef> unavailableRefs,
}) extends StatefulWidget {
  Set<AgentSkillRef> get selectedSkills => owner._selectedSkills;

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
  Widget build(BuildContext context) =>
      _AgentSkillsDialogView(state: this, data: _dialogData);
}

extension on _AgentSkillsDialogState {
  _SkillDialogData get _dialogData => _SkillDialogData(
    _selectedSkillsFor(),
    _availableSkillsFor(_query.trim().toLowerCase()),
    _disabledSkillsFor(_query.trim().toLowerCase()),
  );

  List<WorkspaceSkill> _selectedSkillsFor() => widget.enabledSkills
      .where((skill) => widget.selectedSkills.contains(skill.ref))
      .toList();

  List<WorkspaceSkill> _availableSkillsFor(String query) => widget.enabledSkills
      .where(
        (skill) =>
            !widget.selectedSkills.contains(skill.ref) && skill.matches(query),
      )
      .toList();

  List<WorkspaceSkill> _disabledSkillsFor(String query) =>
      widget.disabledSkills.where((skill) => skill.matches(query)).toList();

  void _setQuery(String value) => setState(() => _query = value);

  void _enableFromDialog(WorkspaceSkill skill) => unawaited(_enable(skill));

  void _removeUnavailable(AgentSkillRef ref) {
    setState(() => widget.owner._removeUnavailableSkill(ref));
  }

  void _toggle(WorkspaceSkill skill) {
    setState(() => widget.owner._toggleSkillValue(skill));
  }

  Future<void> _enable(WorkspaceSkill skill) async {
    await widget.owner._confirmEnableSkill(skill);
    if (mounted) setState(() => _query = _searchController.text);
  }
}

class const _SkillDialogData(
  final List<WorkspaceSkill> selectedSkills,
  final List<WorkspaceSkill> availableSkills,
  final List<WorkspaceSkill> disabledSkills,
);

class const _AgentSkillsDialogView({
  required final _AgentSkillsDialogState state,
  required final _SkillDialogData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _AgentManageDialog(
      title: const TextLocale(LocaleKeys.agents_manage_skills_title),
      child: _AgentSkillsDialogList(state: state, data: data),
    );
  }
}

class const _AgentSkillsDialogList({
  required final _AgentSkillsDialogState state,
  required final _SkillDialogData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SkillDialogSearch(
          controller: state._searchController,
          onChanged: state._setQuery,
        ),
        const SizedBox(height: 16),
        _SkillDialogSections(state: state, data: data),
      ],
    );
  }
}

class const _SkillDialogSearch({
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: controller,
      label: Text(LocaleKeys.agents_manage_skills_search.tr(context: context)),
      onChanged: onChanged,
    );
  }
}

class const _SkillDialogSections({
  required final _AgentSkillsDialogState state,
  required final _SkillDialogData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _SkillDialogEnabledSections(state: state, data: data),
      _SkillDialogDisabledSections(state: state, data: data),
    ],
  );
}

class const _SkillDialogEnabledSections({
  required final _AgentSkillsDialogState state,
  required final _SkillDialogData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _SelectedSkillDialogSection(state: state, skills: data.selectedSkills),
      _AvailableSkillDialogSection(state: state, skills: data.availableSkills),
    ],
  );
}

class const _SkillDialogDisabledSections({
  required final _AgentSkillsDialogState state,
  required final _SkillDialogData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _DisabledSkillDialogSection(state: state, skills: data.disabledSkills),
      if (state.widget.unavailableRefs.isNotEmpty)
        _UnavailableSkillSection(
          refs: state.widget.unavailableRefs,
          onRemove: state._removeUnavailable,
        ),
    ],
  );
}

class const _SelectedSkillDialogSection({
  required final _AgentSkillsDialogState state,
  required final List<WorkspaceSkill> skills,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillDialogSection(
    title: const TextLocale(LocaleKeys.agents_manage_selected_section),
    empty: const TextLocale(LocaleKeys.agents_manage_selected_empty),
    skills: skills,
    selectedSkills: state.widget.selectedSkills,
    onTap: state._toggle,
  );
}

class const _AvailableSkillDialogSection({
  required final _AgentSkillsDialogState state,
  required final List<WorkspaceSkill> skills,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillDialogSection(
    title: const TextLocale(LocaleKeys.agents_manage_available_section),
    empty: const TextLocale(LocaleKeys.agents_manage_available_empty),
    skills: skills,
    selectedSkills: state.widget.selectedSkills,
    onTap: state._toggle,
  );
}

class const _DisabledSkillDialogSection({
  required final _AgentSkillsDialogState state,
  required final List<WorkspaceSkill> skills,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillDialogSection(
    title: const TextLocale(LocaleKeys.agents_disabled_skills_title),
    empty: const TextLocale(LocaleKeys.agents_disabled_skills_empty),
    skills: skills,
    selectedSkills: state.widget.selectedSkills,
    onTap: state._enableFromDialog,
    disabled: true,
  );
}

class const _SkillDialogSection({
  required final Widget title,
  required final Widget empty,
  required final List<WorkspaceSkill> skills,
  required final Set<AgentSkillRef> selectedSkills,
  required final ValueChanged<WorkspaceSkill> onTap,
  final bool disabled = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillSection(
    title: title,
    empty: empty,
    skills: skills,
    selectedSkills: selectedSkills,
    onTap: onTap,
    disabled: disabled,
  );
}

class const _AgentToolPermissionsDialog({
  required final List<WorkspaceSkill> skills,
  required final Set<AgentSkillRef> selectedSkills,
  required final List<WorkspaceToolEntity> tools,
  required final Map<String, AgentToolPermissionMode> values,
  required final void Function(String toolId, AgentToolPermissionMode value)
  onChanged,
}) extends StatefulWidget {
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
  Widget build(BuildContext context) =>
      _AgentToolPermissionsDialogView(state: this, data: _dialogData);
}

extension on _AgentToolPermissionsDialogState {
  _ToolPermissionDialogData get _dialogData {
    final query = _query.trim().toLowerCase();
    final visibleTools = _visibleTools(query);

    return _ToolPermissionDialogData(
      query,
      visibleTools,
      _overrideTools(visibleTools),
      _groupDefaultTools(_defaultTools(visibleTools), visibleTools),
    );
  }

  List<WorkspaceToolEntity> _visibleTools(String query) =>
      widget.tools.where((tool) => tool.matches(query)).toList();

  List<WorkspaceToolEntity> _overrideTools(List<WorkspaceToolEntity> tools) =>
      tools
          .where(
            (tool) =>
                _value(tool.id) != AgentToolPermissionMode.workspaceDefault,
          )
          .toList();

  List<WorkspaceToolEntity> _defaultTools(List<WorkspaceToolEntity> tools) =>
      tools
          .where(
            (tool) =>
                _value(tool.id) == AgentToolPermissionMode.workspaceDefault,
          )
          .toList();

  void _setQuery(String value) => setState(() => _query = value);

  _GroupedTools _groupDefaultTools(
    List<WorkspaceToolEntity> tools,
    List<WorkspaceToolEntity> visibleTools,
  ) {
    final buckets = _ToolGroupBuckets();
    for (final tool in tools) {
      _addDefaultTool(tool, visibleTools, buckets);
    }

    return buckets.toGroupedTools();
  }

  void _addDefaultTool(
    WorkspaceToolEntity tool,
    List<WorkspaceToolEntity> visibleTools,
    _ToolGroupBuckets buckets,
  ) {
    if (_isSkillControlTool(tool.toolId)) {
      buckets.skillControls.add(tool);
      return;
    }

    final parsed = ToolNameFormatter.parseSkillToolName(tool.toolId);
    if (parsed == null) {
      buckets.otherWorkspaceTools.add(tool);
      return;
    }

    _toolGroup(parsed, visibleTools, buckets).tools.add(tool);
  }

  _ToolGroup _toolGroup(
    ({String source, String skillSlug, String toolSlug}) parsed,
    List<WorkspaceToolEntity> visibleTools,
    _ToolGroupBuckets buckets,
  ) {
    final key = '${parsed.source}:${parsed.skillSlug}';
    return buckets.groupByKey.putIfAbsent(
      key,
      () => _createToolGroup((
        key: key,
        parsed: parsed,
        visibleTools: visibleTools,
        buckets: buckets,
      )),
    );
  }

  _ToolGroup _createToolGroup(_ToolGroupRequest request) {
    final skill = _findSkill(request.parsed.source, request.parsed.skillSlug);
    final group = _newToolGroup((
      key: request.key,
      parsed: request.parsed,
      skill: skill,
      visibleTools: request.visibleTools,
    ));
    _addToolGroup(group, skill, request.buckets);
    return group;
  }

  _ToolGroup _newToolGroup(_NewToolGroupRequest request) {
    final parsed = request.parsed;

    return _ToolGroup(
      key: request.key,
      title: _skillGroupTitle(request.skill, parsed.skillSlug),
      tools: [],
      overrideCount: _skillGroupOverrideCount(
        source: parsed.source,
        skillSlug: parsed.skillSlug,
        tools: request.visibleTools,
      ),
    );
  }

  void _addToolGroup(
    _ToolGroup group,
    WorkspaceSkill? skill,
    _ToolGroupBuckets buckets,
  ) {
    final selected = skill != null && widget.selectedSkills.contains(skill.ref);
    (selected ? buckets.selectedSkillGroups : buckets.otherSkillGroups).add(
      group,
    );
  }

  WorkspaceSkill? _findSkill(String source, String slug) {
    for (final skill in widget.skills) {
      final expectedSource = switch (skill.source) {
        .user => 'user',
        .app => 'app',
      };
      if (expectedSource == source && skill.slug == slug) return skill;
    }
    return null;
  }

  String _skillGroupTitle(WorkspaceSkill? skill, String fallbackSlug) =>
      skill?.title ?? fallbackSlug.toHumanReadable();

  bool _isSkillControlTool(String toolId) =>
      toolId == 'load_skill' ||
      toolId == 'unload_skill' ||
      toolId == 'list_skill_credentials';

  AgentToolPermissionMode _value(String toolId) =>
      widget.values[toolId] ?? AgentToolPermissionMode.workspaceDefault;

  int _skillGroupOverrideCount({
    required String source,
    required String skillSlug,
    required List<WorkspaceToolEntity> tools,
  }) => tools
      .where((tool) => _isToolOverrideForGroup(tool, source, skillSlug))
      .length;

  bool _isToolOverrideForGroup(
    WorkspaceToolEntity tool,
    String source,
    String skillSlug,
  ) {
    final parsed = ToolNameFormatter.parseSkillToolName(tool.toolId);
    return parsed?.source == source &&
        parsed?.skillSlug == skillSlug &&
        _value(tool.id) != AgentToolPermissionMode.workspaceDefault;
  }

  bool _isGroupExpanded(_ToolGroup group, String query) {
    if (query.isNotEmpty) return true;
    if (_collapsedToolGroups.contains(group.key)) return false;
    if (_expandedToolGroups.contains(group.key)) return true;
    return group.hasOverrides();
  }

  void _toggleGroup(_ToolGroup group, String query) {
    if (query.isNotEmpty) return;
    final isExpanded = _isGroupExpanded(group, query);
    setState(() => _setGroupExpansion(group.key, isExpanded));
  }

  void _setGroupExpansion(String key, bool isExpanded) {
    if (isExpanded) {
      final _ = _expandedToolGroups.remove(key);
      final _ = _collapsedToolGroups.add(key);
      return;
    }
    final _ = _collapsedToolGroups.remove(key);
    final _ = _expandedToolGroups.add(key);
  }

  void _change(String toolId, AgentToolPermissionMode value) {
    setState(() => widget.onChanged(toolId, value));
  }
}

class const _ToolPermissionDialogData(
  final String query,
  final List<WorkspaceToolEntity> visibleTools,
  final List<WorkspaceToolEntity> overrideTools,
  final _GroupedTools grouped,
);

class const _AgentToolPermissionsDialogView({
  required final _AgentToolPermissionsDialogState state,
  required final _ToolPermissionDialogData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _AgentManageDialog(
      title: const TextLocale(LocaleKeys.agents_manage_tool_permissions_title),
      child: _AgentToolPermissionsDialogList(state: state, data: data),
    );
  }
}

class const _AgentToolPermissionsDialogList({
  required final _AgentToolPermissionsDialogState state,
  required final _ToolPermissionDialogData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _ToolPermissionsSearch(
        controller: state._searchController,
        onChanged: state._setQuery,
      ),
      const SizedBox(height: 16),
      _ToolPermissionSections(state: state, data: data),
    ],
  );
}

class const _ToolPermissionSections({
  required final _AgentToolPermissionsDialogState state,
  required final _ToolPermissionDialogData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _OverrideToolsSection(state: state, tools: data.overrideTools),
      _ToolGroupSections(state: state, data: data),
      _ToolControlsSections(state: state, grouped: data.grouped),
    ],
  );
}

class const _ToolPermissionsSearch({
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: controller,
      label: Text(
        LocaleKeys.agents_manage_tool_permissions_search.tr(context: context),
      ),
      onChanged: onChanged,
    );
  }
}

class const _OverrideToolsSection({
  required final _AgentToolPermissionsDialogState state,
  required final List<WorkspaceToolEntity> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ToolSection(
      title: const TextLocale(LocaleKeys.agents_manage_overrides_section),
      empty: const TextLocale(LocaleKeys.agents_manage_overrides_empty),
      tools: tools,
      valueOf: state._value,
      onChanged: state._change,
    );
  }
}

class _ToolGroupSections({
  required final _AgentToolPermissionsDialogState state,
  required final _ToolPermissionDialogData data,
}) extends StatelessWidget {
  final Widget _child = Column(
    children: [
      _ToolGroupList(
        groups: data.grouped.selectedSkillGroups,
        empty: const TextLocale(
          LocaleKeys.agents_manage_selected_skill_tools_empty,
        ),
        query: data.query,
        state: state,
      ),
      _ToolGroupList(
        groups: data.grouped.otherSkillGroups,
        empty: const TextLocale(
          LocaleKeys.agents_manage_other_skill_tools_empty,
        ),
        query: data.query,
        state: state,
      ),
    ],
  );

  @override
  Widget build(BuildContext _) => _child;
}

class const _ToolGroupList({
  required final List<_ToolGroup> groups,
  required final Widget empty,
  required final String query,
  required final _AgentToolPermissionsDialogState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final group in groups)
          _ToolGroupItem(
            group: group,
            empty: empty,
            query: query,
            state: state,
          ),
      ],
    );
  }
}

class const _ToolGroupItem({
  required final _ToolGroup group,
  required final Widget empty,
  required final String query,
  required final _AgentToolPermissionsDialogState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CollapsibleToolSection(
      title: group.title,
      empty: empty,
      isExpanded: state._isGroupExpanded(group, query),
      onToggle: () => state._toggleGroup(group, query),
      tools: group.tools,
      valueOf: state._value,
      onChanged: state._change,
    );
  }
}

class const _ToolControlsSections({
  required final _AgentToolPermissionsDialogState state,
  required final _GroupedTools grouped,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _SkillControlsSection(state: state, tools: grouped.skillControls),
      _OtherWorkspaceToolsSection(
        state: state,
        tools: grouped.otherWorkspaceTools,
      ),
    ],
  );
}

class const _SkillControlsSection({
  required final _AgentToolPermissionsDialogState state,
  required final List<WorkspaceToolEntity> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ToolSection(
    title: const TextLocale(LocaleKeys.agents_manage_skill_controls_section),
    empty: const TextLocale(LocaleKeys.agents_manage_skill_controls_empty),
    tools: tools,
    valueOf: state._value,
    onChanged: state._change,
  );
}

class const _OtherWorkspaceToolsSection({
  required final _AgentToolPermissionsDialogState state,
  required final List<WorkspaceToolEntity> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ToolSection(
    title: const TextLocale(
      LocaleKeys.agents_manage_other_workspace_tools_section,
    ),
    empty: const TextLocale(
      LocaleKeys.agents_manage_other_workspace_tools_empty,
    ),
    tools: tools,
    valueOf: state._value,
    onChanged: state._change,
  );
}

class _ToolGroupBuckets {
  final selectedSkillGroups = <_ToolGroup>[];
  final otherSkillGroups = <_ToolGroup>[];
  final skillControls = <WorkspaceToolEntity>[];
  final otherWorkspaceTools = <WorkspaceToolEntity>[];
  final groupByKey = <String, _ToolGroup>{};

  _GroupedTools toGroupedTools() => _GroupedTools(
    selectedSkillGroups: selectedSkillGroups,
    otherSkillGroups: otherSkillGroups,
    skillControls: skillControls,
    otherWorkspaceTools: otherWorkspaceTools,
  );
}

class const _GroupedTools({
  required final List<_ToolGroup> selectedSkillGroups,
  required final List<_ToolGroup> otherSkillGroups,
  required final List<WorkspaceToolEntity> skillControls,
  required final List<WorkspaceToolEntity> otherWorkspaceTools,
}) {
  bool containsTool(String toolId) => [
    ...selectedSkillGroups,
    ...otherSkillGroups,
  ].any((group) => group.tools.any((tool) => tool.id == toolId));
}

class const _ToolGroup({
  required final String key,
  required final String title,
  required final List<WorkspaceToolEntity> tools,
  required final int overrideCount,
}) {
  bool hasOverrides() => overrideCount > 0;
}

class const _AgentManageDialog({
  required final Widget title,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        .circular(context.auraTheme.fromBorderRadius(.xl)),
      ),
    ),
    child: _AgentManageDialogContainer(title: title, child: child),
  );
}

class const _AgentManageDialogContainer({
  required final Widget title,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.9,
      constraints: .new(
        maxWidth: 620,
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      child: _AgentManageDialogBody(title: title, child: child),
    );
  }
}

class const _AgentManageDialogBody({
  required final Widget title,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        _AgentManageDialogHeader(title: title),
        Flexible(child: child),
      ],
    );
  }
}

class const _AgentManageDialogHeader({required final Widget title})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(context.auraTheme.fromSpacing(.md)),
    child: _AgentManageDialogHeaderRow(title: title),
  );
}

class const _AgentManageDialogHeaderRow({required final Widget title})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      Expanded(
        child: AuraText(child: title, style: .heading5),
      ),
      const _AgentManageDialogCloseButton(),
    ],
  );
}

class const _AgentManageDialogCloseButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.close,
    onPressed: () => Navigator.of(context).pop(),
    semanticLabel: LocaleKeys.common_close_dialog.tr(context: context),
  );
}

class _SkillSection({
  required final Widget title,
  required final Widget empty,
  required final List<WorkspaceSkill> skills,
  required final Set<AgentSkillRef> selectedSkills,
  required final ValueChanged<WorkspaceSkill> onTap,
  final bool disabled = false,
}) extends StatelessWidget {
  final Widget _child = _DialogSection(
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

  @override
  Widget build(BuildContext _) => _child;
}

class const _UnavailableSkillSection({
  required final List<AgentSkillRef> refs,
  required final ValueChanged<AgentSkillRef> onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _DialogSection(
    title: const TextLocale(LocaleKeys.agents_unavailable_skills_title),
    empty: const SizedBox.shrink(),
    children: [
      const AuraText(
        child: TextLocale(LocaleKeys.agents_disabled_skills_warning),
        style: .bodySmall,
      ),
      _UnavailableSkillList(refs: refs, onRemove: onRemove),
    ],
    isEmpty: false,
  );
}

class const _UnavailableSkillList({
  required final List<AgentSkillRef> refs,
  required final ValueChanged<AgentSkillRef> onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final ref in refs)
        _UnavailableSkillTile(ref: ref, onRemove: onRemove),
    ],
  );
}

class const _UnavailableSkillTile({
  required final AgentSkillRef ref,
  required final ValueChanged<AgentSkillRef> onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: AuraTile(
      child: _UnavailableSkillTileContent(ref: ref),
      onTap: () => onRemove(ref),
      variant: .surface,
      leading: const AuraIcon(Icons.warning_amber_outlined),
      trailing: const AuraIcon(Icons.close),
    ),
  );
}

class const _UnavailableSkillTileContent({required final AgentSkillRef ref})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const TextLocale(LocaleKeys.agents_disabled_skill_label),
      Text(ref.label()),
    ],
    crossAxisAlignment: .start,
  );
}

class _ToolSection({
  required final Widget title,
  required final Widget empty,
  required final List<WorkspaceToolEntity> tools,
  required final AgentToolPermissionMode Function(String toolId) valueOf,
  required final void Function(String toolId, AgentToolPermissionMode value)
  onChanged,
}) extends StatelessWidget {
  final Widget _child = _DialogSection(
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

  @override
  Widget build(BuildContext _) => _child;
}

class const _CollapsibleToolSection({
  required final String title,
  required final Widget empty,
  required final bool isExpanded,
  required final VoidCallback onToggle,
  required final List<WorkspaceToolEntity> tools,
  required final AgentToolPermissionMode Function(String toolId) valueOf,
  required final void Function(String toolId, AgentToolPermissionMode value)
  onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: _CollapsibleToolColumn(
      title: title,
      empty: empty,
      isExpanded: isExpanded,
      onToggle: onToggle,
      tools: tools,
      valueOf: valueOf,
      onChanged: onChanged,
    ),
  );
}

class _CollapsibleToolColumn({
  required final String title,
  required final Widget empty,
  required final bool isExpanded,
  required final VoidCallback onToggle,
  required final List<WorkspaceToolEntity> tools,
  required final AgentToolPermissionMode Function(String toolId) valueOf,
  required final void Function(String toolId, AgentToolPermissionMode value)
  onChanged,
}) extends StatelessWidget {
  final Widget _child = AuraColumn(
    children: [
      _CollapsibleToolHeader(
        title: title,
        isExpanded: isExpanded,
        onToggle: onToggle,
      ),
      if (isExpanded)
        _CollapsibleToolContent(
          empty: empty,
          tools: tools,
          valueOf: valueOf,
          onChanged: onChanged,
        ),
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );

  @override
  Widget build(BuildContext _) => _child;
}

class const _CollapsibleToolHeader({
  required final String title,
  required final bool isExpanded,
  required final VoidCallback onToggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: AuraColumn(children: [Text(title)], crossAxisAlignment: .start),
    onTap: onToggle,
    variant: .surface,
    leading: AuraIcon(isExpanded ? Icons.expand_less : Icons.expand_more),
  );
}

class const _CollapsibleToolContent({
  required final Widget empty,
  required final List<WorkspaceToolEntity> tools,
  required final AgentToolPermissionMode Function(String toolId) valueOf,
  required final void Function(String toolId, AgentToolPermissionMode value)
  onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (tools.isEmpty) return AuraText(child: empty, style: .bodySmall);

    return Column(
      children: [
        for (final tool in tools)
          _AgentToolPermissionTile(
            tool: tool,
            value: valueOf(tool.id),
            onChanged: (value) => onChanged(tool.id, value),
          ),
      ],
    );
  }
}

class _DialogSection({
  required final Widget title,
  required final Widget empty,
  required final List<Widget> children,
  required final bool isEmpty,
}) extends StatelessWidget {
  final Widget _child = Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: AuraColumn(
      children: [
        AuraText(child: title, style: .heading6),
        if (isEmpty) AuraText(child: empty, style: .bodySmall) else ...children,
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    ),
  );

  @override
  Widget build(BuildContext _) => _child;
}

class const _AgentSkillTile({
  required final WorkspaceSkill skill,
  required final bool selected,
  required final VoidCallback onTap,
  final bool disabled = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AgentSkillTileCard(
    data: (skill: skill, selected: selected, onTap: onTap, disabled: disabled),
  );
}

class const _AgentSkillTileCard({required final _AgentSkillTileData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AgentSkillTilePadding(data: data);
}

class const _AgentSkillTilePadding({required final _AgentSkillTileData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: _AgentSkillTileSurface(data: data),
  );
}

class const _AgentSkillTileSurface({required final _AgentSkillTileData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: _AgentSkillTileContent(skill: data.skill),
    onTap: data.onTap,
    variant: data.selected ? AuraTileVariant.selected : AuraTileVariant.surface,
    leading: _AgentSkillTileLeading(disabled: data.disabled),
    trailing: _AgentSkillTileTrailing(selected: data.selected),
  );
}

class const _AgentSkillTileContent({required final WorkspaceSkill skill})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _SkillTitle(skill: skill),
      AuraText(child: Text(skill.source.name), style: .bodySmall),
    ],
    crossAxisAlignment: .start,
  );
}

class const _AgentSkillTileLeading({required final bool disabled})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraIcon(disabled ? Icons.lock_outline : Icons.psychology_alt_outlined);
}

class const _AgentSkillTileTrailing({required final bool selected})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraIcon(selected ? Icons.check_circle : Icons.radio_button_unchecked);
}

class const _SkillTitle({required final WorkspaceSkill skill})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final titleKey = skill.titleKey;

    return titleKey == null ? Text(skill.title) : TextLocale(titleKey);
  }
}

class const _AgentToolPermissionTile({
  required final WorkspaceToolEntity tool,
  required final AgentToolPermissionMode value,
  required final ValueChanged<AgentToolPermissionMode> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: _AgentToolPermissionTileCard(
      tool: tool,
      value: value,
      onChanged: onChanged,
    ),
  );
}

class const _AgentToolPermissionTileCard({
  required final WorkspaceToolEntity tool,
  required final AgentToolPermissionMode value,
  required final ValueChanged<AgentToolPermissionMode> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: _AgentToolPermissionTileContent(
      tool: tool,
      value: value,
      onChanged: onChanged,
    ),
    variant: .surface,
    leading: AuraText(child: tool.getIconWidget()),
  );
}

class const _AgentToolPermissionTileContent({
  required final WorkspaceToolEntity tool,
  required final AgentToolPermissionMode value,
  required final ValueChanged<AgentToolPermissionMode> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraText(child: tool.getNameWidget()),
      _AgentToolDescription(tool: tool),
      _AgentToolPermissionSelector(value: value, onChanged: onChanged),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _AgentToolDescription({required final WorkspaceToolEntity tool})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: DefaultTextStyle.merge(
      overflow: .ellipsis,
      maxLines: 1,
      child: tool.getDescriptionWidget(),
    ),
    style: .bodySmall,
  );
}

class const _AgentToolPermissionSelector({
  required final AgentToolPermissionMode value,
  required final ValueChanged<AgentToolPermissionMode> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: .horizontal,
    child: AuraButtonGroup<AgentToolPermissionMode>.single(
      items: _agentToolPermissionItems,
      selectedValue: value,
      onChanged: onChanged,
      size: .sm,
    ),
  );
}

extension on WorkspaceSkill {
  DisableSkillRequest _enableRequest(String workspaceId) => (
    workspaceId: workspaceId,
    source: source,
    skillId: id,
    isEnabled: true,
    slug: null,
    title: null,
    description: null,
    content: null,
  );

  AgentSkillRef get ref {
    return switch (source) {
      .user => AgentSkillRef.user(id),
      .app => AgentSkillRef.app(id),
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
  String label() {
    return switch (this) {
      UserAgentSkillRef(:final skillId) => skillId,
      AppAgentSkillRef(:final identifier) => identifier,
    };
  }
}
