// Required: Existing UI spacing uses small numeric values.
// Required: Form callbacks stay local to this screen.
import 'dart:async';

import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/markdown/show_markdown_editor.dart';
import 'package:auravibes_app/features/markdown/widgets/markdown_preview_field.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credentials_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart'
    show appSkillRegistryProvider;
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/delete_cloud_routed_skill_usecases.dart';
import 'package:auravibes_app/features/skills/usecases/duplicate_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/duplicate_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AppSkillToolDefinition;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:textf/textf.dart';

const _skillDescriptionMaxCharacters = 1024;

class const SkillDetailScreen({
  required final String workspaceId,
  final String? skillId,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends ConsumerState<SkillDetailScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextfEditingController();
  final _contentController = TextEditingController();
  String? _credentialDefinitionId;
  bool _isCredentialOptional = false;
  bool _isEnabled = true;
  bool _initialized = false;
  bool _isSaving = false;
  SkillDetail? _formDetail;

  bool get _isCreate => widget.skillId == null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skillId = widget.skillId;
    final detailAsync = skillId == null
        ? null
        : ref.watch(skillDetailProvider(widget.workspaceId, skillId));
    final currentDetail = detailAsync?.value;
    final userSkillDetail = currentDetail != null && currentDetail.isUserSkill
        ? currentDetail
        : null;
    Widget? statusChild;
    if (detailAsync == null) {
      _formDetail = null;
    } else {
      switch (detailAsync) {
        case AsyncData(value: null):
          statusChild = const Center(
            child: TextLocale(LocaleKeys.skills_screen_not_found),
          );
        case AsyncData(value: final detail?):
          _initializeForm(context, detail);
          _formDetail = detail;
        case AsyncLoading(value: final SkillDetail detail, hasValue: true):
          _initializeForm(context, detail);
          _formDetail = detail;
        case AsyncLoading():
          statusChild = const Center(child: AuraSpinner());
        case AsyncError():
          statusChild = const Center(
            child: TextLocale(LocaleKeys.skills_screen_load_error),
          );
      }
    }
    final child =
        statusChild ??
        _SkillDetailForm(
          detail: _formDetail,
          workspaceId: widget.workspaceId,
          titleController: _titleController,
          descriptionController: _descriptionController,
          contentController: _contentController,
          credentialDefinitionId: _credentialDefinitionId,
          isCredentialOptional: _isCredentialOptional,
          isEnabled: _isEnabled,
          isSaving: _isSaving,
          onCredentialDefinitionChanged: _setCredentialDefinition,
          onCredentialOptionalChanged: (value) =>
              setState(() => _isCredentialOptional = value),
          onEnabledChanged: (value) => setState(() => _isEnabled = value),
          onEditDescription: () => _editDescription(context),
          onEditContent: () => _editContent(context),
          onSave: () => _save(context),
        );

    return AuraScreen(
      child: child,
      appBar: AuraAppBar(
        title: TextLocale(
          _isCreate
              ? LocaleKeys.skills_screen_create_title
              : LocaleKeys.skills_screen_detail_title,
        ),
        actions: [
          if (!_isCreate && userSkillDetail != null) ...[
            AuraIconButton(
              icon: Icons.copy_outlined,
              onPressed: _isSaving
                  ? null
                  : () => _duplicateSkill(context, userSkillDetail),
              tooltip: LocaleKeys.skills_screen_duplicate.tr(context: context),
            ),
            AuraIconButton(
              icon: Icons.delete_outline,
              onPressed: _isSaving
                  ? null
                  : () => _confirmDelete(context, userSkillDetail),
              tooltip: LocaleKeys.skills_screen_delete.tr(context: context),
            ),
          ],
          if (_isCreate || currentDetail?.isUserSkill == true)
            AuraIconButton(
              icon: Icons.save_outlined,
              onPressed: _isSaving ? null : () => _save(context),
              tooltip: LocaleKeys.skills_screen_save.tr(context: context),
            ),
        ],
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _editDescription(BuildContext context) async {
    final result = await MarkdownEditorLauncher.show(
      context,
      initialMarkdown: _descriptionController.text,
      maxCharacters: _skillDescriptionMaxCharacters,
    );
    if (result == null || !mounted) return;

    setState(() => _descriptionController.text = result);
  }

  Future<void> _editContent(BuildContext context) async {
    final result = await MarkdownEditorLauncher.show(
      context,
      initialMarkdown: _contentController.text,
    );
    if (result == null || !mounted) return;

    setState(() => _contentController.text = result);
  }

  void _setCredentialDefinition(String? value) {
    setState(() {
      _credentialDefinitionId = value;
      if (value == null) _isCredentialOptional = false;
    });
  }

  void _initializeForm(BuildContext context, SkillDetail detail) {
    if (_initialized) return;

    _titleController.text =
        detail.titleKey?.tr(context: context) ?? detail.title;
    _descriptionController.text =
        detail.descriptionKey?.tr(context: context) ?? detail.description;
    _contentController.text =
        detail.contentKey?.tr(context: context) ?? detail.content;
    _credentialDefinitionId = detail.credentialDefinitionId;
    _isCredentialOptional = detail.isCredentialOptional;
    _isEnabled = detail.isEnabled;
    _initialized = true;
  }

  Future<void> _save(BuildContext context) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    var didSave = false;
    try {
      await _saveSkill();
      didSave = true;
    } on Object {
      if (!context.mounted) return;
      final _ = AuraSnackBars.show(
        context: context,
        content: Text(LocaleKeys.skills_screen_save_error.tr(context: context)),
        variant: AuraSnackBarVariant.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!didSave || !context.mounted) return;
    _navigateAfterSave(context);
  }

  Future<void> _saveSkill() async {
    if (_isCreate) {
      final usecase = ref.read(createSkillUsecaseProvider(widget.workspaceId));
      final _ = await usecase.call(
        widget.workspaceId,
        SkillToCreate(
          kind: SkillKind.template,
          title: _titleController.text,
          description: _descriptionController.text,
          content: _contentController.text,
          credentialDefinitionId: _credentialDefinitionId,
          isCredentialOptional: _isCredentialOptional,
          isEnabled: _isEnabled,
        ),
      );

      return;
    }

    final skillId = widget.skillId;
    if (skillId == null) return;
    final usecase = ref.read(updateSkillUsecaseProvider(widget.workspaceId));
    final _ = await usecase.call(
      skillId,
      SkillToUpdate(
        title: _titleController.text,
        description: _descriptionController.text,
        content: _contentController.text,
        credentialDefinitionId: _credentialDefinitionId,
        clearCredentialDefinition: _credentialDefinitionId == null,
        isCredentialOptional: _isCredentialOptional,
        isEnabled: _isEnabled,
      ),
    );
  }

  void _navigateAfterSave(BuildContext context) {
    try {
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/workspaces/${widget.workspaceId}/more/skills');
      }
    } on Object {
      // Save already succeeded, so navigation failures are not save errors.
    }
  }

  Future<void> _duplicateSkill(BuildContext context, SkillDetail detail) async {
    setState(() => _isSaving = true);
    try {
      final usecase = ref.read(
        duplicateSkillUsecaseProvider(widget.workspaceId),
      );
      final _ = await usecase.call(detail.id);
      ref.invalidate(workspaceSkillsProvider(widget.workspaceId));
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } on Object {
      if (!context.mounted) return;
      final _ = AuraSnackBars.show(
        context: context,
        content: Text(LocaleKeys.skills_screen_save_error.tr(context: context)),
        variant: AuraSnackBarVariant.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context, SkillDetail detail) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AuraConfirmDialog(
        title: const TextLocale(LocaleKeys.skills_screen_delete),
        message: const TextLocale(LocaleKeys.skills_screen_delete_confirm),
        confirmLabel: Text(
          LocaleKeys.skills_screen_delete.tr(context: context),
        ),
        cancelLabel: Text(LocaleKeys.common_cancel.tr(context: context)),
        isDestructive: true,
      ),
    );
    if (shouldDelete != true) return;
    await ref.read(deleteSkillProvider(widget.workspaceId))(detail.id);
    ref.invalidate(workspaceSkillsProvider(widget.workspaceId));
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

class const _SkillDetailForm({
  required final SkillDetail? detail,
  required final String workspaceId,
  required final TextEditingController titleController,
  required final TextEditingController descriptionController,
  required final TextEditingController contentController,
  required final String? credentialDefinitionId,
  required final bool isCredentialOptional,
  required final bool isEnabled,
  required final bool isSaving,
  required final ValueChanged<String?> onCredentialDefinitionChanged,
  required final ValueChanged<bool> onCredentialOptionalChanged,
  required final ValueChanged<bool> onEnabledChanged,
  required final VoidCallback onEditDescription,
  required final VoidCallback onEditContent,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final detail = this.detail;
    final isCreate = detail == null;
    final isReadOnly = detail != null && !detail.isUserSkill;
    final canEdit = isCreate || !isReadOnly;
    final canSave = isCreate || !isReadOnly;
    final credentialDefinitionId = this.credentialDefinitionId;
    final skillFields = <Widget>[
      if (isReadOnly)
        const AuraText(
          child: TextLocale(LocaleKeys.skills_screen_app_read_only),
        ),
      if (detail != null)
        _ReadOnlyField(
          labelKey: LocaleKeys.skills_screen_slug_label,
          value: detail.slug,
        ),
      AuraInput(
        controller: titleController,
        label: Text(LocaleKeys.skills_screen_title_label.tr(context: context)),
        enabled: !isReadOnly,
      ),
      MarkdownPreviewField(
        controller: descriptionController,
        titleKey: LocaleKeys.skills_screen_description_label,
        editKey: LocaleKeys.skills_screen_edit_description,
        emptyKey: LocaleKeys.skills_screen_description_empty,
        onEdit: onEditDescription,
        isReadOnly: isReadOnly,
      ),
      MarkdownPreviewField(
        controller: contentController,
        titleKey: LocaleKeys.skills_screen_content_label,
        editKey: LocaleKeys.skills_screen_edit_content,
        emptyKey: LocaleKeys.skills_screen_content_empty,
        onEdit: onEditContent,
        isReadOnly: isReadOnly,
      ),
      AuraRow(
        children: [
          AuraSwitch(
            value: isEnabled,
            onChanged: isReadOnly ? null : onEnabledChanged,
            disabled: isReadOnly,
          ),
          const Expanded(
            child: AuraText(
              child: TextLocale(LocaleKeys.skills_screen_enabled_label),
            ),
          ),
        ],
        spacing: .md,
      ),
    ];
    final credentialFields = <Widget>[
      if (canEdit)
        _CredentialDefinitionSelector(
          workspaceId: workspaceId,
          value: credentialDefinitionId,
          onChanged: onCredentialDefinitionChanged,
        ),
      if (canEdit && credentialDefinitionId != null)
        AuraCheckboxListTile(
          value: isCredentialOptional,
          onChanged: onCredentialOptionalChanged,
          title: const TextLocale(
            LocaleKeys.skills_screen_credential_optional_label,
          ),
          subtitle: const TextLocale(
            LocaleKeys.skills_screen_credential_optional_hint,
          ),
        ),
      if (detail != null && credentialDefinitionId != null)
        _SkillCredentialsHint(
          workspaceId: workspaceId,
          credentialDefinitionId: credentialDefinitionId,
          isCredentialOptional: isCredentialOptional,
        ),
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AuraCard(
          child: AuraColumn(
            children: [
              ...skillFields,
              ...credentialFields,
              if (canSave)
                Align(
                  alignment: Alignment.centerRight,
                  child: AuraButton(
                    onPressed: onSave,
                    child: TextLocale(
                      isCreate
                          ? LocaleKeys.skills_screen_create
                          : LocaleKeys.skills_screen_save,
                    ),
                    disabled: isSaving,
                  ),
                ),
            ],
            spacing: .md,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ),
        if (detail != null &&
            !detail.isUserSkill &&
            detail.appTools.any((tool) => tool.requiresCredential)) ...[
          const SizedBox(height: 12),
          _AppSkillCredentialsHint(
            workspaceId: workspaceId,
            appSkillId: detail.id,
          ),
        ],
        if (detail != null && detail.isUserSkill) ...[
          const SizedBox(height: 12),
          _SkillToolsCard(workspaceId: workspaceId, skillId: detail.id),
        ],
        if (detail != null &&
            !detail.isUserSkill &&
            detail.appTools.isNotEmpty) ...[
          const SizedBox(height: 12),
          _AppSkillToolsCard(tools: detail.appTools),
        ],
      ],
    );
  }
}

class const _SkillToolsCard({
  required final String workspaceId,
  required final String skillId,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsAsync = ref.watch(
      skillTemplateToolsProvider(workspaceId, skillId),
    );

    return AuraCard(
      child: AuraColumn(
        children: [
          Row(
            children: [
              const Expanded(
                child: AuraText(
                  child: TextLocale(LocaleKeys.skills_tool_section_title),
                  style: AuraTextStyle.heading4,
                ),
              ),
              AuraIconButton(
                icon: Icons.add,
                onPressed: () => _openNewTool(context),
                tooltip: LocaleKeys.skills_tool_create_title.tr(
                  context: context,
                ),
              ),
            ],
          ),
          switch (toolsAsync) {
            AsyncData(:final value) =>
              value.isEmpty
                  ? const AuraText(
                      child: TextLocale(LocaleKeys.skills_tool_empty),
                    )
                  : AuraColumn(
                      children: [
                        for (final tool in value)
                          AuraTile(
                            child: AuraColumn(
                              children: [
                                AuraText(child: Text(tool.title)),
                                AuraText(child: Text(tool.slug)),
                              ],
                              spacing: .xs,
                              crossAxisAlignment: CrossAxisAlignment.start,
                            ),
                            onTap: () => _openTool(context, tool.id),
                            variant: AuraTileVariant.ghost,
                            leading: const AuraIcon(Icons.link_outlined),
                            trailing: AuraRow(
                              children: [
                                AuraIconButton(
                                  icon: Icons.copy_outlined,
                                  onPressed: () => _duplicateTool(ref, tool),
                                ),
                                AuraIconButton(
                                  icon: Icons.delete_outline,
                                  onPressed: () =>
                                      _confirmDeleteTool(context, ref, tool),
                                ),
                                const AuraIcon(Icons.chevron_right),
                              ],
                              mainAxisSize: MainAxisSize.min,
                            ),
                          ),
                      ],
                    ),
            AsyncLoading(value: final value?, hasValue: true) => AuraText(
              child: Text('${value.length}'),
            ),
            AsyncLoading() => const Center(child: AuraSpinner()),
            AsyncError() => const AuraText(
              child: TextLocale(LocaleKeys.skills_tool_load_error),
              tint: AuraTint.error,
            ),
          },
        ],
        spacing: .sm,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  Future<void> _openNewTool(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final result = await context.push<bool>(
      '/workspaces/$workspaceId/more/skills/$skillId/tools/new',
    );
    if (result == true) {
      _scheduleToolsRefresh(container);
    }
  }

  Future<void> _openTool(BuildContext context, String toolId) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final result = await context.push<bool>(
      '/workspaces/$workspaceId/more/skills/$skillId/tools/$toolId',
    );
    if (result == true) {
      _scheduleToolsRefresh(container);
    }
  }

  void _scheduleToolsRefresh(ProviderContainer container) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshToolsAfterFrame(container));
    });
  }

  Future<void> _refreshToolsAfterFrame(ProviderContainer container) async {
    await container.pump();
    container.invalidate(skillTemplateToolsProvider(workspaceId, skillId));
  }

  Future<void> _duplicateTool(
    WidgetRef ref,
    SkillTemplateToolEntity tool,
  ) async {
    final usecase = ref.read(
      duplicateSkillTemplateToolUsecaseProvider(workspaceId),
    );
    final _ = await usecase.call(tool.id);
    ref.invalidate(skillTemplateToolsProvider(workspaceId, skillId));
  }

  Future<void> _confirmDeleteTool(
    BuildContext context,
    WidgetRef ref,
    SkillTemplateToolEntity tool,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AuraConfirmDialog(
        title: const TextLocale(LocaleKeys.skills_tool_delete_title),
        message: const TextLocale(LocaleKeys.skills_tool_delete_confirm),
        confirmLabel: Text(LocaleKeys.common_delete.tr(context: context)),
        cancelLabel: Text(LocaleKeys.common_cancel.tr(context: context)),
        isDestructive: true,
      ),
    );
    if (shouldDelete != true) return;
    await ref.read(deleteSkillTemplateToolProvider(workspaceId))(tool.id);
    ref.invalidate(skillTemplateToolsProvider(workspaceId, skillId));
  }
}

class const _AppSkillToolsCard({
  required final List<AppSkillToolDefinition> tools,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: AuraColumn(
        children: [
          const AuraText(
            child: TextLocale(LocaleKeys.skills_tool_section_title),
            style: AuraTextStyle.heading4,
          ),
          for (final tool in tools)
            AuraTile(
              child: AuraColumn(
                children: [
                  AuraText(
                    child: switch (tool.titleKey) {
                      null => Text(tool.title),
                      final titleKey => TextLocale(titleKey),
                    },
                  ),
                  AuraBadge.text(
                    child: Text(
                      tool.slug,
                      style: TextStyle(
                        fontFamily: context.auraTheme.typography.monoFontFamily,
                      ),
                    ),
                    variant: AuraBadgeVariant.outlined,
                    size: AuraBadgeSize.small,
                  ),
                  AuraText(
                    child: switch (tool.descriptionKey) {
                      null => Text(tool.description),
                      final descriptionKey => TextLocale(descriptionKey),
                    },
                  ),
                ],
                spacing: .xs,
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              variant: AuraTileVariant.ghost,
              leading: const AuraIcon(Icons.code_outlined),
            ),
        ],
        spacing: .sm,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}

class const _CredentialDefinitionSelector({
  required final String workspaceId,
  required final String? value,
  required final ValueChanged<String?> onChanged,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitionsAsync = ref.watch(
      skillCredentialDefinitionsProvider(workspaceId),
    );

    return switch (definitionsAsync) {
      AsyncData(:final value) => _CredentialDefinitionSelectContent(
        definitions: value,
        value: this.value,
        onChanged: onChanged,
      ),
      AsyncLoading() => const AuraSpinner(size: AuraSpinnerSize.small),
      AsyncError() => const AuraText(
        child: TextLocale(LocaleKeys.skill_credentials_definitions_error),
        tint: AuraTint.error,
      ),
    };
  }
}

class const _CredentialDefinitionSelectContent({
  required final List<SkillCredentialDefinitionEntity> definitions,
  required final String? value,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  static const _noneValue = '';
  @override
  Widget build(BuildContext context) {
    final hasSelectedDefinition =
        value != null &&
        definitions.any((definition) => definition.id == value);
    final hasMissingDefinition = value != null && !hasSelectedDefinition;

    return AuraColumn(
      children: [
        AuraDropdownSelector<String>(
          options: [
            AuraDropdownOption<String>(
              value: _noneValue,
              child: Text(
                LocaleKeys.skill_credentials_none.tr(context: context),
              ),
            ),
            for (final definition in definitions)
              AuraDropdownOption<String>(
                value: definition.id,
                child: Text(definition.title),
              ),
          ],
          value: hasSelectedDefinition ? value : _noneValue,
          onChanged: (value) {
            onChanged(value == _noneValue ? null : value);
          },
          label: Text(
            LocaleKeys.skill_credentials_definition_label.tr(context: context),
          ),
        ),
        if (hasMissingDefinition)
          const AuraText(
            child: TextLocale(
              LocaleKeys.skill_credentials_definitions_not_found,
            ),
            tint: AuraTint.error,
          ),
      ],
      spacing: .xs,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}

class const _SkillCredentialsHint({
  required final String workspaceId,
  required final String credentialDefinitionId,
  required final bool isCredentialOptional,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitionAsync = ref.watch(
      skillCredentialDefinitionProvider(workspaceId, credentialDefinitionId),
    );
    final credentialsAsync = ref.watch(
      skillCredentialsForDefinitionProvider(
        workspaceId,
        credentialDefinitionId,
      ),
    );

    return switch ((
      definition: definitionAsync,
      credentials: credentialsAsync,
    )) {
      (definition: AsyncData(value: null), credentials: _) =>
        const SizedBox.shrink(),
      (definition: AsyncData(), credentials: AsyncData(:final value)) =>
        _LoadedCredentialsHint(
          credentials: value,
          isCredentialOptional: isCredentialOptional,
          onCreateCredential: () => _openCredentialCreate(context),
        ),
      (definition: AsyncLoading(), credentials: _) ||
      (
        definition: _,
        credentials: AsyncLoading(),
      ) => const AuraSpinner(size: AuraSpinnerSize.small),
      (definition: AsyncError(), credentials: _) ||
      (definition: _, credentials: AsyncError()) => const AuraText(
        child: TextLocale(LocaleKeys.skill_credentials_load_error),
        tint: AuraTint.error,
      ),
    };
  }

  Future<void> _openCredentialCreate(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final result = await ServiceConnectionCreateRoute(
      workspaceId: workspaceId,
      type: 'skillCredential',
      credentialDefinitionId: credentialDefinitionId,
    ).push<bool>(context);
    if (!context.mounted) return;
    if (result == true) {
      _scheduleCredentialRefresh(
        container,
        workspaceId,
        credentialDefinitionId,
      );
    }
  }

  void _scheduleCredentialRefresh(
    ProviderContainer container,
    String workspaceId,
    String credentialDefinitionId,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _refreshCredentialAfterFrame(
          container,
          workspaceId,
          credentialDefinitionId,
        ),
      );
    });
  }

  Future<void> _refreshCredentialAfterFrame(
    ProviderContainer container,
    String workspaceId,
    String credentialDefinitionId,
  ) async {
    await container.pump();
    container.invalidate(
      skillCredentialsForDefinitionProvider(
        workspaceId,
        credentialDefinitionId,
      ),
    );
  }
}

class const _AppSkillCredentialsHint({
  required final String workspaceId,
  required final String appSkillId,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AppSkillCredentialsHint> createState() =>
      _AppSkillCredentialsHintState();
}

class _AppSkillCredentialsHintState
    extends ConsumerState<_AppSkillCredentialsHint> {
  Future<List<AppSkillCredentialCandidate>> _future = Future.value(const []);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(_AppSkillCredentialsHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId == widget.workspaceId &&
        oldWidget.appSkillId == widget.appSkillId) {
      return;
    }
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppSkillCredentialCandidate>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MissingCredentialHint(
            isCredentialOptional: false,
            onCreateCredential: () => _openCredentialCreate(context),
          );
        }

        final credentials = snapshot.data;
        if (credentials == null) {
          return const AuraSpinner(size: AuraSpinnerSize.small);
        }
        if (credentials.isEmpty) {
          return _MissingCredentialHint(
            isCredentialOptional: false,
            onCreateCredential: () => _openCredentialCreate(context),
          );
        }

        return AuraText(
          child: Text(
            LocaleKeys.skill_credentials_configured_count.plural(
              credentials.length,
              args: ['${credentials.length}'],
              context: context,
            ),
          ),
        );
      },
    );
  }

  Future<List<AppSkillCredentialCandidate>> _load() async {
    final appSkill = ref
        .read(appSkillRegistryProvider)
        .getByIdentifier(widget.appSkillId);
    if (appSkill == null) return const [];

    return await ref
        .read(listAppSkillCredentialCandidatesUsecaseProvider)
        .call(workspaceId: widget.workspaceId, skill: appSkill);
  }

  Future<void> _openCredentialCreate(BuildContext context) async {
    final appSkill = ref
        .read(appSkillRegistryProvider)
        .getByIdentifier(widget.appSkillId);
    if (appSkill == null) return;

    final result = appSkill.compatibleModelProviderIds.isNotEmpty
        ? await ServiceConnectionCreateRoute(
            workspaceId: widget.workspaceId,
            type: 'modelProvider',
          ).push<bool>(context)
        : await context.push<bool>(
            '/workspaces/${widget.workspaceId}/more/service-connections/new'
            '?type=appSkillCredential&appSkillId=${widget.appSkillId}',
          );
    if (!mounted || result != true) return;
    setState(() {
      _future = _load();
    });
  }
}

class const _LoadedCredentialsHint({
  required final List<SkillCredentialEntity> credentials,
  required final bool isCredentialOptional,
  required final VoidCallback onCreateCredential,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (credentials.isEmpty) {
      return _MissingCredentialHint(
        isCredentialOptional: isCredentialOptional,
        onCreateCredential: onCreateCredential,
      );
    }

    return AuraText(
      child: Text(
        LocaleKeys.skill_credentials_configured_count.plural(
          credentials.length,
          args: ['${credentials.length}'],
          context: context,
        ),
      ),
    );
  }
}

class const _MissingCredentialHint({
  required final bool isCredentialOptional,
  required final VoidCallback onCreateCredential,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hintKey = isCredentialOptional
        ? LocaleKeys.skill_credentials_optional_missing_hint
        : LocaleKeys.skill_credentials_missing_hint;

    return Row(
      children: [
        Expanded(
          child: AuraText(
            child: TextLocale(hintKey),
            tint: isCredentialOptional ? null : AuraTint.error,
          ),
        ),
        AuraButton(
          onPressed: onCreateCredential,
          child: const TextLocale(LocaleKeys.skill_credentials_add_title),
          size: AuraButtonSize.small,
        ),
      ],
    );
  }
}

class const _ReadOnlyField({
  required final String labelKey,
  required final String value,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        AuraText(child: TextLocale(labelKey)),
        AuraSelectableText(value),
      ],
      spacing: .xs,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}
