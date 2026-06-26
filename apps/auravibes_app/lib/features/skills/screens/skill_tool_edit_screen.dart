// Required: Existing UI spacing uses small numeric values.
// Required: Private form row widgets keep this screen self-contained.
import 'dart:convert';

import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/markdown/show_markdown_editor.dart';
import 'package:auravibes_app/features/markdown/widgets/empty_markdown_preview.dart';
import 'package:auravibes_app/features/skills/models/skill_url_template.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_template_tool_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/url/models/url_request_method.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:textf/textf.dart';

const _skillToolDescriptionMaxCharacters = 1024;

class SkillToolEditScreen extends ConsumerStatefulWidget {
  const SkillToolEditScreen({
    required this.workspaceId,
    required this.skillId,
    this.toolId,
    super.key,
  });

  final String workspaceId;
  final String skillId;
  final String? toolId;

  @override
  ConsumerState<SkillToolEditScreen> createState() =>
      _SkillToolEditScreenState();
}

class _SkillToolEditScreenState extends ConsumerState<SkillToolEditScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextfEditingController();
  final _urlController = TextEditingController();
  final _bodyController = TextEditingController();
  final _queryFields = <_KeyValueField>[];
  final _inputFields = <_InputField>[];
  UrlRequestMethod _method = UrlRequestMethod.get;
  SkillUrlTemplateBodyFormat _bodyFormat = SkillUrlTemplateBodyFormat.json;
  bool _requiresCredential = false;
  bool _isEnabled = true;
  bool _initialized = false;
  bool _isSaving = false;

  bool get _isCreate => widget.toolId == null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _bodyController.dispose();
    for (final field in _queryFields) {
      field.dispose();
    }
    for (final field in _inputFields) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolId = widget.toolId;
    final toolAsync = toolId == null
        ? null
        : ref.watch(skillTemplateToolProvider(toolId));
    final currentTool = toolAsync?.value;
    final skillDetailAsync = ref.watch(
      skillDetailProvider(widget.workspaceId, widget.skillId),
    );
    final skillHasCredentialDefinition =
        skillDetailAsync.value?.credentialDefinitionId != null;

    final Widget child;
    if (toolAsync == null) {
      _initializeCreateForm();
      child = _SkillToolForm(
        tool: null,
        titleController: _titleController,
        descriptionController: _descriptionController,
        urlController: _urlController,
        bodyController: _bodyController,
        queryFields: _queryFields,
        inputFields: _inputFields,
        method: _method,
        bodyFormat: _bodyFormat,
        requiresCredential: _requiresCredential,
        isEnabled: _isEnabled,
        isSaving: _isSaving,
        skillHasCredentialDefinition: skillHasCredentialDefinition,
        onEditDescription: () => _editDescription(context),
        onMethodChanged: (value) => setState(() => _method = value),
        onAddQueryField: () =>
            setState(() => _queryFields.add(_KeyValueField())),
        onRemoveQueryField: _removeQueryField,
        onBodyFormatChanged: (value) => setState(() => _bodyFormat = value),
        onAddInputField: () => setState(() => _inputFields.add(_InputField())),
        onRemoveInputField: _removeInputField,
        onInputChanged: () => setState(() {
          final _ = Object();
        }),
        onRequiresCredentialChanged: (value) =>
            setState(() => _requiresCredential = value),
        onEnabledChanged: (value) => setState(() => _isEnabled = value),
        onSave: () => _save(context),
      );
    } else {
      child = switch (toolAsync) {
        AsyncData(value: null) => const Center(
          child: TextLocale(LocaleKeys.skills_tool_not_found),
        ),
        AsyncData(value: final tool?) => () {
          _initializeFromTool(tool);

          return _SkillToolForm(
            tool: tool,
            titleController: _titleController,
            descriptionController: _descriptionController,
            urlController: _urlController,
            bodyController: _bodyController,
            queryFields: _queryFields,
            inputFields: _inputFields,
            method: _method,
            bodyFormat: _bodyFormat,
            requiresCredential: _requiresCredential,
            isEnabled: _isEnabled,
            isSaving: _isSaving,
            skillHasCredentialDefinition: skillHasCredentialDefinition,
            onEditDescription: () => _editDescription(context),
            onMethodChanged: (value) => setState(() => _method = value),
            onAddQueryField: () =>
                setState(() => _queryFields.add(_KeyValueField())),
            onRemoveQueryField: _removeQueryField,
            onBodyFormatChanged: (value) => setState(() => _bodyFormat = value),
            onAddInputField: () =>
                setState(() => _inputFields.add(_InputField())),
            onRemoveInputField: _removeInputField,
            onInputChanged: () => setState(() {
              final _ = Object();
            }),
            onRequiresCredentialChanged: (value) =>
                setState(() => _requiresCredential = value),
            onEnabledChanged: (value) => setState(() => _isEnabled = value),
            onSave: () => _save(context),
          );
        }(),
        AsyncLoading() when currentTool != null => () {
          _initializeFromTool(currentTool);

          return _SkillToolForm(
            tool: currentTool,
            titleController: _titleController,
            descriptionController: _descriptionController,
            urlController: _urlController,
            bodyController: _bodyController,
            queryFields: _queryFields,
            inputFields: _inputFields,
            method: _method,
            bodyFormat: _bodyFormat,
            requiresCredential: _requiresCredential,
            isEnabled: _isEnabled,
            isSaving: _isSaving,
            skillHasCredentialDefinition: skillHasCredentialDefinition,
            onEditDescription: () => _editDescription(context),
            onMethodChanged: (value) => setState(() => _method = value),
            onAddQueryField: () =>
                setState(() => _queryFields.add(_KeyValueField())),
            onRemoveQueryField: _removeQueryField,
            onBodyFormatChanged: (value) => setState(() => _bodyFormat = value),
            onAddInputField: () =>
                setState(() => _inputFields.add(_InputField())),
            onRemoveInputField: _removeInputField,
            onInputChanged: () => setState(() {
              final _ = Object();
            }),
            onRequiresCredentialChanged: (value) =>
                setState(() => _requiresCredential = value),
            onEnabledChanged: (value) => setState(() => _isEnabled = value),
            onSave: () => _save(context),
          );
        }(),
        AsyncLoading() => const Center(
          child: AuraSpinner(),
        ),
        AsyncError() => const Center(
          child: TextLocale(LocaleKeys.skills_tool_load_error),
        ),
      };
    }

    return AuraScreen(
      child: child,
      appBar: AuraAppBar(
        title: TextLocale(
          _isCreate
              ? LocaleKeys.skills_tool_create_title
              : LocaleKeys.skills_tool_edit_title,
        ),
        actions: [
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

  void _initializeCreateForm() {
    if (!_initialized) {
      _inputFields.add(_InputField());
      _initialized = true;
    }
  }

  Future<void> _editDescription(BuildContext context) async {
    final result = await showMarkdownEditor(
      context,
      initialMarkdown: _descriptionController.text,
      maxCharacters: _skillToolDescriptionMaxCharacters,
    );
    if (result == null || !mounted) return;

    setState(() => _descriptionController.text = result);
  }

  void _removeQueryField(_KeyValueField field) {
    setState(() {
      final _ = _queryFields.remove(field);
      field.dispose();
    });
  }

  void _removeInputField(_InputField field) {
    setState(() {
      final _ = _inputFields.remove(field);
      field.dispose();
    });
  }

  void _initializeFromTool(SkillTemplateToolEntity tool) {
    if (_initialized) return;

    _titleController.text = tool.title;
    _descriptionController.text = tool.description;
    _requiresCredential = tool.requiresCredential;
    _isEnabled = tool.isEnabled;
    try {
      final template = SkillUrlTemplate.fromJsonString(tool.templateJson);
      _urlController.text = template.url;
      _method = template.method;
      _bodyFormat = template.resolvedBodyFormat;
      _bodyController.text = template.body ?? '';
      _queryFields
        ..clear()
        ..addAll(
          template.query.entries.map(
            (entry) => _KeyValueField(key: entry.key, value: entry.value),
          ),
        );
    } on Object {
      _urlController.clear();
      _bodyController.text = tool.templateJson;
    }

    try {
      final inputs = SkillTemplateInputDefinition.parseMap(tool.inputsJson);
      _inputFields
        ..clear()
        ..addAll(
          inputs.entries.map(
            (entry) => _InputField(
              name: entry.key,
              type: entry.value.type,
              description: entry.value.description,
              optional: entry.value.optional,
            ),
          ),
        );
    } on Object {
      _inputFields.clear();
    }
    if (_inputFields.isEmpty) _inputFields.add(_InputField());
    _initialized = true;
  }

  Future<void> _save(BuildContext context) async {
    setState(() => _isSaving = true);
    try {
      final templateJson = _buildTemplateJson();
      final inputsJson = _buildInputsJson();
      final requiresCredential =
          ref
                  .read(
                    skillDetailProvider(widget.workspaceId, widget.skillId),
                  )
                  .value
                  ?.credentialDefinitionId !=
              null &&
          _requiresCredential;
      if (_isCreate) {
        final usecase = ref.read(createSkillTemplateToolUsecaseProvider);
        final _ = await usecase.call(
          widget.skillId,
          SkillTemplateToolToCreate(
            templateType: SkillTemplateToolType.url,
            title: _titleController.text,
            description: _descriptionController.text,
            templateJson: templateJson,
            inputsJson: inputsJson,
            requiresCredential: requiresCredential,
            isEnabled: _isEnabled,
          ),
        );
      } else {
        final toolId = widget.toolId;
        if (toolId == null) return;
        final usecase = ref.read(updateSkillTemplateToolUsecaseProvider);
        final _ = await usecase.call(
          toolId,
          SkillTemplateToolToUpdate(
            title: _titleController.text,
            description: _descriptionController.text,
            templateJson: templateJson,
            inputsJson: inputsJson,
            requiresCredential: requiresCredential,
            isEnabled: _isEnabled,
          ),
        );
      }
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } on Object {
      if (!context.mounted) return;
      final _ = showAuraSnackBar(
        context: context,
        content: Text(LocaleKeys.skills_tool_save_error.tr(context: context)),
        variant: AuraSnackBarVariant.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _buildTemplateJson() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      throw const FormatException('URL is required.');
    }
    if (_descriptionController.text.trim().isEmpty) {
      throw const FormatException('Description is required.');
    }
    final query = <String, String>{};
    for (final field in _queryFields) {
      final key = field.keyController.text.trim();
      final value = field.valueController.text.trim();
      if (key.isEmpty && value.isEmpty) continue;
      if (key.isEmpty || value.isEmpty) {
        throw const FormatException('Query fields require key and value.');
      }
      query[key] = value;
    }
    final template = <String, Object>{
      'url': url,
      'method': _method.value,
      if (query.isNotEmpty) 'query': query,
      if (_bodyController.text.trim().isNotEmpty)
        'body': _bodyController.text.trim(),
      if (_bodyController.text.trim().isNotEmpty)
        'bodyFormat': _bodyFormat.value,
    };

    return jsonEncode(template);
  }

  String _buildInputsJson() {
    final inputs = <String, Map<String, Object>>{};
    for (final field in _inputFields) {
      final name = field.nameController.text.trim();
      final description = field.descriptionController.text.trim();
      if (name.isEmpty && description.isEmpty) continue;
      if (name.isEmpty || description.isEmpty) {
        throw const FormatException(
          'Input fields require name and description.',
        );
      }
      inputs[name] = {
        'type': field.type,
        'description': description,
        if (field.optional) 'optional': true,
      };
    }

    return jsonEncode(inputs);
  }
}

class _SkillToolForm extends StatelessWidget {
  const _SkillToolForm({
    required this.tool,
    required this.titleController,
    required this.descriptionController,
    required this.urlController,
    required this.bodyController,
    required this.queryFields,
    required this.inputFields,
    required this.method,
    required this.bodyFormat,
    required this.requiresCredential,
    required this.isEnabled,
    required this.isSaving,
    required this.skillHasCredentialDefinition,
    required this.onEditDescription,
    required this.onMethodChanged,
    required this.onAddQueryField,
    required this.onRemoveQueryField,
    required this.onBodyFormatChanged,
    required this.onAddInputField,
    required this.onRemoveInputField,
    required this.onInputChanged,
    required this.onRequiresCredentialChanged,
    required this.onEnabledChanged,
    required this.onSave,
  });

  final SkillTemplateToolEntity? tool;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController urlController;
  final TextEditingController bodyController;
  final List<_KeyValueField> queryFields;
  final List<_InputField> inputFields;
  final UrlRequestMethod method;
  final SkillUrlTemplateBodyFormat bodyFormat;
  final bool requiresCredential;
  final bool isEnabled;
  final bool isSaving;
  final bool skillHasCredentialDefinition;
  final VoidCallback onEditDescription;
  final ValueChanged<UrlRequestMethod> onMethodChanged;
  final VoidCallback onAddQueryField;
  final ValueChanged<_KeyValueField> onRemoveQueryField;
  final ValueChanged<SkillUrlTemplateBodyFormat> onBodyFormatChanged;
  final VoidCallback onAddInputField;
  final ValueChanged<_InputField> onRemoveInputField;
  final VoidCallback onInputChanged;
  final ValueChanged<bool> onRequiresCredentialChanged;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final tool = this.tool;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AuraCard(
          child: AuraColumn(
            children: [
              if (tool != null)
                _ReadOnlyField(
                  labelKey: LocaleKeys.skills_screen_slug_label,
                  value: tool.slug,
                ),
              AuraInput(
                controller: titleController,
                label: Text(
                  LocaleKeys.skills_screen_title_label.tr(context: context),
                ),
              ),
              _MarkdownToolDescriptionField(
                controller: descriptionController,
                onEdit: onEditDescription,
              ),
              AuraInput(
                controller: urlController,
                placeholder: Text(
                  LocaleKeys.skills_tool_url_hint.tr(context: context),
                ),
                label: Text(
                  LocaleKeys.skills_tool_url_label.tr(context: context),
                ),
              ),
              AuraDropdownSelector<UrlRequestMethod>(
                options: [
                  for (final method in UrlRequestMethod.values)
                    AuraDropdownOption(
                      value: method,
                      child: Text(method.value),
                    ),
                ],
                value: method,
                onChanged: (value) {
                  if (value != null) onMethodChanged(value);
                },
                label: Text(
                  LocaleKeys.skills_tool_method_label.tr(context: context),
                ),
              ),
              _QueryFieldsSection(
                fields: queryFields,
                onAdd: onAddQueryField,
                onRemove: onRemoveQueryField,
              ),
              AuraDropdownSelector<SkillUrlTemplateBodyFormat>(
                options: [
                  AuraDropdownOption(
                    value: SkillUrlTemplateBodyFormat.json,
                    child: Text(
                      LocaleKeys.skills_tool_body_format_json.tr(
                        context: context,
                      ),
                    ),
                  ),
                  AuraDropdownOption(
                    value: SkillUrlTemplateBodyFormat.text,
                    child: Text(
                      LocaleKeys.skills_tool_body_format_text.tr(
                        context: context,
                      ),
                    ),
                  ),
                ],
                value: bodyFormat,
                onChanged: (value) {
                  if (value == null) return;
                  onBodyFormatChanged(value);
                },
                label: Text(
                  LocaleKeys.skills_tool_body_format_label.tr(context: context),
                ),
              ),
              AuraInput(
                controller: bodyController,
                placeholder: Text(
                  LocaleKeys.skills_tool_body_hint.tr(context: context),
                ),
                label: Text(
                  LocaleKeys.skills_tool_body_label.tr(context: context),
                ),
                minLines: 5,
                maxLines: 12,
              ),
              _InputFieldsSection(
                fields: inputFields,
                onAdd: onAddInputField,
                onRemove: onRemoveInputField,
                onChanged: onInputChanged,
              ),
              if (skillHasCredentialDefinition)
                AuraCheckboxListTile(
                  value: requiresCredential,
                  onChanged: onRequiresCredentialChanged,
                  title: const TextLocale(
                    LocaleKeys.skills_tool_requires_credential_label,
                  ),
                  subtitle: const TextLocale(
                    LocaleKeys.skills_tool_requires_credential_hint,
                  ),
                ),
              AuraRow(
                children: [
                  AuraSwitch(
                    value: isEnabled,
                    onChanged: onEnabledChanged,
                  ),
                  const Expanded(
                    child: AuraText(
                      child: TextLocale(
                        LocaleKeys.skills_screen_enabled_label,
                      ),
                    ),
                  ),
                ],
                spacing: AuraSpacing.md,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AuraButton(
                  onPressed: onSave,
                  child: const TextLocale(LocaleKeys.skills_screen_save),
                  disabled: isSaving,
                ),
              ),
            ],
            spacing: AuraSpacing.lg,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ),
      ],
    );
  }
}

class _MarkdownToolDescriptionField extends StatelessWidget {
  const _MarkdownToolDescriptionField({
    required this.controller,
    required this.onEdit,
  });

  final TextEditingController controller;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: AuraColumn(
        children: [
          AuraRow(
            children: [
              const Expanded(
                child: AuraText(
                  child: TextLocale(LocaleKeys.skills_tool_description_label),
                  style: AuraTextStyle.heading6,
                ),
              ),
              AuraButton(
                onPressed: onEdit,
                child: const TextLocale(
                  LocaleKeys.skills_screen_edit_description,
                ),
                variant: AuraButtonVariant.outlined,
                size: AuraButtonSize.small,
              ),
            ],
            spacing: .md,
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final text = value.text.trim();
              if (text.isEmpty) {
                return const EmptyMarkdownPreview(
                  label: LocaleKeys.skills_screen_description_empty,
                );
              }

              return GptMarkdown(text);
            },
          ),
        ],
        spacing: .sm,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      style: AuraCardStyle.border,
    );
  }
}

class _QueryFieldsSection extends StatelessWidget {
  const _QueryFieldsSection({
    required this.fields,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_KeyValueField> fields;
  final VoidCallback onAdd;
  final ValueChanged<_KeyValueField> onRemove;

  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.skills_tool_query_section_title),
          style: AuraTextStyle.heading4,
        ),
        const AuraText(
          child: TextLocale(LocaleKeys.skills_tool_query_hint),
        ),
        for (final field in fields)
          Row(
            children: [
              Expanded(
                child: AuraInput(
                  controller: field.keyController,
                  label: Text(
                    LocaleKeys.skills_tool_query_key_label.tr(
                      context: context,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AuraInput(
                  controller: field.valueController,
                  placeholder: const TextLocale(
                    LocaleKeys.skills_tool_query_value_placeholder,
                  ),
                  label: Text(
                    LocaleKeys.skills_tool_query_value_label.tr(
                      context: context,
                    ),
                  ),
                ),
              ),
              AuraIconButton(
                icon: Icons.remove_circle_outline,
                onPressed: () => onRemove(field),
                tooltip: LocaleKeys.common_remove.tr(context: context),
              ),
            ],
          ),
        AuraButton(
          onPressed: onAdd,
          child: AuraRow(
            children: [
              const AuraIcon(Icons.add),
              Text(LocaleKeys.skills_tool_add_query.tr(context: context)),
            ],
            spacing: AuraSpacing.xs,
            mainAxisSize: MainAxisSize.min,
          ),
          variant: AuraButtonVariant.text,
        ),
      ],
      spacing: AuraSpacing.sm,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}

class _InputFieldsSection extends StatelessWidget {
  const _InputFieldsSection({
    required this.fields,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final List<_InputField> fields;
  final VoidCallback onAdd;
  final ValueChanged<_InputField> onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.skills_tool_inputs_section_title),
          style: AuraTextStyle.heading4,
        ),
        const AuraText(
          child: TextLocale(LocaleKeys.skills_tool_inputs_hint),
        ),
        for (final field in fields)
          AuraCard(
            child: AuraColumn(
              children: [
                AuraInput(
                  controller: field.nameController,
                  placeholder: const TextLocale(
                    LocaleKeys.skills_tool_input_name_placeholder,
                  ),
                  label: Text(
                    LocaleKeys.skills_tool_input_name_label.tr(
                      context: context,
                    ),
                  ),
                ),
                AuraDropdownSelector<String>(
                  options: const [
                    AuraDropdownOption(
                      value: 'string',
                      child: TextLocale(
                        LocaleKeys.skills_tool_input_type_string,
                      ),
                    ),
                    AuraDropdownOption(
                      value: 'number',
                      child: TextLocale(
                        LocaleKeys.skills_tool_input_type_number,
                      ),
                    ),
                    AuraDropdownOption(
                      value: 'integer',
                      child: TextLocale(
                        LocaleKeys.skills_tool_input_type_integer,
                      ),
                    ),
                    AuraDropdownOption(
                      value: 'boolean',
                      child: TextLocale(
                        LocaleKeys.skills_tool_input_type_boolean,
                      ),
                    ),
                    AuraDropdownOption(
                      value: 'object',
                      child: TextLocale(
                        LocaleKeys.skills_tool_input_type_object,
                      ),
                    ),
                    AuraDropdownOption(
                      value: 'array',
                      child: TextLocale(
                        LocaleKeys.skills_tool_input_type_array,
                      ),
                    ),
                  ],
                  value: field.type,
                  onChanged: (value) {
                    if (value == null) return;
                    field.type = value;
                    onChanged();
                  },
                  label: Text(
                    LocaleKeys.skills_tool_input_type_label.tr(
                      context: context,
                    ),
                  ),
                ),
                AuraInput(
                  controller: field.descriptionController,
                  placeholder: Text(
                    LocaleKeys.skills_tool_input_description_hint.tr(
                      context: context,
                    ),
                  ),
                  label: Text(
                    LocaleKeys.skills_tool_input_description_label.tr(
                      context: context,
                    ),
                  ),
                ),
                AuraCheckboxListTile(
                  value: field.optional,
                  onChanged: (value) {
                    field.optional = value;
                    onChanged();
                  },
                  title: const TextLocale(
                    LocaleKeys.skills_tool_input_optional_label,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: AuraButton(
                    onPressed: () => onRemove(field),
                    child: AuraRow(
                      children: [
                        const AuraIcon(Icons.remove_circle_outline),
                        Text(LocaleKeys.common_remove.tr(context: context)),
                      ],
                      spacing: AuraSpacing.xs,
                      mainAxisSize: MainAxisSize.min,
                    ),
                    variant: AuraButtonVariant.text,
                  ),
                ),
              ],
              spacing: AuraSpacing.sm,
            ),
            style: AuraCardStyle.border,
          ),
        AuraButton(
          onPressed: onAdd,
          child: AuraRow(
            children: [
              const AuraIcon(Icons.add),
              Text(LocaleKeys.skills_tool_add_input.tr(context: context)),
            ],
            spacing: AuraSpacing.xs,
            mainAxisSize: MainAxisSize.min,
          ),
          variant: AuraButtonVariant.text,
        ),
      ],
      spacing: AuraSpacing.sm,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}

class _KeyValueField {
  _KeyValueField({String key = '', String value = ''})
    : keyController = TextEditingController(text: key),
      valueController = TextEditingController(text: value);

  final TextEditingController keyController;
  final TextEditingController valueController;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class _InputField {
  _InputField({
    String name = '',
    this.type = 'string',
    String description = '',
    this.optional = false,
  }) : nameController = TextEditingController(text: name),
       descriptionController = TextEditingController(text: description);

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  String type;
  bool optional;

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.labelKey, required this.value});

  final String labelKey;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        AuraText(
          child: TextLocale(labelKey),
        ),
        AuraSelectableText(value),
      ],
      spacing: AuraSpacing.xs,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}
