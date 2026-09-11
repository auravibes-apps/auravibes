// Required: Existing UI spacing uses small numeric values.
// Required: Private form row widgets keep this screen self-contained.
import 'dart:convert';

import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/markdown/markdown_editor_launcher.dart';
import 'package:auravibes_app/features/markdown/widgets/markdown_preview_field.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_template_tool_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show
        SkillTemplateInputDefinition,
        SkillUrlTemplate,
        SkillUrlTemplateBodyFormat;
import 'package:auravibes_engine/auravibes_engine.dart' show UrlRequestMethod;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:textf/textf.dart';

const _skillToolDescriptionMaxCharacters = 1024;

typedef _TemplateJsonRequest = ({
  String url,
  String description,
  List<_KeyValueField> queryFields,
  UrlRequestMethod method,
  String body,
  SkillUrlTemplateBodyFormat bodyFormat,
});

typedef _SkillToolWatchData = ({
  AsyncValue<SkillTemplateToolEntity?>? toolAsync,
  SkillTemplateToolEntity? currentTool,
  bool skillHasCredentialDefinition,
});

class const _SkillToolSavePayload({
  required final String title,
  required final String description,
  required final String templateJson,
  required final String inputsJson,
  required final bool requiresCredential,
  required final bool isEnabled,
});

class const SkillToolEditScreen({
  required final String workspaceId,
  required final String skillId,
  final String? toolId,
  super.key,
}) extends ConsumerStatefulWidget {
  static const _maxToolBodyLines = 12;
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
  UrlRequestMethod _method = .get;
  SkillUrlTemplateBodyFormat _bodyFormat = .json;
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
    final data = _watchData();
    _initializeForView(data);

    return _SkillToolEditView(data: _viewData(context, data));
  }

  void _setState(VoidCallback callback) => setState(callback);
}

extension _SkillToolEditScreenStateView on _SkillToolEditScreenState {
  _SkillToolWatchData _watchData() {
    final toolId = widget.toolId;
    final toolAsync = _watchTool(toolId);

    return (
      toolAsync: toolAsync,
      currentTool: toolAsync?.value,
      skillHasCredentialDefinition: _watchSkillHasCredentialDefinition(),
    );
  }

  AsyncValue<SkillTemplateToolEntity?>? _watchTool(String? toolId) {
    if (toolId == null) return null;

    return ref.watch(skillTemplateToolProvider(widget.workspaceId, toolId));
  }

  bool _watchSkillHasCredentialDefinition() =>
      ref
          .watch(skillDetailProvider(widget.workspaceId, widget.skillId))
          .value
          ?.credentialDefinitionId !=
      null;

  void _initializeForView(_SkillToolWatchData data) {
    final currentTool = data.currentTool;
    if (currentTool != null) _initializeFromTool(currentTool);
    if (data.toolAsync == null && !_initialized) {
      _inputFields.add(_InputField());
      _initialized = true;
    }
  }

  _SkillToolEditViewData _viewData(
    BuildContext context,
    _SkillToolWatchData data,
  ) => _SkillToolEditViewData(
    isCreate: _isCreate,
    toolAsync: data.toolAsync,
    currentTool: data.currentTool,
    formData: _formData(
      context,
      skillHasCredentialDefinition: data.skillHasCredentialDefinition,
    ),
    isSaving: _isSaving,
    onSave: () => _save(context),
  );

  _SkillToolFormData _formData(
    BuildContext context, {
    required bool skillHasCredentialDefinition,
  }) => _SkillToolFormData(
    values: _formValues(
      skillHasCredentialDefinition: skillHasCredentialDefinition,
    ),
    actions: _formActions(context),
  );

  _SkillToolFormValues _formValues({
    required bool skillHasCredentialDefinition,
  }) =>
      (state: this, skillHasCredentialDefinition: skillHasCredentialDefinition);
}

extension _SkillToolEditScreenStateFormActions on _SkillToolEditScreenState {
  _SkillToolFormActions _formActions(BuildContext context) =>
      _SkillToolFormActions(
        text: _textActions(context),
        query: _queryActions(),
        body: _bodyActions(),
        input: _inputActions(),
        options: _optionsActions(),
        onSave: () => _save(context),
      );

  _SkillToolTextActions _textActions(BuildContext context) =>
      _SkillToolTextActions(
        onEditDescription: () => _editDescription(context),
        onMethodChanged: (value) => _setState(() => _method = value),
      );

  _SkillToolQueryActions _queryActions() => _SkillToolQueryActions(
    onAdd: () => _setState(() => _queryFields.add(_KeyValueField())),
    onRemove: _removeQueryField,
  );

  _SkillToolBodyActions _bodyActions() => _SkillToolBodyActions(
    onFormatChanged: (value) => _setState(() => _bodyFormat = value),
  );

  _SkillToolInputActions _inputActions() => _SkillToolInputActions(
    onAdd: () => _setState(() => _inputFields.add(_InputField())),
    onRemove: _removeInputField,
    onChanged: () => _setState(() {
      final _ = Object();
    }),
  );

  _SkillToolOptionActions _optionsActions() => _SkillToolOptionActions(
    onRequiresCredentialChanged: (value) =>
        _setState(() => _requiresCredential = value),
    onEnabledChanged: (value) => _setState(() => _isEnabled = value),
  );
}

extension _SkillToolEditScreenStateInteractions on _SkillToolEditScreenState {
  Future<void> _editDescription(BuildContext context) async {
    final result = await MarkdownEditorLauncher.show(
      context,
      initialMarkdown: _descriptionController.text,
      maxCharacters: _skillToolDescriptionMaxCharacters,
    );
    if (result == null || !context.mounted) return;

    _setState(() => _descriptionController.text = result);
  }

  void _removeQueryField(_KeyValueField field) {
    _setState(() {
      final _ = _queryFields.remove(field);
      field.dispose();
    });
  }

  void _removeInputField(_InputField field) {
    _setState(() {
      final _ = _inputFields.remove(field);
      field.dispose();
    });
  }
}

extension _SkillToolEditScreenStateInitialization on _SkillToolEditScreenState {
  void _initializeFromTool(SkillTemplateToolEntity tool) {
    if (_initialized) return;

    _applyToolMetadata(tool);
    _applyTemplate(tool);
    _applyInputFields(tool.inputsJson);
    _initialized = true;
  }

  void _applyToolMetadata(SkillTemplateToolEntity tool) {
    _titleController.text = tool.title;
    _descriptionController.text = tool.description;
    _requiresCredential = tool.requiresCredential;
    _isEnabled = tool.isEnabled;
  }

  void _applyTemplate(SkillTemplateToolEntity tool) {
    final template = _parseSkillToolTemplate(tool.templateJson);
    if (template == null) {
      _applyRawTemplate(tool.templateJson);

      return;
    }

    _applyParsedTemplate(template);
  }

  void _applyRawTemplate(String source) {
    _urlController.clear();
    _bodyController.text = source;
  }

  void _applyParsedTemplate(_ParsedSkillToolTemplate template) {
    _urlController.text = template.url;
    _method = template.method;
    _bodyFormat = template.bodyFormat;
    _bodyController.text = template.body;
    _queryFields
      ..clear()
      ..addAll(template.queryFields);
  }

  void _applyInputFields(String source) {
    _inputFields
      ..clear()
      ..addAll(_parseSkillToolInputs(source));
    if (_inputFields.isEmpty) _inputFields.add(_InputField());
  }
}

extension _SkillToolEditScreenStateSave on _SkillToolEditScreenState {
  Future<void> _save(BuildContext context) async {
    _setState(() => _isSaving = true);
    try {
      await _saveAndClose(context);
    } on Object {
      if (!context.mounted) return;

      _showSaveError(context);
    } finally {
      if (mounted) _setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAndClose(BuildContext context) async {
    final saved = await _persistTool(_savePayload());
    if (!saved || !context.mounted) return;

    _closeAfterSave(context);
  }

  Future<bool> _persistTool(_SkillToolSavePayload payload) =>
      _isCreate ? _createTool(payload) : _updateTool(payload);

  void _closeAfterSave(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context).pop(true);
  }

  void _showSaveError(BuildContext context) {
    if (!context.mounted) return;
    final _ = AuraSnackBars.show(
      context: context,
      content: Text(LocaleKeys.skills_tool_save_error.tr(context: context)),
      variant: .error,
    );
  }

  _SkillToolSavePayload _savePayload() {
    final hasCredentialDefinition = _hasCredentialDefinition();

    return _SkillToolSavePayload(
      title: _titleController.text,
      description: _descriptionController.text,
      templateJson: _buildTemplateJson(),
      inputsJson: _buildInputsJson(),
      requiresCredential: hasCredentialDefinition && _requiresCredential,
      isEnabled: _isEnabled,
    );
  }

  bool _hasCredentialDefinition() =>
      ref
          .read(skillDetailProvider(widget.workspaceId, widget.skillId))
          .value
          ?.credentialDefinitionId !=
      null;
}

extension _SkillToolEditScreenStatePersistence on _SkillToolEditScreenState {
  Future<bool> _createTool(_SkillToolSavePayload payload) async {
    final usecase = ref.read(
      createSkillTemplateToolUsecaseProvider(widget.workspaceId),
    );
    final _ = await usecase.call(widget.skillId, _createToolData(payload));

    return true;
  }

  Future<bool> _updateTool(_SkillToolSavePayload payload) async {
    final toolId = widget.toolId;
    if (toolId == null) return false;
    final usecase = ref.read(
      updateSkillTemplateToolUsecaseProvider(widget.workspaceId),
    );
    final _ = await usecase.call(toolId, _updateToolData(payload));

    return true;
  }

  String _buildTemplateJson() {
    return _templateJson((
      url: _urlController.text,
      description: _descriptionController.text,
      queryFields: _queryFields,
      method: _method,
      body: _bodyController.text,
      bodyFormat: _bodyFormat,
    ));
  }

  String _buildInputsJson() => jsonEncode(_inputValues(_inputFields));

  SkillTemplateToolToCreate _createToolData(_SkillToolSavePayload payload) =>
      .new(
        templateType: SkillTemplateToolType.url,
        title: payload.title,
        description: payload.description,
        templateJson: payload.templateJson,
        inputsJson: payload.inputsJson,
        requiresCredential: payload.requiresCredential,
        isEnabled: payload.isEnabled,
      );

  SkillTemplateToolToUpdate _updateToolData(_SkillToolSavePayload payload) =>
      .new(
        title: payload.title,
        description: payload.description,
        templateJson: payload.templateJson,
        inputsJson: payload.inputsJson,
        requiresCredential: payload.requiresCredential,
        isEnabled: payload.isEnabled,
      );
}

String _templateJson(_TemplateJsonRequest request) {
  final url = request.url.trim();
  if (url.isEmpty) throw const FormatException('URL is required.');
  _validateTemplateDescription(request.description);

  return jsonEncode(_templateValues(request, url));
}

void _validateTemplateDescription(String description) {
  if (description.trim().isEmpty) {
    throw const FormatException('Description is required.');
  }
}

Map<String, Object> _templateValues(_TemplateJsonRequest request, String url) {
  final query = _queryValues(request.queryFields);
  final body = request.body.trim();

  return {
    'url': url,
    'method': request.method.value,
    if (query.isNotEmpty) 'query': query,
    if (body.isNotEmpty) 'body': body,
    if (body.isNotEmpty) 'bodyFormat': request.bodyFormat.value,
  };
}

class const _ParsedSkillToolTemplate({
  required final String url,
  required final UrlRequestMethod method,
  required final SkillUrlTemplateBodyFormat bodyFormat,
  required final String body,
  required final List<_KeyValueField> queryFields,
});

_ParsedSkillToolTemplate? _parseSkillToolTemplate(String source) {
  try {
    final template = SkillUrlTemplate.fromJsonString(source);

    return _parsedTemplate(template);
  } on Object {
    return null;
  }
}

_ParsedSkillToolTemplate _parsedTemplate(SkillUrlTemplate template) =>
    _ParsedSkillToolTemplate(
      url: template.url,
      method: template.method,
      bodyFormat: template.resolvedBodyFormat,
      body: template.body ?? '',
      queryFields: _parsedQueryFields(template.query),
    );

List<_KeyValueField> _parsedQueryFields(Map<String, String> query) => [
  for (final entry in query.entries)
    _KeyValueField(key: entry.key, value: entry.value),
];

List<_InputField> _parseSkillToolInputs(String source) {
  try {
    final inputs = SkillTemplateInputDefinition.parseMap(source);

    return _parsedInputFields(inputs);
  } on Object {
    return [];
  }
}

List<_InputField> _parsedInputFields(
  Map<String, SkillTemplateInputDefinition> inputs,
) => [
  for (final entry in inputs.entries)
    _InputField(
      name: entry.key,
      type: entry.value.type,
      description: entry.value.description,
      optional: entry.value.optional,
    ),
];

Map<String, String> _queryValues(List<_KeyValueField> fields) {
  final query = <String, String>{};
  for (final field in fields) {
    final value = _queryFieldValue(field);
    if (value == null) continue;
    query[value.key] = value.value;
  }

  return query;
}

MapEntry<String, String>? _queryFieldValue(_KeyValueField field) {
  final key = field.keyController.text.trim();
  final value = field.valueController.text.trim();
  if (key.isEmpty && value.isEmpty) return null;
  if (key.isEmpty || value.isEmpty) {
    throw const FormatException('Query fields require key and value.');
  }

  return MapEntry(key, value);
}

Map<String, Map<String, Object>> _inputValues(List<_InputField> fields) {
  final inputs = <String, Map<String, Object>>{};
  for (final field in fields) {
    final value = _inputFieldValue(field);
    if (value == null) continue;
    inputs[value.key] = value.value;
  }

  return inputs;
}

MapEntry<String, Map<String, Object>>? _inputFieldValue(_InputField field) {
  final name = field.nameController.text.trim();
  final description = field.descriptionController.text.trim();
  if (name.isEmpty && description.isEmpty) return null;
  if (name.isEmpty || description.isEmpty) {
    throw const FormatException('Input fields require name and description.');
  }

  return MapEntry(name, {
    'type': field.type,
    'description': description,
    if (field.optional) 'optional': true,
  });
}

class const _SkillToolEditViewData({
  required final bool isCreate,
  required final AsyncValue<SkillTemplateToolEntity?>? toolAsync,
  required final SkillTemplateToolEntity? currentTool,
  required final _SkillToolFormData formData,
  required final bool isSaving,
  required final VoidCallback onSave,
});

class const _SkillToolEditView({required final _SkillToolEditViewData data})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraScreen(
    child: _SkillToolEditBody(
      toolAsync: data.toolAsync,
      currentTool: data.currentTool,
      form: _SkillToolForm(tool: data.currentTool, data: data.formData),
    ),
    appBar: _SkillToolEditAppBar(
      isCreate: data.isCreate,
      isSaving: data.isSaving,
      onSave: data.onSave,
    ),
  );
}

class const _SkillToolEditBody({
  required final AsyncValue<SkillTemplateToolEntity?>? toolAsync,
  required final SkillTemplateToolEntity? currentTool,
  required final Widget form,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final asyncValue = toolAsync;
    if (asyncValue == null) return form;

    return _AsyncToolBody(
      asyncValue: asyncValue,
      currentTool: currentTool,
      form: form,
    );
  }
}

class const _AsyncToolBody({
  required final AsyncValue<SkillTemplateToolEntity?> asyncValue,
  required final SkillTemplateToolEntity? currentTool,
  required final Widget form,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (asyncValue) {
    AsyncData(value: null) => const Center(
      child: TextLocale(LocaleKeys.skills_tool_not_found),
    ),
    AsyncData() => form,
    AsyncLoading() when currentTool != null => form,
    AsyncLoading() => const Center(child: AuraSpinner()),
    AsyncError() => const Center(
      child: TextLocale(LocaleKeys.skills_tool_load_error),
    ),
  };
}

class const _SkillToolEditAppBar({
  required final bool isCreate,
  required final bool isSaving,
  required final VoidCallback onSave,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AuraAppBar(
    title: _SkillToolAppBarTitle(isCreate: isCreate),
    actions: [_SkillToolAppBarSave(isSaving: isSaving, onSave: onSave)],
    leading: _SkillToolAppBarBack(onPressed: () => Navigator.of(context).pop()),
  );
}

class const _SkillToolAppBarTitle({required final bool isCreate})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextLocale(
    isCreate
        ? LocaleKeys.skills_tool_create_title
        : LocaleKeys.skills_tool_edit_title,
  );
}

class const _SkillToolAppBarSave({
  required final bool isSaving,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.save_outlined,
    onPressed: isSaving ? null : onSave,
    tooltip: LocaleKeys.skills_screen_save.tr(context: context),
  );
}

class const _SkillToolAppBarBack({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraIconButton(icon: Icons.arrow_back, onPressed: onPressed);
}

class const _SkillToolForm({
  required final SkillTemplateToolEntity? tool,
  required final _SkillToolFormData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      AuraCard(
        child: _SkillToolFormContent(tool: tool, data: data),
      ),
    ],
  );
}

class const _SkillToolFormData({
  required final _SkillToolFormValues values,
  required final _SkillToolFormActions actions,
});

typedef _SkillToolFormValues = ({
  _SkillToolEditScreenState state,
  bool skillHasCredentialDefinition,
});

class const _SkillToolFormActions({
  required final _SkillToolTextActions text,
  required final _SkillToolQueryActions query,
  required final _SkillToolBodyActions body,
  required final _SkillToolInputActions input,
  required final _SkillToolOptionActions options,
  required final VoidCallback onSave,
});

class const _SkillToolTextActions({
  required final VoidCallback onEditDescription,
  required final ValueChanged<UrlRequestMethod> onMethodChanged,
});

class const _SkillToolQueryActions({
  required final VoidCallback onAdd,
  required final ValueChanged<_KeyValueField> onRemove,
});

class const _SkillToolBodyActions({
  required final ValueChanged<SkillUrlTemplateBodyFormat> onFormatChanged,
});

class const _SkillToolInputActions({
  required final VoidCallback onAdd,
  required final ValueChanged<_InputField> onRemove,
  required final VoidCallback onChanged,
});

class const _SkillToolOptionActions({
  required final ValueChanged<bool> onRequiresCredentialChanged,
  required final ValueChanged<bool> onEnabledChanged,
});

class const _SkillToolFormContent({
  required final SkillTemplateToolEntity? tool,
  required final _SkillToolFormData data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final values = data.values;
    final actions = data.actions;

    return _SkillToolFormContentView(
      tool: tool,
      values: values,
      actions: actions,
    );
  }
}

class _SkillToolFormContentView extends StatelessWidget {
  new({required this.tool, required this.values, required this.actions})
    : _children = [
        _SkillToolIdentityFields(tool: tool, values: values, actions: actions),
        _SkillToolRequestFields(values: values, actions: actions),
        _SkillToolInputFields(values: values, actions: actions),
        _SkillToolOptionsFields(values: values, actions: actions),
      ];

  final SkillTemplateToolEntity? tool;
  final _SkillToolFormValues values;
  final _SkillToolFormActions actions;
  final List<Widget> _children;

  @override
  Widget build(BuildContext context) =>
      AuraColumn(children: _children, spacing: .lg, crossAxisAlignment: .start);
}

class _SkillToolIdentityFields extends StatelessWidget {
  new({required this.tool, required this.values, required this.actions})
    : _children = [
        if (tool != null)
          _ReadOnlyField(
            labelKey: LocaleKeys.skills_screen_slug_label,
            value: tool.slug,
          ),
        _SkillToolGeneralFields(values: values, actions: actions),
      ];

  final SkillTemplateToolEntity? tool;
  final _SkillToolFormValues values;
  final _SkillToolFormActions actions;
  final List<Widget> _children;

  @override
  Widget build(BuildContext context) =>
      AuraColumn(children: _children, spacing: .lg, crossAxisAlignment: .start);
}

class _SkillToolRequestFields extends StatelessWidget {
  new({required this.values, required this.actions})
    : _children = [
        _QueryFieldsSection(
          fields: values.state._queryFields,
          onAdd: actions.query.onAdd,
          onRemove: actions.query.onRemove,
        ),
        _SkillToolBodyFields(values: values, actions: actions),
      ];

  final _SkillToolFormValues values;
  final _SkillToolFormActions actions;
  final List<Widget> _children;

  @override
  Widget build(BuildContext context) =>
      AuraColumn(children: _children, spacing: .lg, crossAxisAlignment: .start);
}

class const _SkillToolInputFields({
  required final _SkillToolFormValues values,
  required final _SkillToolFormActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final input = actions.input;

    return _InputFieldsSection(
      fields: values.state._inputFields,
      onAdd: input.onAdd,
      onRemove: input.onRemove,
      onChanged: input.onChanged,
    );
  }
}

class const _SkillToolGeneralFields({
  required final _SkillToolFormValues values,
  required final _SkillToolFormActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _SkillToolGeneralFieldColumn(values: values, actions: actions);
}

class _SkillToolGeneralFieldColumn extends StatelessWidget {
  new({required this.values, required this.actions})
    : _children = [
        _SkillToolTitleField(controller: values.state._titleController),
        _SkillToolDescriptionField(
          controller: values.state._descriptionController,
          onEdit: actions.text.onEditDescription,
        ),
        _SkillToolUrlField(controller: values.state._urlController),
        _SkillToolMethodField(
          value: values.state._method,
          onChanged: actions.text.onMethodChanged,
        ),
      ];

  final _SkillToolFormValues values;
  final _SkillToolFormActions actions;
  final List<Widget> _children;

  @override
  Widget build(BuildContext context) =>
      AuraColumn(children: _children, spacing: .lg, crossAxisAlignment: .start);
}

class const _SkillToolBodyFields({
  required final _SkillToolFormValues values,
  required final _SkillToolFormActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _SkillToolBodyFormatField(
        value: values.state._bodyFormat,
        onChanged: actions.body.onFormatChanged,
      ),
      _SkillToolBodyField(controller: values.state._bodyController),
    ],
    spacing: .lg,
    crossAxisAlignment: .start,
  );
}

class const _SkillToolOptionsFields({
  required final _SkillToolFormValues values,
  required final _SkillToolFormActions actions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _SkillToolOptionFieldColumn(values: values, actions: actions);
}

class _SkillToolOptionFieldColumn extends StatelessWidget {
  new({required this.values, required this.actions})
    : _children = [
        if (values.skillHasCredentialDefinition)
          _SkillToolCredentialField(
            value: values.state._requiresCredential,
            onChanged: actions.options.onRequiresCredentialChanged,
          ),
        _SkillToolEnabledField(
          value: values.state._isEnabled,
          onChanged: actions.options.onEnabledChanged,
        ),
        _SkillToolSaveButton(
          isSaving: values.state._isSaving,
          onPressed: actions.onSave,
        ),
      ];

  final _SkillToolFormValues values;
  final _SkillToolFormActions actions;
  final List<Widget> _children;

  @override
  Widget build(BuildContext context) =>
      AuraColumn(children: _children, spacing: .lg, crossAxisAlignment: .start);
}

class const _SkillToolTitleField({
  required final TextEditingController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    label: Text(LocaleKeys.skills_screen_title_label.tr(context: context)),
  );
}

class const _SkillToolDescriptionField({
  required final TextEditingController controller,
  required final VoidCallback onEdit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MarkdownPreviewField(
    controller: controller,
    titleKey: LocaleKeys.skills_tool_description_label,
    editKey: LocaleKeys.skills_screen_edit_description,
    emptyKey: LocaleKeys.skills_screen_description_empty,
    onEdit: onEdit,
  );
}

class const _SkillToolUrlField({
  required final TextEditingController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    placeholder: Text(LocaleKeys.skills_tool_url_hint.tr(context: context)),
    label: Text(LocaleKeys.skills_tool_url_label.tr(context: context)),
  );
}

class const _SkillToolMethodField({
  required final UrlRequestMethod value,
  required final ValueChanged<UrlRequestMethod> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<UrlRequestMethod>(
    options: _methodOptions,
    value: value,
    onChanged: (selected) {
      if (selected != null) onChanged(selected);
    },
    label: Text(LocaleKeys.skills_tool_method_label.tr(context: context)),
  );
}

final List<AuraDropdownOption<UrlRequestMethod>> _methodOptions = [
  for (final method in UrlRequestMethod.values)
    AuraDropdownOption(value: method, child: Text(method.value)),
];

class const _SkillToolBodyFormatField({
  required final SkillUrlTemplateBodyFormat value,
  required final ValueChanged<SkillUrlTemplateBodyFormat> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraChoicePicker<SkillUrlTemplateBodyFormat>(
        options: _bodyFormatOptions(context),
        value: [value],
        onChanged: _handleChanged,
        label: Text(
          LocaleKeys.skills_tool_body_format_label.tr(context: context),
        ),
      );

  void _handleChanged(List<SkillUrlTemplateBodyFormat> values) {
    final selected = values.firstOrNull;
    if (selected != null) onChanged(selected);
  }
}

List<AuraChoiceOption<SkillUrlTemplateBodyFormat>> _bodyFormatOptions(
  BuildContext context,
) => [
  AuraChoiceOption(
    value: SkillUrlTemplateBodyFormat.json,
    label: Text(LocaleKeys.skills_tool_body_format_json.tr(context: context)),
  ),
  AuraChoiceOption(
    value: SkillUrlTemplateBodyFormat.text,
    label: Text(LocaleKeys.skills_tool_body_format_text.tr(context: context)),
  ),
];

class const _SkillToolBodyField({
  required final TextEditingController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    placeholder: Text(LocaleKeys.skills_tool_body_hint.tr(context: context)),
    label: Text(LocaleKeys.skills_tool_body_label.tr(context: context)),
    minLines: 5,
    maxLines: SkillToolEditScreen._maxToolBodyLines,
  );
}

class const _SkillToolCredentialField({
  required final bool value,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCheckboxListTile(
    value: value,
    onChanged: onChanged,
    title: const TextLocale(LocaleKeys.skills_tool_requires_credential_label),
    subtitle: const TextLocale(LocaleKeys.skills_tool_requires_credential_hint),
  );
}

class const _SkillToolEnabledField({
  required final bool value,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraRow(
    children: [
      AuraSwitch(value: value, onChanged: onChanged),
      const Expanded(
        child: AuraText(
          child: TextLocale(LocaleKeys.skills_screen_enabled_label),
        ),
      ),
    ],
    spacing: .md,
  );
}

class const _SkillToolSaveButton({
  required final bool isSaving,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: AuraButton(
      onPressed: onPressed,
      child: const TextLocale(LocaleKeys.skills_screen_save),
      disabled: isSaving,
    ),
  );
}

class const _QueryFieldsSection({
  required final List<_KeyValueField> fields,
  required final VoidCallback onAdd,
  required final ValueChanged<_KeyValueField> onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        const _QueryFieldsHeader(),
        for (final field in fields)
          _QueryFieldRow(field: field, onRemove: onRemove),
        _AddQueryFieldButton(onPressed: onAdd),
      ],
      spacing: .sm,
      crossAxisAlignment: .start,
    );
  }
}

class const _InputFieldsSection({
  required final List<_InputField> fields,
  required final VoidCallback onAdd,
  required final ValueChanged<_InputField> onRemove,
  required final VoidCallback onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _InputFieldsSectionColumn(
    fields: fields,
    onAdd: onAdd,
    onRemove: onRemove,
    onChanged: onChanged,
  );
}

class _InputFieldsSectionColumn extends StatelessWidget {
  new({
    required this.fields,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  }) : _children = [
         const _InputFieldsHeader(),
         for (final field in fields)
           _InputFieldCard(
             field: field,
             onRemove: onRemove,
             onChanged: onChanged,
           ),
         _AddInputFieldButton(onPressed: onAdd),
       ];

  final List<_InputField> fields;
  final VoidCallback onAdd;
  final ValueChanged<_InputField> onRemove;
  final VoidCallback onChanged;
  final List<Widget> _children;

  @override
  Widget build(BuildContext context) =>
      AuraColumn(children: _children, spacing: .sm, crossAxisAlignment: .start);
}

class const _QueryFieldRow({
  required final _KeyValueField field,
  required final ValueChanged<_KeyValueField> onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _QueryFieldKey(field: field)),
      const SizedBox(width: 8),
      Expanded(child: _QueryFieldValue(field: field)),
      _RemoveQueryFieldButton(field: field, onRemove: onRemove),
    ],
  );
}

class const _QueryFieldsHeader() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraColumn(
    children: [
      AuraText(
        child: TextLocale(LocaleKeys.skills_tool_query_section_title),
        style: .heading4,
      ),
      AuraText(child: TextLocale(LocaleKeys.skills_tool_query_hint)),
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );
}

class const _AddQueryFieldButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: AuraRow(
      children: [
        const AuraIcon(Icons.add),
        Text(LocaleKeys.skills_tool_add_query.tr(context: context)),
      ],
      spacing: .xs,
      mainAxisSize: .min,
    ),
    variant: .text,
  );
}

class const _QueryFieldKey({required final _KeyValueField field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: field.keyController,
    label: Text(LocaleKeys.skills_tool_query_key_label.tr(context: context)),
  );
}

class const _QueryFieldValue({required final _KeyValueField field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: field.valueController,
    placeholder: const TextLocale(
      LocaleKeys.skills_tool_query_value_placeholder,
    ),
    label: Text(LocaleKeys.skills_tool_query_value_label.tr(context: context)),
  );
}

class const _RemoveQueryFieldButton({
  required final _KeyValueField field,
  required final ValueChanged<_KeyValueField> onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.remove_circle_outline,
    onPressed: () => onRemove(field),
    tooltip: LocaleKeys.common_remove.tr(context: context),
  );
}

class const _InputFieldCard({
  required final _InputField field,
  required final ValueChanged<_InputField> onRemove,
  required final VoidCallback onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _InputFieldCardView(
    field: field,
    onRemove: onRemove,
    onChanged: onChanged,
  );
}

class _InputFieldCardView extends StatelessWidget {
  new({required this.field, required this.onRemove, required this.onChanged})
    : _children = [
        _InputFieldName(field: field),
        _InputFieldType(field: field, onChanged: onChanged),
        _InputFieldDescription(field: field),
        _InputFieldOptional(field: field, onChanged: onChanged),
        _InputFieldRemoveButton(field: field, onRemove: onRemove),
      ];

  final _InputField field;
  final ValueChanged<_InputField> onRemove;
  final VoidCallback onChanged;
  final List<Widget> _children;

  @override
  Widget build(BuildContext context) => AuraCard(
    child: AuraColumn(children: _children, spacing: .sm),
    style: .border,
  );
}

class const _InputFieldName({required final _InputField field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: field.nameController,
    placeholder: const TextLocale(
      LocaleKeys.skills_tool_input_name_placeholder,
    ),
    label: Text(LocaleKeys.skills_tool_input_name_label.tr(context: context)),
  );
}

class const _InputFieldType({
  required final _InputField field,
  required final VoidCallback onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: _inputFieldTypeOptions,
    value: field.type,
    onChanged: _handleTypeChanged,
    label: Text(LocaleKeys.skills_tool_input_type_label.tr(context: context)),
  );

  void _handleTypeChanged(String? value) {
    if (value == null) return;
    field.type = value;
    onChanged();
  }
}

const _inputFieldTypeOptions = <AuraDropdownOption<String>>[
  AuraDropdownOption(
    value: 'string',
    child: TextLocale(LocaleKeys.skills_tool_input_type_string),
  ),
  AuraDropdownOption(
    value: 'number',
    child: TextLocale(LocaleKeys.skills_tool_input_type_number),
  ),
  AuraDropdownOption(
    value: 'integer',
    child: TextLocale(LocaleKeys.skills_tool_input_type_integer),
  ),
  AuraDropdownOption(
    value: 'boolean',
    child: TextLocale(LocaleKeys.skills_tool_input_type_boolean),
  ),
  AuraDropdownOption(
    value: 'object',
    child: TextLocale(LocaleKeys.skills_tool_input_type_object),
  ),
  AuraDropdownOption(
    value: 'array',
    child: TextLocale(LocaleKeys.skills_tool_input_type_array),
  ),
];

class const _InputFieldsHeader() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraColumn(
    children: [
      AuraText(
        child: TextLocale(LocaleKeys.skills_tool_inputs_section_title),
        style: .heading4,
      ),
      AuraText(child: TextLocale(LocaleKeys.skills_tool_inputs_hint)),
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );
}

class const _AddInputFieldButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: AuraRow(
      children: [
        const AuraIcon(Icons.add),
        Text(LocaleKeys.skills_tool_add_input.tr(context: context)),
      ],
      spacing: .xs,
      mainAxisSize: .min,
    ),
    variant: .text,
  );
}

class const _InputFieldDescription({required final _InputField field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: field.descriptionController,
    placeholder: Text(
      LocaleKeys.skills_tool_input_description_hint.tr(context: context),
    ),
    label: Text(
      LocaleKeys.skills_tool_input_description_label.tr(context: context),
    ),
  );
}

class const _InputFieldOptional({
  required final _InputField field,
  required final VoidCallback onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCheckboxListTile(
    value: field.optional,
    onChanged: (value) {
      field.optional = value;
      onChanged();
    },
    title: const TextLocale(LocaleKeys.skills_tool_input_optional_label),
  );
}

class const _InputFieldRemoveButton({
  required final _InputField field,
  required final ValueChanged<_InputField> onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: _InputFieldRemoveAction(field: field, onRemove: onRemove),
  );
}

class const _InputFieldRemoveAction({
  required final _InputField field,
  required final ValueChanged<_InputField> onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => onRemove(field),
    child: AuraRow(
      children: [
        const AuraIcon(Icons.remove_circle_outline),
        Text(LocaleKeys.common_remove.tr(context: context)),
      ],
      spacing: .xs,
      mainAxisSize: .min,
    ),
    variant: .text,
  );
}

class _KeyValueField({String key = '', String value = ''}) {
  final TextEditingController keyController = .new(text: key);
  final TextEditingController valueController = .new(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class _InputField({
  String name = '',
  var String type = 'string',
  String description = '',
  var bool optional = false,
}) {
  final TextEditingController nameController = .new(text: name);
  final TextEditingController descriptionController = .new(text: description);
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
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
      crossAxisAlignment: .start,
    );
  }
}
