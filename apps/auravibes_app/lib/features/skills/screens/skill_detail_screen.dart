// ignore_for_file: no-magic-number
// Required: Existing UI spacing uses small numeric values.
// ignore_for_file: prefer-extracting-callbacks
// Required: Form callbacks stay local to this screen.
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credentials_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/providers/workspace_skills_provider.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/delete_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/delete_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/duplicate_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/duplicate_skill_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/services/skills/models/app_skill_tool_definition.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SkillDetailScreen extends ConsumerStatefulWidget {
  const SkillDetailScreen({
    required this.workspaceId,
    this.skillId,
    super.key,
  });

  final String workspaceId;
  final String? skillId;

  @override
  ConsumerState<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends ConsumerState<SkillDetailScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  String? _credentialDefinitionId;
  bool _isCredentialOptional = false;
  bool _isEnabled = true;
  bool _initialized = false;
  bool _isSaving = false;

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

    return AuraScreen(
      child: skillId == null
          ? _buildForm(context, null)
          : switch (detailAsync!) {
              AsyncData(:final value) =>
                value == null
                    ? const Center(
                        child: TextLocale(LocaleKeys.skills_screen_not_found),
                      )
                    : _buildForm(context, value),
              AsyncLoading() when currentDetail != null => _buildForm(
                context,
                currentDetail,
              ),
              AsyncLoading() => const Center(
                child: AuraSpinner(),
              ),
              AsyncError() => const Center(
                child: TextLocale(LocaleKeys.skills_screen_load_error),
              ),
            },
      appBar: AuraAppBar(
        title: TextLocale(
          _isCreate
              ? LocaleKeys.skills_screen_create_title
              : LocaleKeys.skills_screen_detail_title,
        ),
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isCreate && currentDetail?.isUserSkill == true) ...[
            AuraIconButton(
              icon: Icons.copy_outlined,
              onPressed: _isSaving
                  ? null
                  : () => _duplicateSkill(context, currentDetail!),
              tooltip: LocaleKeys.skills_screen_duplicate.tr(context: context),
            ),
            AuraIconButton(
              icon: Icons.delete_outline,
              onPressed: _isSaving
                  ? null
                  : () => _confirmDelete(context, currentDetail!),
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
      ),
    );
  }

  Widget _buildForm(BuildContext context, SkillDetail? detail) {
    if (detail != null && !_initialized) {
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

    final isReadOnly = detail != null && !detail.isUserSkill;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AuraCard(
          child: AuraColumn(
            spacing: AuraSpacing.md,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isReadOnly)
                const AuraText(
                  child: TextLocale(LocaleKeys.skills_screen_app_read_only),
                  color: AuraColorVariant.onSurfaceVariant,
                ),
              if (detail != null)
                _ReadOnlyField(
                  labelKey: LocaleKeys.skills_screen_slug_label,
                  value: detail.slug,
                ),
              AuraInput(
                controller: _titleController,
                enabled: !isReadOnly,
                label: Text(
                  LocaleKeys.skills_screen_title_label.tr(context: context),
                ),
              ),
              AuraInput(
                controller: _descriptionController,
                enabled: !isReadOnly,
                label: Text(
                  LocaleKeys.skills_screen_description_label.tr(
                    context: context,
                  ),
                ),
              ),
              AuraInput(
                controller: _contentController,
                enabled: !isReadOnly,
                minLines: 8,
                maxLines: 16,
                label: Text(
                  LocaleKeys.skills_screen_content_label.tr(context: context),
                ),
              ),
              AuraRow(
                spacing: AuraSpacing.md,
                children: [
                  AuraSwitch(
                    value: _isEnabled,
                    onChanged: isReadOnly
                        ? null
                        : (value) => setState(() => _isEnabled = value),
                    disabled: isReadOnly,
                  ),
                  const Expanded(
                    child: AuraText(
                      child: TextLocale(
                        LocaleKeys.skills_screen_enabled_label,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isCreate || !isReadOnly)
                _CredentialDefinitionSelector(
                  workspaceId: widget.workspaceId,
                  value: _credentialDefinitionId,
                  onChanged: (value) {
                    setState(() {
                      _credentialDefinitionId = value;
                      if (value == null) _isCredentialOptional = false;
                    });
                  },
                ),
              if ((_isCreate || !isReadOnly) && _credentialDefinitionId != null)
                AuraCheckboxListTile(
                  value: _isCredentialOptional,
                  onChanged: (value) {
                    setState(() => _isCredentialOptional = value);
                  },
                  title: const TextLocale(
                    LocaleKeys.skills_screen_credential_optional_label,
                  ),
                  subtitle: const TextLocale(
                    LocaleKeys.skills_screen_credential_optional_hint,
                  ),
                ),
              if (detail != null && _credentialDefinitionId != null)
                _SkillCredentialsHint(
                  workspaceId: widget.workspaceId,
                  credentialDefinitionId: _credentialDefinitionId!,
                  isCredentialOptional: _isCredentialOptional,
                ),
              if (_isCreate || !isReadOnly)
                Align(
                  alignment: Alignment.centerRight,
                  child: AuraButton(
                    onPressed: () => _save(context),
                    disabled: _isSaving,
                    child: TextLocale(
                      _isCreate
                          ? LocaleKeys.skills_screen_create
                          : LocaleKeys.skills_screen_save,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (detail != null && detail.isUserSkill) ...[
          const SizedBox(height: 12),
          _SkillToolsCard(
            workspaceId: widget.workspaceId,
            skillId: detail.id,
          ),
        ] else if (detail != null && detail.appTools.isNotEmpty) ...[
          const SizedBox(height: 12),
          _AppSkillToolsCard(tools: detail.appTools),
        ],
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    var didSave = false;
    try {
      if (_isCreate) {
        final usecase = ref.read(createSkillUsecaseProvider);
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
      } else {
        final usecase = ref.read(updateSkillUsecaseProvider);
        final _ = await usecase.call(
          widget.skillId!,
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
      didSave = true;
    } on Object {
      if (!context.mounted) return;
      showAuraSnackBar(
        context: context,
        variant: AuraSnackBarVariant.error,
        content: Text(
          LocaleKeys.skills_screen_save_error.tr(context: context),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!didSave || !context.mounted) return;
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
      final usecase = ref.read(duplicateSkillUsecaseProvider);
      final _ = await usecase.call(detail.id);
      ref.invalidate(workspaceSkillsProvider(widget.workspaceId));
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } on Object {
      if (!context.mounted) return;
      showAuraSnackBar(
        context: context,
        variant: AuraSnackBarVariant.error,
        content: Text(
          LocaleKeys.skills_screen_save_error.tr(context: context),
        ),
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
        cancelLabel: Text(LocaleKeys.common_cancel.tr(context: context)),
        confirmLabel: Text(
          LocaleKeys.skills_screen_delete.tr(context: context),
        ),
        isDestructive: true,
      ),
    );
    if (shouldDelete != true) return;
    final usecase = ref.read(deleteSkillUsecaseProvider);
    final _ = await usecase.call(detail.id);
    ref.invalidate(workspaceSkillsProvider(widget.workspaceId));
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

class _SkillToolsCard extends ConsumerWidget {
  const _SkillToolsCard({
    required this.workspaceId,
    required this.skillId,
  });

  final String workspaceId;
  final String skillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsAsync = ref.watch(skillTemplateToolsProvider(skillId));

    return AuraCard(
      child: AuraColumn(
        spacing: AuraSpacing.sm,
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      color: AuraColorVariant.onSurfaceVariant,
                    )
                  : AuraColumn(
                      children: [
                        for (final tool in value)
                          AuraTile(
                            onTap: () => _openTool(context, tool.id),
                            variant: AuraTileVariant.ghost,
                            leading: const AuraIcon(Icons.link_outlined),
                            trailing: AuraRow(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AuraIconButton(
                                  icon: Icons.copy_outlined,
                                  onPressed: () => _duplicateTool(ref, tool),
                                ),
                                AuraIconButton(
                                  icon: Icons.delete_outline,
                                  onPressed: () => _confirmDeleteTool(
                                    context,
                                    ref,
                                    tool,
                                  ),
                                ),
                                const AuraIcon(Icons.chevron_right),
                              ],
                            ),
                            child: AuraColumn(
                              spacing: AuraSpacing.xs,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AuraText(child: Text(tool.title)),
                                AuraText(
                                  child: Text(tool.slug),
                                  color: AuraColorVariant.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            AsyncLoading(:final value, hasValue: true) => AuraText(
              child: Text('${value!.length}'),
            ),
            AsyncLoading() => const Center(child: AuraSpinner()),
            AsyncError() => const AuraText(
              child: TextLocale(LocaleKeys.skills_tool_load_error),
              color: AuraColorVariant.error,
            ),
          },
        ],
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await container.pump();
      container.invalidate(skillTemplateToolsProvider(skillId));
    });
  }

  Future<void> _duplicateTool(
    WidgetRef ref,
    SkillTemplateToolEntity tool,
  ) async {
    final usecase = ref.read(duplicateSkillTemplateToolUsecaseProvider);
    final _ = await usecase.call(tool.id);
    ref.invalidate(skillTemplateToolsProvider(skillId));
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
        cancelLabel: Text(LocaleKeys.common_cancel.tr(context: context)),
        confirmLabel: Text(LocaleKeys.common_delete.tr(context: context)),
        isDestructive: true,
      ),
    );
    if (shouldDelete != true) return;
    final usecase = ref.read(deleteSkillTemplateToolUsecaseProvider);
    final _ = await usecase.call(tool.id);
    ref.invalidate(skillTemplateToolsProvider(skillId));
  }
}

class _AppSkillToolsCard extends StatelessWidget {
  const _AppSkillToolsCard({required this.tools});

  final List<AppSkillToolDefinition> tools;

  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: AuraColumn(
        spacing: AuraSpacing.sm,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuraText(
            child: TextLocale(LocaleKeys.skills_tool_section_title),
            style: AuraTextStyle.heading4,
          ),
          for (final tool in tools)
            AuraTile(
              variant: AuraTileVariant.ghost,
              leading: const AuraIcon(Icons.code_outlined),
              child: AuraColumn(
                spacing: AuraSpacing.xs,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuraText(
                    child: tool.titleKey == null
                        ? Text(tool.title)
                        : TextLocale(tool.titleKey!),
                  ),
                  AuraText(
                    child: tool.descriptionKey == null
                        ? Text('${tool.slug}\n${tool.description}')
                        : Text(
                            '${tool.slug}\n'
                            '${tool.descriptionKey!.tr(context: context)}',
                          ),
                    color: AuraColorVariant.onSurfaceVariant,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CredentialDefinitionSelector extends ConsumerWidget {
  const _CredentialDefinitionSelector({
    required this.workspaceId,
    required this.value,
    required this.onChanged,
  });

  final String workspaceId;
  final String? value;
  final ValueChanged<String?> onChanged;

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
        color: AuraColorVariant.error,
      ),
    };
  }
}

class _CredentialDefinitionSelectContent extends StatelessWidget {
  const _CredentialDefinitionSelectContent({
    required this.definitions,
    required this.value,
    required this.onChanged,
  });

  final List<SkillCredentialDefinitionEntity> definitions;
  final String? value;
  final ValueChanged<String?> onChanged;

  static const _noneValue = '';

  @override
  Widget build(BuildContext context) {
    final hasSelectedDefinition =
        value != null &&
        definitions.any((definition) => definition.id == value);
    final hasMissingDefinition = value != null && !hasSelectedDefinition;

    return AuraColumn(
      spacing: AuraSpacing.xs,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuraDropdownSelector<String>(
          value: hasSelectedDefinition ? value : _noneValue,
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
            color: AuraColorVariant.error,
          ),
      ],
    );
  }
}

class _SkillCredentialsHint extends ConsumerWidget {
  const _SkillCredentialsHint({
    required this.workspaceId,
    required this.credentialDefinitionId,
    required this.isCredentialOptional,
  });

  final String workspaceId;
  final String credentialDefinitionId;
  final bool isCredentialOptional;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitionAsync = ref.watch(
      skillCredentialDefinitionProvider(credentialDefinitionId),
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
        value.isEmpty
            ? Row(
                children: [
                  Expanded(
                    child: AuraText(
                      child: TextLocale(
                        isCredentialOptional
                            ? LocaleKeys.skill_credentials_optional_missing_hint
                            : LocaleKeys.skill_credentials_missing_hint,
                      ),
                      color: isCredentialOptional
                          ? AuraColorVariant.onSurfaceVariant
                          : AuraColorVariant.error,
                    ),
                  ),
                  AuraButton(
                    onPressed: () async {
                      final container = ProviderScope.containerOf(
                        context,
                        listen: false,
                      );
                      final result =
                          await ServiceConnectionCreateRoute(
                            workspaceId: workspaceId,
                            type: 'skillCredential',
                            credentialDefinitionId: credentialDefinitionId,
                          ).push<bool>(
                            context,
                          );
                      if (!context.mounted) return;
                      if (result == true) {
                        _scheduleCredentialRefresh(
                          container,
                          workspaceId,
                          credentialDefinitionId,
                        );
                      }
                    },
                    size: AuraButtonSize.small,
                    child: const TextLocale(
                      LocaleKeys.skill_credentials_add_title,
                    ),
                  ),
                ],
              )
            : AuraText(
                child: Text(
                  (value.length == 1
                          ? LocaleKeys.skill_credentials_configured_count_one
                          : LocaleKeys.skill_credentials_configured_count_other)
                      .tr(
                        args: ['${value.length}'],
                        context: context,
                      ),
                ),
                color: AuraColorVariant.onSurfaceVariant,
              ),
      (definition: AsyncLoading(), credentials: _) ||
      (definition: _, credentials: AsyncLoading()) => const AuraSpinner(
        size: AuraSpinnerSize.small,
      ),
      (definition: AsyncError(), credentials: _) ||
      (definition: _, credentials: AsyncError()) => const AuraText(
        child: TextLocale(LocaleKeys.skill_credentials_load_error),
        color: AuraColorVariant.error,
      ),
    };
  }

  void _scheduleCredentialRefresh(
    ProviderContainer container,
    String workspaceId,
    String credentialDefinitionId,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await container.pump();
      container.invalidate(
        skillCredentialsForDefinitionProvider(
          workspaceId,
          credentialDefinitionId,
        ),
      );
    });
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.labelKey, required this.value});

  final String labelKey;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      spacing: AuraSpacing.xs,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuraText(
          child: TextLocale(labelKey),
          color: AuraColorVariant.onSurfaceVariant,
        ),
        AuraSelectableText(value),
      ],
    );
  }
}
