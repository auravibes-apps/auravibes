// ignore_for_file: no-magic-number
// Required: Existing UI spacing uses small numeric values.
// ignore_for_file: prefer-single-widget-per-file
// Required: Private form row widgets keep this screen self-contained.
import 'dart:convert';

import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
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
  final _descriptionController = TextEditingController();
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

    return AuraScreen(
      child: _buildBody(
        context,
        toolAsync,
        currentTool,
        skillHasCredentialDefinition,
      ),
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

  Widget _buildBody(
    BuildContext context,
    AsyncValue<SkillTemplateToolEntity?>? toolAsync,
    SkillTemplateToolEntity? currentTool,
    bool skillHasCredentialDefinition,
  ) {
    if (toolAsync == null) {
      return _buildForm(context, null, skillHasCredentialDefinition);
    }

    return switch (toolAsync) {
      AsyncData(:final value) => _buildLoadedBody(
        context,
        value,
        skillHasCredentialDefinition,
      ),
      AsyncLoading() when currentTool != null => _buildForm(
        context,
        currentTool,
        skillHasCredentialDefinition,
      ),
      AsyncLoading() => const Center(
        child: AuraSpinner(),
      ),
      AsyncError() => const Center(
        child: TextLocale(LocaleKeys.skills_tool_load_error),
      ),
    };
  }

  Widget _buildLoadedBody(
    BuildContext context,
    SkillTemplateToolEntity? tool,
    bool skillHasCredentialDefinition,
  ) {
    if (tool == null) {
      return const Center(
        child: TextLocale(LocaleKeys.skills_tool_not_found),
      );
    }

    return _buildForm(context, tool, skillHasCredentialDefinition);
  }

  Widget _buildForm(
    BuildContext context,
    SkillTemplateToolEntity? tool,
    bool skillHasCredentialDefinition,
  ) {
    if (tool != null && !_initialized) {
      _initializeFromTool(tool);
    } else if (tool == null && !_initialized) {
      _inputFields.add(_InputField());
      _initialized = true;
    }

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
                controller: _titleController,
                label: Text(
                  LocaleKeys.skills_screen_title_label.tr(context: context),
                ),
              ),
              AuraInput(
                controller: _descriptionController,
                placeholder: Text(
                  LocaleKeys.skills_tool_description_hint.tr(context: context),
                ),
                label: Text(
                  LocaleKeys.skills_tool_description_label.tr(context: context),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              AuraInput(
                controller: _urlController,
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
                value: _method,
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
                label: Text(
                  LocaleKeys.skills_tool_method_label.tr(context: context),
                ),
              ),
              _QueryFieldsSection(
                fields: _queryFields,
                onAdd: () => setState(() => _queryFields.add(_KeyValueField())),
                onRemove: (field) => setState(() {
                  _queryFields.remove(field);
                  field.dispose();
                }),
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
                value: _bodyFormat,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _bodyFormat = value);
                },
                label: Text(
                  LocaleKeys.skills_tool_body_format_label.tr(context: context),
                ),
              ),
              AuraInput(
                controller: _bodyController,
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
                fields: _inputFields,
                onAdd: () => setState(() => _inputFields.add(_InputField())),
                onRemove: (field) => setState(() {
                  _inputFields.remove(field);
                  field.dispose();
                }),
                onChanged: () => setState(() {}),
              ),
              if (skillHasCredentialDefinition)
                AuraCheckboxListTile(
                  value: _requiresCredential,
                  onChanged: (value) {
                    setState(() => _requiresCredential = value);
                  },
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
                    value: _isEnabled,
                    onChanged: (value) => setState(() => _isEnabled = value),
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
                  onPressed: () => _save(context),
                  child: const TextLocale(LocaleKeys.skills_screen_save),
                  disabled: _isSaving,
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

  void _initializeFromTool(SkillTemplateToolEntity tool) {
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
        final usecase = ref.read(updateSkillTemplateToolUsecaseProvider);
        final _ = await usecase.call(
          widget.toolId!,
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
      showAuraSnackBar(
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
          color: AuraColorVariant.onSurfaceVariant,
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
                  placeholder: const Text('{input:search}'),
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
          color: AuraColorVariant.onSurfaceVariant,
        ),
        for (final field in fields)
          AuraCard(
            child: AuraColumn(
              children: [
                AuraInput(
                  controller: field.nameController,
                  placeholder: const Text('company_id'),
                  label: Text(
                    LocaleKeys.skills_tool_input_name_label.tr(
                      context: context,
                    ),
                  ),
                ),
                AuraDropdownSelector<String>(
                  options: const [
                    AuraDropdownOption(value: 'string', child: Text('String')),
                    AuraDropdownOption(value: 'number', child: Text('Number')),
                    AuraDropdownOption(
                      value: 'integer',
                      child: Text('Integer'),
                    ),
                    AuraDropdownOption(
                      value: 'boolean',
                      child: Text('Boolean'),
                    ),
                    AuraDropdownOption(value: 'object', child: Text('Object')),
                    AuraDropdownOption(value: 'array', child: Text('Array')),
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
          color: AuraColorVariant.onSurfaceVariant,
        ),
        AuraSelectableText(value),
      ],
      spacing: AuraSpacing.xs,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}
