// Required: Existing UI spacing uses small numeric values.
import 'dart:convert';

import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/delete_cloud_routed_skill_usecases.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_credential_definition_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show SkillCredentialAttributeDefinition;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class const SkillCredentialDefinitionEditScreen({
  required final String workspaceId,
  final String? definitionId,
  super.key,
}) extends ConsumerStatefulWidget {
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
    final definitionAsync = _watchCredentialDefinition(
      ref,
      widget.workspaceId,
      definitionId,
    );
    final currentDefinition = definitionAsync?.value;

    return AuraScreen(
      child: _SkillCredentialDefinitionBody(
        state: this,
        definitionAsync: definitionAsync,
        currentDefinition: currentDefinition,
      ),
      appBar: _SkillCredentialDefinitionAppBar(state: this),
    );
  }
}

extension on _SkillCredentialDefinitionEditScreenState {
  void _initializeForm(SkillCredentialDefinitionEntity? definition) {
    if (_initialized) return;
    if (definition != null) {
      _titleController.text = definition.title;
      _attributeRows.addAll(_parseAttributeRows(definition.attributesJson));
    }
    if (_attributeRows.isEmpty) {
      _attributeRows.add(_AttributeFormRow());
    }
    _initialized = true;
  }

  List<_AttributeFormRow> _parseAttributeRows(String attributesJson) {
    final attributes = SkillCredentialAttributeDefinition.parseMap(
      attributesJson,
    );

    return [
      for (final entry in attributes.entries)
        _AttributeFormRow(
          variable: entry.key,
          description: entry.value.description,
          optional: entry.value.optional,
          secret: entry.value.secret,
        ),
    ];
  }

  Future<void> _save(BuildContext context) async {
    setState(() => _isSaving = true);
    try {
      await _saveDefinition();
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } on Object {
      if (!context.mounted) return;
      _showSaveError(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveDefinition() async {
    final attributesJson = _buildAttributesJson();
    if (_isCreate) {
      await _createDefinition(attributesJson);
    } else {
      await _updateDefinition(attributesJson);
    }
    ref.invalidate(skillCredentialDefinitionsProvider(widget.workspaceId));
  }

  Future<void> _createDefinition(String attributesJson) async {
    final usecase = ref.read(
      createSkillCredentialDefinitionUsecaseProvider(widget.workspaceId),
    );
    final _ = await usecase.call(
      widget.workspaceId,
      .new(title: _titleController.text, attributesJson: attributesJson),
    );
  }

  Future<void> _updateDefinition(String attributesJson) async {
    final definitionId = widget.definitionId;
    if (definitionId == null) return;
    final usecase = ref.read(
      updateSkillCredentialDefinitionUsecaseProvider(widget.workspaceId),
    );
    final _ = await usecase.call(
      definitionId,
      _definitionUpdate(attributesJson),
    );
    ref.invalidate(
      skillCredentialDefinitionProvider(widget.workspaceId, definitionId),
    );
  }

  SkillCredentialDefinitionToUpdate _definitionUpdate(String attributesJson) =>
      .new(title: _titleController.text, attributesJson: attributesJson);
}

extension on _SkillCredentialDefinitionEditScreenState {
  void _addAttributeRow() {
    setState(() => _attributeRows.add(_AttributeFormRow()));
  }

  void _onFormChanged() {
    setState(() {
      final _ = Object();
    });
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
      attributes[variable] = _attributeValues(row, variable, attributes);
    }

    return jsonEncode(attributes);
  }

  Map<String, Object> _attributeValues(
    _AttributeFormRow row,
    String variable,
    Map<String, Map<String, Object>> attributes,
  ) {
    if (variable.isEmpty) {
      throw const FormatException('Attribute variable is required.');
    }
    if (attributes.containsKey(variable)) {
      throw FormatException('Duplicate attribute variable: $variable');
    }

    return {
      'description': row.descriptionController.text.trim(),
      if (row.optional) 'optional': true,
      if (!row.secret) 'secret': false,
    };
  }
}

extension on _SkillCredentialDefinitionEditScreenState {
  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await _showDeleteConfirmation(context);
    final definitionId = widget.definitionId;
    if (shouldDelete != true || !context.mounted || definitionId == null) {
      return;
    }

    await _performDelete(context, definitionId);
  }

  Future<void> _performDelete(BuildContext context, String definitionId) async {
    setState(() => _isSaving = true);
    try {
      await _deleteDefinitionAndClose(context, definitionId);
    } on Object {
      if (!context.mounted) return;
      _showSaveError(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => _CredentialDefinitionDeleteDialog(),
    );
  }

  Future<void> _deleteDefinition(String definitionId) async {
    await ref.read(deleteSkillCredentialDefinitionProvider(widget.workspaceId))(
      definitionId,
    );
    ref.invalidate(skillCredentialDefinitionsProvider(widget.workspaceId));
  }

  Future<void> _deleteDefinitionAndClose(
    BuildContext context,
    String definitionId,
  ) async {
    await _deleteDefinition(definitionId);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  void _showSaveError(BuildContext context) {
    if (!context.mounted) return;
    final _ = AuraSnackBars.show(
      context: context,
      content: Text(
        LocaleKeys.skill_credentials_definitions_save_error.tr(
          context: context,
        ),
      ),
      variant: .error,
    );
  }
}

AsyncValue<SkillCredentialDefinitionEntity?>? _watchCredentialDefinition(
  WidgetRef ref,
  String workspaceId,
  String? definitionId,
) => definitionId == null
    ? null
    : ref.watch(skillCredentialDefinitionProvider(workspaceId, definitionId));

class const _SkillCredentialDefinitionBody({
  required final _SkillCredentialDefinitionEditScreenState state,
  required final AsyncValue<SkillCredentialDefinitionEntity?>? definitionAsync,
  required final SkillCredentialDefinitionEntity? currentDefinition,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = this.state;
    final definitionAsync = this.definitionAsync;
    if (definitionAsync == null) {
      state._initializeForm(null);

      return _SkillCredentialDefinitionForm(state: state, definition: null);
    }

    return _CredentialDefinitionAsyncBody(
      state: state,
      definitionAsync: definitionAsync,
      currentDefinition: currentDefinition,
    );
  }
}

class const _CredentialDefinitionAsyncBody({
  required final _SkillCredentialDefinitionEditScreenState state,
  required final AsyncValue<SkillCredentialDefinitionEntity?> definitionAsync,
  required final SkillCredentialDefinitionEntity? currentDefinition,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = this.state;
    final definitionAsync = this.definitionAsync;

    return switch (definitionAsync) {
      AsyncData(:final value) =>
        value == null
            ? _CredentialDefinitionNotFound()
            : _CredentialDefinitionReadyForm(state: state, definition: value),
      AsyncLoading() =>
        currentDefinition == null
            ? _CredentialDefinitionLoading()
            : _CredentialDefinitionReadyForm(
                state: state,
                definition: currentDefinition,
              ),
      AsyncError() => _CredentialDefinitionError(),
    };
  }
}

class const _CredentialDefinitionReadyForm({
  required final _SkillCredentialDefinitionEditScreenState state,
  required final SkillCredentialDefinitionEntity? definition,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final definition = this.definition;

    if (definition == null) return _CredentialDefinitionLoading();

    state._initializeForm(definition);

    return _SkillCredentialDefinitionForm(state: state, definition: definition);
  }
}

class _CredentialDefinitionNotFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: TextLocale(LocaleKeys.skill_credentials_definitions_not_found),
    );
  }
}

class _CredentialDefinitionLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: AuraSpinner());
  }
}

class _CredentialDefinitionError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: TextLocale(LocaleKeys.skill_credentials_definitions_error),
    );
  }
}

class const _SkillCredentialDefinitionAppBar({
  required final _SkillCredentialDefinitionEditScreenState state,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final state = this.state;

    return AuraAppBar(
      title: TextLocale(
        state._isCreate
            ? LocaleKeys.skill_credentials_definitions_create_title
            : LocaleKeys.skill_credentials_definitions_edit_title,
      ),
      actions: [
        if (!state._isCreate) _CredentialDefinitionDeleteButton(state: state),
        _CredentialDefinitionAppBarSaveButton(state: state),
      ],
      leading: _CredentialDefinitionBackButton(),
    );
  }
}

class const _CredentialDefinitionDeleteButton({
  required final _SkillCredentialDefinitionEditScreenState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.delete_outline,
      onPressed: state._isSaving ? null : () => state._confirmDelete(context),
      tooltip: LocaleKeys.skill_credentials_definitions_delete_title.tr(
        context: context,
      ),
    );
  }
}

class const _CredentialDefinitionAppBarSaveButton({
  required final _SkillCredentialDefinitionEditScreenState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.save_outlined,
      onPressed: state._isSaving ? null : () => state._save(context),
      tooltip: LocaleKeys.skill_credentials_definitions_save.tr(
        context: context,
      ),
    );
  }
}

class _CredentialDefinitionBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.arrow_back,
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

class _CredentialDefinitionDeleteDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraConfirmDialog(
      title: const TextLocale(
        LocaleKeys.skill_credentials_definitions_delete_title,
      ),
      message: const TextLocale(
        LocaleKeys.skill_credentials_definitions_delete_confirm,
      ),
      confirmLabel: Text(LocaleKeys.common_delete.tr(context: context)),
      cancelLabel: Text(LocaleKeys.common_cancel.tr(context: context)),
      isDestructive: true,
    );
  }
}

class const _SkillCredentialDefinitionForm({
  required final _SkillCredentialDefinitionEditScreenState state,
  required final SkillCredentialDefinitionEntity? definition,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _CredentialDefinitionFormCard(state: state, definition: definition),
      ],
    );
  }
}

class const _CredentialDefinitionFormCard({
  required final _SkillCredentialDefinitionEditScreenState state,
  required final SkillCredentialDefinitionEntity? definition,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final definition = this.definition;

    return AuraCard(
      child: AuraColumn(
        children: [
          _CredentialDefinitionFormHeader(state: state, definition: definition),
          _CredentialDefinitionAttributes(state: state),
          _CredentialDefinitionSaveButton(state: state),
        ],
        spacing: .md,
        crossAxisAlignment: .start,
      ),
    );
  }
}

class const _CredentialDefinitionFormHeader({
  required final _SkillCredentialDefinitionEditScreenState state,
  required final SkillCredentialDefinitionEntity? definition,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _CredentialDefinitionHint(),
        if (definition case final definition?)
          AuraSelectableText(definition.slug),
        _CredentialDefinitionTitleField(controller: state._titleController),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }
}

class _CredentialDefinitionHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AuraText(
      child: TextLocale(LocaleKeys.skill_credentials_definitions_hint),
    );
  }
}

class const _CredentialDefinitionTitleField({
  required final TextEditingController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: controller,
      label: Text(LocaleKeys.skills_screen_title_label.tr(context: context)),
    );
  }
}

class const _CredentialDefinitionAttributes({
  required final _SkillCredentialDefinitionEditScreenState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _CredentialDefinitionAttributesLabel(),
        _CredentialDefinitionAttributeRows(state: state),
        _CredentialDefinitionAddAttributeButton(
          onPressed: state._addAttributeRow,
        ),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }
}

class _CredentialDefinitionAttributesLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AuraText(
      child: TextLocale(
        LocaleKeys.skill_credentials_definitions_attributes_label,
      ),
    );
  }
}

class const _CredentialDefinitionAttributeRows({
  required final _SkillCredentialDefinitionEditScreenState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        for (final row in state._attributeRows)
          _CredentialDefinitionAttributeRow(state: state, row: row),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }
}

class const _CredentialDefinitionAttributeRow({
  required final _SkillCredentialDefinitionEditScreenState state,
  required final _AttributeFormRow row,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AttributeRowEditor(
    row: row,
    canDelete: state._attributeRows.length > 1,
    onChanged: state._onFormChanged,
    onDelete: () => state._deleteAttributeRow(row),
    key: ValueKey(row),
  );
}

class const _CredentialDefinitionAddAttributeButton({
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraButton(
      onPressed: onPressed,
      child: const TextLocale(
        LocaleKeys.skill_credentials_definitions_add_attribute,
      ),
    );
  }
}

class const _CredentialDefinitionSaveButton({
  required final _SkillCredentialDefinitionEditScreenState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: AuraButton(
        onPressed: () => state._save(context),
        child: const TextLocale(LocaleKeys.skill_credentials_definitions_save),
        disabled: state._isSaving,
      ),
    );
  }
}

class _AttributeFormRow({
  String variable = '',
  String description = '',
  var bool optional = false,
  var bool secret = true,
}) {
  final TextEditingController variableController = .new(text: variable);
  final TextEditingController descriptionController = .new(text: description);
  void dispose() {
    variableController.dispose();
    descriptionController.dispose();
  }
}

class const _AttributeRowEditor({
  required final _AttributeFormRow row,
  required final bool canDelete,
  required final VoidCallback onChanged,
  required final VoidCallback onDelete,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _AttributeRowCard(
      row: row,
      canDelete: canDelete,
      onChanged: onChanged,
      onDelete: onDelete,
    );
  }
}

class const _AttributeRowCard({
  required final _AttributeFormRow row,
  required final bool canDelete,
  required final VoidCallback onChanged,
  required final VoidCallback onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _attributeRowDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _AttributeRowContent(
          row: row,
          canDelete: canDelete,
          onChanged: onChanged,
          onDelete: onDelete,
        ),
      ),
    );
  }
}

BoxDecoration _attributeRowDecoration(BuildContext context) => BoxDecoration(
  border: Border.all(color: Theme.of(context).dividerColor),
  borderRadius: const BorderRadius.all(.circular(8)),
);

class const _AttributeRowContent({
  required final _AttributeFormRow row,
  required final bool canDelete,
  required final VoidCallback onChanged,
  required final VoidCallback onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _AttributeRowFields(
          row: row,
          canDelete: canDelete,
          onChanged: onChanged,
          onDelete: onDelete,
        ),
        _AttributeOptionalToggle(row: row, onChanged: onChanged),
        _AttributeSecretToggle(row: row, onChanged: onChanged),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }
}

class const _AttributeOptionalToggle({
  required final _AttributeFormRow row,
  required final VoidCallback onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _AttributeRowToggle(
      value: row.optional,
      labelKey: LocaleKeys.skill_credentials_definitions_attribute_optional,
      onChanged: (value) {
        row.optional = value;
        onChanged();
      },
    );
  }
}

class const _AttributeSecretToggle({
  required final _AttributeFormRow row,
  required final VoidCallback onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _AttributeRowToggle(
      value: row.secret,
      labelKey: LocaleKeys.skill_credentials_definitions_attribute_secret,
      onChanged: (value) {
        row.secret = value;
        onChanged();
      },
    );
  }
}

class const _AttributeRowFields({
  required final _AttributeFormRow row,
  required final bool canDelete,
  required final VoidCallback onChanged,
  required final VoidCallback onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        Row(
          crossAxisAlignment: .start,
          children: [
            Expanded(
              child: _AttributeVariableField(
                controller: row.variableController,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            _AttributeDeleteButton(canDelete: canDelete, onPressed: onDelete),
          ],
        ),
        _AttributeDescriptionField(
          controller: row.descriptionController,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class const _AttributeVariableField({
  required final TextEditingController controller,
  required final VoidCallback onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = LocaleKeys
        .skill_credentials_definitions_attribute_variable_label
        .tr(context: context);

    return AuraInput(
      controller: controller,
      label: Text(label),
      onChanged: (_) => onChanged(),
    );
  }
}

class const _AttributeDeleteButton({
  required final bool canDelete,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.delete_outline,
      onPressed: canDelete ? onPressed : null,
      tooltip: LocaleKeys.skill_credentials_definitions_delete_attribute.tr(
        context: context,
      ),
    );
  }
}

class const _AttributeDescriptionField({
  required final TextEditingController controller,
  required final VoidCallback onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = LocaleKeys
        .skill_credentials_definitions_attribute_description_label
        .tr(context: context);

    return AuraInput(
      controller: controller,
      label: Text(label),
      onChanged: (_) => onChanged(),
    );
  }
}

class const _AttributeRowToggle({
  required final bool value,
  required final String labelKey,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraRow(
      children: [
        AuraSwitch(value: value, onChanged: onChanged),
        Expanded(child: AuraText(child: TextLocale(labelKey))),
      ],
      spacing: .md,
    );
  }
}
