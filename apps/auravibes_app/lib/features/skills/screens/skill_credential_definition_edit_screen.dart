// ignore_for_file: no-magic-number
// Required: Existing UI spacing uses small numeric values.
import 'dart:convert';

import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/delete_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SkillCredentialDefinitionEditScreen extends ConsumerStatefulWidget {
  const SkillCredentialDefinitionEditScreen({
    required this.workspaceId,
    this.definitionId,
    super.key,
  });

  final String workspaceId;
  final String? definitionId;

  @override
  ConsumerState<SkillCredentialDefinitionEditScreen> createState() =>
      _SkillCredentialDefinitionEditScreenState();
}

class _SkillCredentialDefinitionEditScreenState
    extends ConsumerState<SkillCredentialDefinitionEditScreen> {
  final _titleController = TextEditingController();
  final _attributeRows = <_AttributeFormRow>[];
  bool _initialized = false;
  bool _isSaving = false;

  bool get _isCreate => widget.definitionId == null;

  @override
  void dispose() {
    _titleController.dispose();
    for (final row in _attributeRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final definitionId = widget.definitionId;
    final definitionAsync = definitionId == null
        ? null
        : ref.watch(skillCredentialDefinitionProvider(definitionId));
    final currentDefinition = definitionAsync?.value;
    final Widget child;
    if (definitionAsync == null) {
      _initializeForm(null);
      child = _SkillCredentialDefinitionForm(
        definition: null,
        titleController: _titleController,
        attributeRows: _attributeRows,
        isSaving: _isSaving,
        onAddAttributeRow: _addAttributeRow,
        onDeleteAttributeRow: _deleteAttributeRow,
        onSave: () => _save(context),
        onChanged: () => setState(() {
          final _ = Object();
        }),
      );
    } else {
      child = switch (definitionAsync) {
        AsyncData(value: null) => const Center(
          child: TextLocale(
            LocaleKeys.skill_credentials_definitions_not_found,
          ),
        ),
        AsyncData(value: final definition?) => () {
          _initializeForm(definition);

          return _SkillCredentialDefinitionForm(
            definition: definition,
            titleController: _titleController,
            attributeRows: _attributeRows,
            isSaving: _isSaving,
            onAddAttributeRow: _addAttributeRow,
            onDeleteAttributeRow: _deleteAttributeRow,
            onSave: () => _save(context),
            onChanged: () => setState(() {
              final _ = Object();
            }),
          );
        }(),
        AsyncLoading() when currentDefinition != null => () {
          _initializeForm(currentDefinition);

          return _SkillCredentialDefinitionForm(
            definition: currentDefinition,
            titleController: _titleController,
            attributeRows: _attributeRows,
            isSaving: _isSaving,
            onAddAttributeRow: _addAttributeRow,
            onDeleteAttributeRow: _deleteAttributeRow,
            onSave: () => _save(context),
            onChanged: () => setState(() {
              final _ = Object();
            }),
          );
        }(),
        AsyncLoading() => const Center(
          child: AuraSpinner(),
        ),
        AsyncError() => const Center(
          child: TextLocale(
            LocaleKeys.skill_credentials_definitions_error,
          ),
        ),
      };
    }

    return AuraScreen(
      child: child,
      appBar: AuraAppBar(
        title: TextLocale(
          _isCreate
              ? LocaleKeys.skill_credentials_definitions_create_title
              : LocaleKeys.skill_credentials_definitions_edit_title,
        ),
        actions: [
          if (!_isCreate)
            AuraIconButton(
              icon: Icons.delete_outline,
              onPressed: _isSaving ? null : () => _confirmDelete(context),
              tooltip: LocaleKeys.skill_credentials_definitions_delete_title.tr(
                context: context,
              ),
            ),
          AuraIconButton(
            icon: Icons.save_outlined,
            onPressed: _isSaving ? null : () => _save(context),
            tooltip: LocaleKeys.skill_credentials_definitions_save.tr(
              context: context,
            ),
          ),
        ],
        leading: AuraIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _initializeForm(SkillCredentialDefinitionEntity? definition) {
    if (_initialized) return;
    if (definition != null) {
      _titleController.text = definition.title;
      _attributeRows.addAll(
        SkillCredentialAttributeDefinition.parseMap(
          definition.attributesJson,
        ).entries.map(
          (entry) => _AttributeFormRow(
            variable: entry.key,
            description: entry.value.description,
            optional: entry.value.optional,
            secret: entry.value.secret,
          ),
        ),
      );
    }
    if (_attributeRows.isEmpty) {
      _attributeRows.add(_AttributeFormRow());
    }
    _initialized = true;
  }

  Future<void> _save(BuildContext context) async {
    setState(() => _isSaving = true);
    try {
      final attributesJson = _buildAttributesJson();
      if (_isCreate) {
        final usecase = ref.read(
          createSkillCredentialDefinitionUsecaseProvider,
        );
        final _ = await usecase.call(
          widget.workspaceId,
          SkillCredentialDefinitionToCreate(
            title: _titleController.text,
            attributesJson: attributesJson,
          ),
        );
      } else {
        final definitionId = widget.definitionId;
        if (definitionId == null) return;
        final usecase = ref.read(
          updateSkillCredentialDefinitionUsecaseProvider,
        );
        final _ = await usecase.call(
          definitionId,
          SkillCredentialDefinitionToUpdate(
            title: _titleController.text,
            attributesJson: attributesJson,
          ),
        );
        ref.invalidate(skillCredentialDefinitionProvider(definitionId));
      }
      ref.invalidate(skillCredentialDefinitionsProvider(widget.workspaceId));
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } on Object {
      if (!context.mounted) return;
      final _ = showAuraSnackBar(
        context: context,
        content: Text(
          LocaleKeys.skill_credentials_definitions_save_error.tr(
            context: context,
          ),
        ),
        variant: AuraSnackBarVariant.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addAttributeRow() {
    setState(() => _attributeRows.add(_AttributeFormRow()));
  }

  void _deleteAttributeRow(_AttributeFormRow row) {
    setState(() {
      final removed = _attributeRows.remove(row);
      if (removed) row.dispose();
      if (_attributeRows.isEmpty) _attributeRows.add(_AttributeFormRow());
    });
  }

  String _buildAttributesJson() {
    final attributes = <String, Map<String, Object>>{};
    for (final row in _attributeRows) {
      final variable = row.variableController.text.trim();
      if (variable.isEmpty) {
        throw const FormatException('Attribute variable is required.');
      }
      if (attributes.containsKey(variable)) {
        throw FormatException('Duplicate attribute variable: $variable');
      }
      attributes[variable] = {
        'description': row.descriptionController.text.trim(),
        if (row.optional) 'optional': true,
        if (!row.secret) 'secret': false,
      };
    }

    return jsonEncode(attributes);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AuraConfirmDialog(
        title: const TextLocale(
          LocaleKeys.skill_credentials_definitions_delete_title,
        ),
        message: const TextLocale(
          LocaleKeys.skill_credentials_definitions_delete_confirm,
        ),
        confirmLabel: Text(LocaleKeys.common_delete.tr(context: context)),
        cancelLabel: Text(LocaleKeys.common_cancel.tr(context: context)),
        isDestructive: true,
      ),
    );
    if (shouldDelete != true) return;
    if (!mounted) return;

    final definitionId = widget.definitionId;
    if (definitionId == null) return;

    setState(() => _isSaving = true);
    try {
      final usecase = ref.read(
        deleteSkillCredentialDefinitionUsecaseProvider,
      );
      final _ = await usecase.call(definitionId);
      ref.invalidate(skillCredentialDefinitionsProvider(widget.workspaceId));
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } on Object {
      if (!context.mounted) return;
      final _ = showAuraSnackBar(
        context: context,
        content: Text(
          LocaleKeys.skill_credentials_definitions_save_error.tr(
            context: context,
          ),
        ),
        variant: AuraSnackBarVariant.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _SkillCredentialDefinitionForm extends StatelessWidget {
  const _SkillCredentialDefinitionForm({
    required this.definition,
    required this.titleController,
    required this.attributeRows,
    required this.isSaving,
    required this.onAddAttributeRow,
    required this.onDeleteAttributeRow,
    required this.onSave,
    required this.onChanged,
  });

  final SkillCredentialDefinitionEntity? definition;
  final TextEditingController titleController;
  final List<_AttributeFormRow> attributeRows;
  final bool isSaving;
  final VoidCallback onAddAttributeRow;
  final ValueChanged<_AttributeFormRow> onDeleteAttributeRow;
  final VoidCallback onSave;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final definition = this.definition;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AuraCard(
          child: AuraColumn(
            children: [
              const AuraText(
                child: TextLocale(
                  LocaleKeys.skill_credentials_definitions_hint,
                ),
                color: AuraColorVariant.onSurfaceVariant,
              ),
              if (definition != null) AuraSelectableText(definition.slug),
              AuraInput(
                controller: titleController,
                label: Text(
                  LocaleKeys.skills_screen_title_label.tr(context: context),
                ),
              ),
              AuraColumn(
                children: [
                  const AuraText(
                    child: TextLocale(
                      LocaleKeys.skill_credentials_definitions_attributes_label,
                    ),
                    color: AuraColorVariant.onSurface,
                  ),
                  for (final row in attributeRows)
                    _AttributeRowEditor(
                      row: row,
                      canDelete: attributeRows.length > 1,
                      onChanged: onChanged,
                      onDelete: () => onDeleteAttributeRow(row),
                      key: ValueKey(row),
                    ),
                  AuraButton(
                    onPressed: onAddAttributeRow,
                    child: const TextLocale(
                      LocaleKeys.skill_credentials_definitions_add_attribute,
                    ),
                  ),
                ],
                spacing: AuraSpacing.sm,
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AuraButton(
                  onPressed: onSave,
                  child: const TextLocale(
                    LocaleKeys.skill_credentials_definitions_save,
                  ),
                  disabled: isSaving,
                ),
              ),
            ],
            spacing: AuraSpacing.md,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ),
      ],
    );
  }
}

class _AttributeFormRow {
  _AttributeFormRow({
    String variable = '',
    String description = '',
    this.optional = false,
    this.secret = true,
  }) : variableController = TextEditingController(text: variable),
       descriptionController = TextEditingController(text: description);

  final TextEditingController variableController;
  final TextEditingController descriptionController;
  bool optional;
  bool secret;

  void dispose() {
    variableController.dispose();
    descriptionController.dispose();
  }
}

class _AttributeRowEditor extends StatelessWidget {
  const _AttributeRowEditor({
    required this.row,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
    super.key,
  });

  final _AttributeFormRow row;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final variableLabel = LocaleKeys
        .skill_credentials_definitions_attribute_variable_label
        .tr(context: context);
    final descriptionLabel = LocaleKeys
        .skill_credentials_definitions_attribute_description_label
        .tr(context: context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AuraColumn(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AuraInput(
                    controller: row.variableController,
                    label: Text(variableLabel),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                AuraIconButton(
                  icon: Icons.delete_outline,
                  onPressed: canDelete ? onDelete : null,
                  tooltip: LocaleKeys
                      .skill_credentials_definitions_delete_attribute
                      .tr(context: context),
                ),
              ],
            ),
            AuraInput(
              controller: row.descriptionController,
              label: Text(descriptionLabel),
              onChanged: (_) => onChanged(),
            ),
            AuraRow(
              children: [
                AuraSwitch(
                  value: row.optional,
                  onChanged: (value) {
                    row.optional = value;
                    onChanged();
                  },
                ),
                const Expanded(
                  child: AuraText(
                    child: TextLocale(
                      LocaleKeys
                          .skill_credentials_definitions_attribute_optional,
                    ),
                  ),
                ),
              ],
              spacing: AuraSpacing.md,
            ),
            AuraRow(
              children: [
                AuraSwitch(
                  value: row.secret,
                  onChanged: (value) {
                    row.secret = value;
                    onChanged();
                  },
                ),
                const Expanded(
                  child: AuraText(
                    child: TextLocale(
                      LocaleKeys.skill_credentials_definitions_attribute_secret,
                    ),
                  ),
                ),
              ],
              spacing: AuraSpacing.md,
            ),
          ],
          spacing: AuraSpacing.sm,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      ),
    );
  }
}
