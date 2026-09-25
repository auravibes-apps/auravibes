// Required: Existing UI spacing uses small numeric values.
// Required: Private form row widgets keep this screen self-contained.
import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/markdown/markdown_editor_launcher.dart';
import 'package:auravibes_app/features/markdown/widgets/markdown_preview_field.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/update_skill_template_tool_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show
        SkillTemplateDefinition,
        SkillTemplateInputDefinition,
        SkillTemplateRequestPreview,
        SkillUrlTemplate,
        SkillUrlTemplateBodyFormat;
import 'package:auravibes_engine/auravibes_engine.dart'
    show UrlRequestMethod, renderSkillTemplatePreview;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:textf/textf.dart';

const int _skillToolDescriptionMaxCharacters = 1024;

typedef _TemplateJsonRequest = ({
  String url,
  String description,
  List<_KeyValueField> headerFields,
  List<_KeyValueField> queryFields,
  UrlRequestMethod method,
  String body,
  SkillUrlTemplateBodyFormat bodyFormat,
});

typedef _SkillToolWatchData = ({
  AsyncValue<SkillTemplateToolEntity?>? toolAsync,
  SkillTemplateToolEntity? currentTool,
  String? skillCredentialDefinitionId,
});

typedef _SkillToolSavePayloadFields = ({
  String title,
  String description,
  String templateJson,
  String inputsJson,
  String definitionJson,
  String? credentialDefinitionId,
  bool clearCredentialDefinition,
  bool requiresCredential,
  bool isEnabled,
});

_SkillToolSavePayload _savePayloadFromFields(
  _SkillToolSavePayloadFields fields,
) => _SkillToolSavePayload(
  title: fields.title,
  description: fields.description,
  templateJson: fields.templateJson,
  inputsJson: fields.inputsJson,
  definitionJson: fields.definitionJson,
  credentialDefinitionId: fields.credentialDefinitionId,
  clearCredentialDefinition: fields.clearCredentialDefinition,
  requiresCredential: fields.requiresCredential,
  isEnabled: fields.isEnabled,
);

class const _SkillToolSavePayload({
  required final String title,
  required final String description,
  required final String templateJson,
  required final String inputsJson,
  required final String definitionJson,
  required final String? credentialDefinitionId,
  required final bool clearCredentialDefinition,
  required final bool requiresCredential,
  required final bool isEnabled,
});

class const SkillToolEditScreen({
  required final String workspaceId,
  required final String skillId,
  final String? toolId,
  final SkillToolEditRouteGuard? routeExitGuard,
  super.key,
}) extends ConsumerStatefulWidget {
  static const _maxToolBodyLines = 12;
  static const _minAdvancedDefinitionLines = 8;
  static const int _maxAdvancedDefinitionLines =
      _maxToolBodyLines + _maxToolBodyLines;
  @override
  ConsumerState<SkillToolEditScreen> createState() =>
      _SkillToolEditScreenState();
}

/// Guards route replacements that bypass the screen's PopScope.
class SkillToolEditRouteGuard {
  var _isDirty = false;
  var _isSaving = false;

  void update({required bool isDirty, required bool isSaving}) {
    _isDirty = isDirty;
    _isSaving = isSaving;
  }

  Future<bool> canExit(BuildContext context) async {
    if (_isSaving || !context.mounted) return false;
    if (!_isDirty) return true;

    final shouldDiscard = await AuraDialogs.confirm(
      context: context,
      title: const TextLocale(LocaleKeys.common_unsaved_changes_title),
      message: const TextLocale(LocaleKeys.common_unsaved_changes_message),
      actions: const AuraConfirmDialogActions(
        confirmLabel: TextLocale(LocaleKeys.common_discard_changes),
        cancelLabel: TextLocale(LocaleKeys.common_keep_editing),
      ),
      isDestructive: true,
    );
    if (shouldDiscard != true || !context.mounted) return false;

    _isDirty = false;

    return true;
  }
}

class _SkillToolEditScreenState extends ConsumerState<SkillToolEditScreen> {
  SkillToolEditRouteGuard? _routeExitGuard;

  final _titleController = TextEditingController();
  final _descriptionController = TextfEditingController();
  final _urlController = TextEditingController();
  final _bodyController = TextEditingController();
  final _definitionController = TextEditingController();
  final _credentialDefinitionIdController = TextEditingController();
  final _headerFields = <_KeyValueField>[];
  final _queryFields = <_KeyValueField>[];
  final _inputFields = <_InputField>[];
  UrlRequestMethod _method = .get;
  SkillUrlTemplateBodyFormat _bodyFormat = .json;
  bool _requiresCredential = false;
  bool _isEnabled = true;
  bool _editRawDefinition = false;
  bool _initialized = false;
  bool _isSaving = false;
  bool _isDirty = false;
  bool _allowPop = false;
  bool _isUpdating = false;
  String _savedSnapshot = '';

  SkillToolEditRouteGuard get _exitGuard =>
      _routeExitGuard ??= widget.routeExitGuard ?? SkillToolEditRouteGuard();

  bool get _isCreate => widget.toolId == null;

  @override
  void initState() {
    super.initState();
    _syncRouteExitGuard();
    _titleController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
    _urlController.addListener(_onFormChanged);
    _bodyController.addListener(_onFormChanged);
    _definitionController.addListener(_onFormChanged);
    _credentialDefinitionIdController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_onFormChanged)
      ..dispose();
    _descriptionController
      ..removeListener(_onFormChanged)
      ..dispose();
    _urlController
      ..removeListener(_onFormChanged)
      ..dispose();
    _bodyController
      ..removeListener(_onFormChanged)
      ..dispose();
    _definitionController
      ..removeListener(_onFormChanged)
      ..dispose();
    _credentialDefinitionIdController
      ..removeListener(_onFormChanged)
      ..dispose();
    _headerFields.forEach(_disposeKeyValueField);
    _queryFields.forEach(_disposeKeyValueField);
    _inputFields.forEach(_disposeInputField);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _watchData();
    _initializeForView(data);

    return PopScope<Object?>(
      child: _SkillToolEditView(data: _viewData(context, data)),
      canPop: _allowPop || (!_isDirty && !_isSaving),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack(context));
      },
    );
  }

  void _setState(VoidCallback callback) {
    _isUpdating = true;
    try {
      setState(() {
        callback();
        if (_initialized) {
          _isDirty = _currentSnapshot() != _savedSnapshot;
        }
        _syncRouteExitGuard();
      });
    } finally {
      _isUpdating = false;
    }
  }

  void _syncRouteExitGuard() =>
      _exitGuard.update(isDirty: _isDirty, isSaving: _isSaving);
}

extension _SkillToolEditScreenStateDirtyTracking on _SkillToolEditScreenState {
  void _listenToKeyValueField(_KeyValueField field) {
    field.keyController.addListener(_onFormChanged);
    field.valueController.addListener(_onFormChanged);
  }

  void _disposeKeyValueField(_KeyValueField field) {
    field.keyController.removeListener(_onFormChanged);
    field.valueController.removeListener(_onFormChanged);
    field.dispose();
  }

  List<TextEditingController> _inputControllers(_InputField field) => [
    field.nameController,
    field.descriptionController,
    field.defaultController,
    field.enumController,
    field.minimumController,
    field.maximumController,
    field.nestedPropertiesController,
  ];

  void _listenToInputField(_InputField field) {
    for (final controller in _inputControllers(field)) {
      controller.addListener(_onFormChanged);
    }
  }

  void _disposeInputField(_InputField field) {
    for (final controller in _inputControllers(field)) {
      controller.removeListener(_onFormChanged);
    }
    field.dispose();
  }

  void _addKeyValueField(List<_KeyValueField> fields) {
    _setState(() {
      final field = _KeyValueField();
      _listenToKeyValueField(field);
      fields.add(field);
    });
  }

  void _addInputField() {
    _setState(() {
      final field = _InputField();
      _listenToInputField(field);
      _inputFields.add(field);
    });
  }

  void _onFormChanged() {
    if (!mounted || !_initialized || _isUpdating) return;
    _setState(() => _isDirty = _currentSnapshot() != _savedSnapshot);
  }

  Future<void> _handleBack(BuildContext context) async {
    if (!await _exitGuard.canExit(context) || !context.mounted) return;
    _popEditor(context);
  }

  void _popEditor(BuildContext context, {bool? saved}) {
    _savedSnapshot = _currentSnapshot();
    _setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pop<bool>(saved);
    });
  }

  String _currentSnapshot() {
    try {
      final payload = _savePayload();

      return jsonEncode({
        'title': payload.title,
        'description': payload.description,
        'template': _canonicalJsonValue(jsonDecode(payload.templateJson)),
        'inputs': _canonicalJsonValue(jsonDecode(payload.inputsJson)),
        'definition': _canonicalJsonValue(jsonDecode(payload.definitionJson)),
        'credentialDefinitionId': payload.credentialDefinitionId,
        'clearCredentialDefinition': payload.clearCredentialDefinition,
        'requiresCredential': payload.requiresCredential,
        'isEnabled': payload.isEnabled,
      });
    } on Object {
      return jsonEncode({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'url': _urlController.text,
        'method': _method.value,
        'body': _bodyController.text,
        'bodyFormat': _bodyFormat.value,
        'headers': [
          for (final field in _headerFields)
            [field.keyController.text, field.valueController.text],
        ],
        'query': [
          for (final field in _queryFields)
            [field.keyController.text, field.valueController.text],
        ],
        'inputs': [
          for (final field in _inputFields)
            [
              field.nameController.text,
              field.type,
              field.descriptionController.text,
              field.optional,
              field.defaultController.text,
              field.enumController.text,
              field.minimumController.text,
              field.maximumController.text,
              field.itemType,
              field.nestedPropertiesController.text,
            ],
        ],
        'definition': _definitionController.text,
        'editRawDefinition': _editRawDefinition,
        'credentialDefinitionId': _credentialDefinitionIdController.text,
        'requiresCredential': _requiresCredential,
        'isEnabled': _isEnabled,
      });
    }
  }
}

Object? _canonicalJsonValue(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();

    return {for (final key in keys) key: _canonicalJsonValue(value[key])};
  }
  if (value is List) {
    return [for (final item in value) _canonicalJsonValue(item)];
  }

  return value;
}

extension _SkillToolEditScreenStateView on _SkillToolEditScreenState {
  _SkillToolWatchData _watchData() {
    final toolId = widget.toolId;
    final toolAsync = _watchTool(toolId);

    return (
      toolAsync: toolAsync,
      currentTool: toolAsync?.value,
      skillCredentialDefinitionId: _watchSkillCredentialDefinitionId(),
    );
  }

  AsyncValue<SkillTemplateToolEntity?>? _watchTool(String? toolId) {
    if (toolId == null) return null;

    return ref.watch(skillTemplateToolProvider(widget.workspaceId, toolId));
  }

  String? _watchSkillCredentialDefinitionId() => ref
      .watch(skillDetailProvider(widget.workspaceId, widget.skillId))
      .value
      ?.credentialDefinitionId;

  void _initializeForView(_SkillToolWatchData data) {
    final currentTool = data.currentTool;
    if (currentTool != null) _initializeFromTool(currentTool);
    if (data.toolAsync == null && !_initialized) {
      final field = _InputField();
      _listenToInputField(field);
      _inputFields.add(field);
      _initialized = true;
      _savedSnapshot = _currentSnapshot();
      _isDirty = false;
      _syncRouteExitGuard();
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
      skillCredentialDefinitionId: data.skillCredentialDefinitionId,
    ),
    isSaving: _isSaving,
    onSave: () => _save(context),
    onPreview: () => _preview(context),
    onBack: () => _handleBack(context),
  );

  _SkillToolFormData _formData(
    BuildContext context, {
    required String? skillCredentialDefinitionId,
  }) => _SkillToolFormData(
    values: _formValues(
      skillCredentialDefinitionId: skillCredentialDefinitionId,
    ),
    actions: _formActions(context),
  );

  _SkillToolFormValues _formValues({
    required String? skillCredentialDefinitionId,
  }) => (
    state: this,
    workspaceId: widget.workspaceId,
    skillCredentialDefinitionId: skillCredentialDefinitionId,
  );
}

extension _SkillToolEditScreenStateFormActions on _SkillToolEditScreenState {
  _SkillToolFormActions _formActions(BuildContext context) =>
      _SkillToolFormActions(
        text: _textActions(context),
        headers: _headerActions(),
        query: _queryActions(),
        body: _bodyActions(),
        advanced: _advancedActions(),
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
    onAdd: () => _addKeyValueField(_queryFields),
    onRemove: _removeQueryField,
  );

  _SkillToolHeaderActions _headerActions() => _SkillToolHeaderActions(
    onAdd: () => _addKeyValueField(_headerFields),
    onRemove: _removeHeaderField,
  );

  _SkillToolBodyActions _bodyActions() => _SkillToolBodyActions(
    onFormatChanged: (value) => _setState(() => _bodyFormat = value),
  );

  _SkillToolAdvancedActions _advancedActions() => _SkillToolAdvancedActions(
    value: _editRawDefinition,
    onChanged: _setRawDefinitionMode,
  );

  _SkillToolInputActions _inputActions() => _SkillToolInputActions(
    onAdd: _addInputField,
    onRemove: _removeInputField,
    onChanged: () => _setState(() {
      final _ = Object();
    }),
  );

  _SkillToolOptionActions _optionsActions() => _SkillToolOptionActions(
    onCredentialDefinitionChanged: _setCredentialDefinitionId,
    onRequiresCredentialChanged: (value) =>
        _setState(() => _requiresCredential = value),
    onEnabledChanged: (value) => _setState(() => _isEnabled = value),
  );

  void _setCredentialDefinitionId(String? value) => _setState(() {
    _credentialDefinitionIdController.text = value ?? '';
  });
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

  Future<void> _preview(BuildContext context) async {
    try {
      await _showPreviewDialog(context, _renderPreview());
    } on Object {
      if (!context.mounted) return;
      final _ = AuraSnackBars.show(
        context: context,
        content: Text(
          LocaleKeys.skills_tool_preview_error.tr(context: context),
        ),
        variant: .error,
      );
    }
  }

  SkillTemplateRequestPreview _renderPreview() {
    final definition = SkillTemplateDefinition.fromJsonString(
      _savePayload().definitionJson,
    );

    return renderSkillTemplatePreview(
      definition: definition,
      inputs: _previewInputs(definition),
    );
  }

  Future<void> _showPreviewDialog(
    BuildContext context,
    SkillTemplateRequestPreview preview,
  ) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => _SkillToolPreviewDialog(preview: preview),
    );
  }

  void _removeQueryField(_KeyValueField field) {
    _setState(() {
      final _ = _queryFields.remove(field);
      _disposeKeyValueField(field);
    });
  }

  void _removeInputField(_InputField field) {
    _setState(() {
      final _ = _inputFields.remove(field);
      _disposeInputField(field);
    });
  }

  void _removeHeaderField(_KeyValueField field) {
    _setState(() {
      final _ = _headerFields.remove(field);
      _disposeKeyValueField(field);
    });
  }

  void _setRawDefinitionMode(bool value) {
    if (value) {
      try {
        _definitionController.text = _structuredDefinition().toJsonString();
      } on Object {
        _definitionController.clear();
      }
    }
    _setState(() => _editRawDefinition = value);
  }
}

extension _SkillToolEditScreenStateInitialization on _SkillToolEditScreenState {
  void _initializeFromTool(SkillTemplateToolEntity tool) {
    if (_initialized) return;

    _applyToolMetadata(tool);
    final definition = _parseSkillTemplateDefinition(tool);
    _definitionController.text = definition?.toJsonString() ?? '';
    _applyTemplate(
      definition == null
          ? tool
          : tool.copyWith(templateJson: definition.legacyTemplateJson),
    );
    _applyInputFields(definition?.legacyInputsJson ?? tool.inputsJson);
    _headerFields.forEach(_listenToKeyValueField);
    _queryFields.forEach(_listenToKeyValueField);
    _inputFields.forEach(_listenToInputField);
    _initialized = true;
    _savedSnapshot = _currentSnapshot();
    _isDirty = false;
    _syncRouteExitGuard();
  }

  void _applyToolMetadata(SkillTemplateToolEntity tool) {
    _titleController.text = tool.title;
    _descriptionController.text = tool.description;
    _requiresCredential = tool.requiresCredential;
    _isEnabled = tool.isEnabled;
    _credentialDefinitionIdController.text = tool.credentialDefinitionId ?? '';
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
    _headerFields
      ..clear()
      ..addAll(template.headerFields);
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
    _savedSnapshot = _currentSnapshot();
    _popEditor(context, saved: true);
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
    final credentialDefinitionId = _credentialDefinitionId();
    final definition = _definitionForSave();

    return _savePayloadFor(definition, credentialDefinitionId);
  }

  bool _hasCredentialDefinition() =>
      ref
          .read(skillDetailProvider(widget.workspaceId, widget.skillId))
          .value
          ?.credentialDefinitionId !=
      null;

  SkillTemplateDefinition _structuredDefinition() {
    final templateJson = _buildTemplateJson();
    final inputsJson = _buildInputsJson();

    return SkillTemplateDefinition.fromLegacyJson(
      templateJson: templateJson,
      inputsJson: inputsJson,
    );
  }
}

extension _SkillToolEditScreenStateSaveValues on _SkillToolEditScreenState {
  String _credentialDefinitionId() =>
      _credentialDefinitionIdController.text.trim();

  SkillTemplateDefinition _definitionForSave() => _editRawDefinition
      ? SkillTemplateDefinition.fromJsonString(_definitionController.text)
      : _structuredDefinition();

  _SkillToolSavePayload _savePayloadFor(
    SkillTemplateDefinition definition,
    String credentialDefinitionId,
  ) {
    return _savePayloadFromFields(
      _savePayloadFields(definition, credentialDefinitionId),
    );
  }

  _SkillToolSavePayloadFields _savePayloadFields(
    SkillTemplateDefinition definition,
    String credentialDefinitionId,
  ) => (
    title: _titleController.text,
    description: _descriptionController.text,
    templateJson: definition.legacyTemplateJson,
    inputsJson: definition.legacyInputsJson,
    definitionJson: definition.toJsonString(),
    credentialDefinitionId: _savedCredentialDefinitionId(
      credentialDefinitionId,
    ),
    clearCredentialDefinition: _shouldClearCredentialDefinition(
      credentialDefinitionId,
    ),
    requiresCredential: _requiresCredentialForSave(credentialDefinitionId),
    isEnabled: _isEnabled,
  );

  String? _savedCredentialDefinitionId(String credentialDefinitionId) =>
      credentialDefinitionId.isEmpty ? null : credentialDefinitionId;

  bool _shouldClearCredentialDefinition(String credentialDefinitionId) =>
      !_isCreate && credentialDefinitionId.isEmpty;

  bool _requiresCredentialForSave(String credentialDefinitionId) =>
      (credentialDefinitionId.isNotEmpty || _hasCredentialDefinition()) &&
      _requiresCredential;
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
      headerFields: _headerFields,
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
        definitionJson: payload.definitionJson,
        templateJson: payload.templateJson,
        inputsJson: payload.inputsJson,
        credentialDefinitionId: payload.credentialDefinitionId,
        requiresCredential: payload.requiresCredential,
        isEnabled: payload.isEnabled,
      );

  SkillTemplateToolToUpdate _updateToolData(_SkillToolSavePayload payload) =>
      .new(
        title: payload.title,
        description: payload.description,
        definitionJson: payload.definitionJson,
        templateJson: payload.templateJson,
        inputsJson: payload.inputsJson,
        credentialDefinitionId: payload.credentialDefinitionId,
        clearCredentialDefinition: payload.clearCredentialDefinition,
        requiresCredential: payload.requiresCredential,
        isEnabled: payload.isEnabled,
      );
}

SkillTemplateDefinition? _parseSkillTemplateDefinition(
  SkillTemplateToolEntity tool,
) {
  final source = tool.definitionJson.trim();
  if (source.isEmpty || source == '{}') return null;

  try {
    return SkillTemplateDefinition.fromJsonString(source);
  } on Object {
    return null;
  }
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
  final headers = _headerValues(request.headerFields);
  final query = _queryValues(request.queryFields);
  final body = request.body.trim();

  return {
    'url': url,
    'method': request.method.value,
    if (headers.isNotEmpty) 'headers': headers,
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
  required final List<_KeyValueField> headerFields,
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
      headerFields: _parsedKeyValueFields(template.headers),
      queryFields: _parsedQueryFields(template.query),
    );

List<_KeyValueField> _parsedKeyValueFields(Map<String, String> values) => [
  for (final entry in values.entries)
    _KeyValueField(key: entry.key, value: entry.value),
];

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
) => [for (final entry in inputs.entries) _parsedInputField(entry)];

_InputField _parsedInputField(
  MapEntry<String, SkillTemplateInputDefinition> entry,
) => _InputField.fromDefinition(entry.key, entry.value);

String _nestedPropertiesText(SkillTemplateInputDefinition definition) {
  if (definition.properties.isEmpty) return '';

  return jsonEncode({
    for (final nested in definition.properties.entries)
      nested.key: nested.value.toJson(),
  });
}

String _inputValueText(Object? value) {
  if (value == null) return '';
  if (value is String) return value;

  return jsonEncode(value);
}

String _enumValueText(List<Object?> values) {
  if (values.isEmpty) return '';
  if (values.every((value) => value is String)) return values.join(', ');

  return jsonEncode(values);
}

Map<String, dynamic> _previewInputs(SkillTemplateDefinition definition) => {
  for (final entry in definition.inputs.entries)
    entry.key: _previewInputValue(entry.value),
};

Object? _previewInputValue(SkillTemplateInputDefinition definition) {
  if (definition.defaultValue != null) return definition.defaultValue;

  return switch (definition.type.trim().toLowerCase()) {
    'array' => [
      if (definition.items case final item?) _previewInputValue(item),
    ],
    'boolean' => true,
    'integer' || 'number' => 1,
    'object' => {
      for (final entry in definition.properties.entries)
        if (!entry.value.optional) entry.key: _previewInputValue(entry.value),
    },
    _ => 'sample',
  };
}

Map<String, String> _queryValues(List<_KeyValueField> fields) {
  return _keyValueValues(fields, 'Query fields require key and value.');
}

Map<String, String> _headerValues(List<_KeyValueField> fields) {
  return _keyValueValues(fields, 'Header fields require name and value.');
}

Map<String, String> _keyValueValues(
  List<_KeyValueField> fields,
  String errorMessage,
) {
  final values = <String, String>{};
  for (final field in fields) {
    final value = _keyValueFieldValue(field, errorMessage);
    if (value == null) continue;
    values[value.key] = value.value;
  }

  return values;
}

MapEntry<String, String>? _keyValueFieldValue(
  _KeyValueField field,
  String errorMessage,
) {
  final key = field.keyController.text.trim();
  final value = field.valueController.text.trim();
  if (key.isEmpty && value.isEmpty) return null;
  if (key.isEmpty || value.isEmpty) {
    throw FormatException(errorMessage);
  }

  return MapEntry(key, value);
}

Map<String, Map<String, Object?>> _inputValues(List<_InputField> fields) {
  final inputs = <String, Map<String, Object?>>{};
  for (final field in fields) {
    final value = _inputFieldValue(field);
    if (value == null) continue;
    inputs[value.key] = value.value;
  }

  return inputs;
}

MapEntry<String, Map<String, Object?>>? _inputFieldValue(_InputField field) {
  final name = field.nameController.text.trim();
  final description = field.descriptionController.text.trim();
  if (name.isEmpty && description.isEmpty) return null;
  if (name.isEmpty || description.isEmpty) {
    throw const FormatException('Input fields require name and description.');
  }

  return MapEntry(name, _inputFieldDefinition(field));
}

Map<String, Object?> _inputFieldDefinition(_InputField field) {
  final values = <String, Object?>{
    'type': field.type,
    'description': field.descriptionController.text.trim(),
    if (field.optional) 'optional': true,
  };

  return values
    ..addAll(_inputFieldDefaults(field))
    ..addAll(_inputFieldConstraints(field));
}

Map<String, Object?> _inputFieldDefaults(_InputField field) => {
  if (field.defaultController.text.trim().isNotEmpty)
    'default': _typedFieldValue(field.defaultController.text, field.type),
  if (field.enumController.text.trim().isNotEmpty)
    'enum': _enumFieldValues(field.enumController.text, field.type),
};

Map<String, Object?> _inputFieldConstraints(_InputField field) {
  return switch (field.type) {
    'number' || 'integer' => _inputFieldRange(field),
    'array' => {
      'items': {'type': field.itemType},
    },
    'object' => _objectInputFieldConstraint(field),
    _ => const {},
  };
}

Map<String, Object?> _objectInputFieldConstraint(_InputField field) {
  final source = field.nestedPropertiesController.text.trim();
  if (source.isEmpty) return const {};

  return {'properties': _nestedProperties(source)};
}

Map<String, Object?> _inputFieldRange(_InputField field) {
  final minimum = _optionalNumber(field.minimumController.text);
  final maximum = _optionalNumber(field.maximumController.text);

  return {
    ...?_optionalInputValue('minimum', minimum),
    ...?_optionalInputValue('maximum', maximum),
  };
}

Map<String, Object?>? _optionalInputValue(String key, Object? value) {
  if (value == null) return null;

  return {key: value};
}

Object _typedFieldValue(String source, String type) {
  final value = source.trim();

  return switch (type) {
    'number' => _numberValue(value),
    'integer' => _integerValue(value),
    'boolean' => _booleanValue(value),
    'array' => _jsonArrayValue(value),
    'object' => _jsonObjectValue(value),
    _ => source,
  };
}

num _numberValue(String value) {
  final parsed = num.tryParse(value);
  if (parsed == null) throw const FormatException('Invalid number.');

  return parsed;
}

int _integerValue(String value) {
  final parsed = int.tryParse(value);
  if (parsed == null) throw const FormatException('Invalid integer.');

  return parsed;
}

bool _booleanValue(String value) {
  if (value == 'true') return true;
  if (value == 'false') return false;

  throw const FormatException('Invalid boolean.');
}

List<Object?> _jsonArrayValue(String value) {
  final parsed = jsonDecode(value);
  if (parsed is! List) throw const FormatException('Invalid array JSON.');

  return parsed;
}

Map<String, Object?> _jsonObjectValue(String value) {
  final parsed = jsonDecode(value) as Object?;
  if (parsed is! Map<String, Object?>) {
    throw const FormatException('Invalid object JSON.');
  }

  return parsed;
}

List<Object?> _enumFieldValues(String source, String type) {
  if (type == 'string') {
    return [
      for (final value in source.split(','))
        if (value.trim().isNotEmpty) value.trim(),
    ];
  }

  final trimmed = source.trim();
  if (trimmed.startsWith('[')) {
    final parsed = jsonDecode(trimmed);
    if (parsed is! List) throw const FormatException('Invalid enum JSON.');

    return parsed;
  }

  return [
    for (final value in source.split(','))
      if (value.trim().isNotEmpty) _typedFieldValue(value, type),
  ];
}

num? _optionalNumber(String source) {
  final value = source.trim();
  if (value.isEmpty) return null;
  final parsed = num.tryParse(value);
  if (parsed == null) throw const FormatException('Invalid range.');

  return parsed;
}

Map<String, Object?> _nestedProperties(String source) {
  final definitions = SkillTemplateInputDefinition.parseMap(source);

  return {
    for (final entry in definitions.entries) entry.key: entry.value.toJson(),
  };
}

class const _SkillToolEditViewData({
  required final bool isCreate,
  required final AsyncValue<SkillTemplateToolEntity?>? toolAsync,
  required final SkillTemplateToolEntity? currentTool,
  required final _SkillToolFormData formData,
  required final bool isSaving,
  required final VoidCallback onSave,
  required final VoidCallback onPreview,
  required final VoidCallback onBack,
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
      onPreview: data.onPreview,
      onBack: data.onBack,
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
  required final VoidCallback onPreview,
  required final VoidCallback onBack,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AuraAppBarWithDrawer(
    title: _SkillToolAppBarTitle(isCreate: isCreate),
    actions: [
      _SkillToolAppBarPreview(onPressed: onPreview),
      _SkillToolAppBarSave(isSaving: isSaving, onSave: onSave),
    ],
    leading: _SkillToolAppBarBack(onPressed: onBack),
  );
}

class const _SkillToolAppBarPreview({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraIconButton(
    icon: Icons.visibility_outlined,
    onPressed: onPressed,
    tooltip: LocaleKeys.skills_tool_preview_label.tr(context: context),
  );
}

class const _SkillToolPreviewDialog({
  required final SkillTemplateRequestPreview preview,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraAlertDialog(
    title: const TextLocale(LocaleKeys.skills_tool_preview_label),
    message: AuraSelectableText(
      const JsonEncoder.withIndent('  ').convert({
        'method': preview.method,
        'url': preview.url,
        'headers': preview.headers,
        'query': preview.query,
        'body': preview.body,
      }),
    ),
    dismissLabel: Text(LocaleKeys.common_close.tr(context: context)),
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
  String workspaceId,
  String? skillCredentialDefinitionId,
});

class const _SkillToolFormActions({
  required final _SkillToolTextActions text,
  required final _SkillToolHeaderActions headers,
  required final _SkillToolQueryActions query,
  required final _SkillToolBodyActions body,
  required final _SkillToolAdvancedActions advanced,
  required final _SkillToolInputActions input,
  required final _SkillToolOptionActions options,
  required final VoidCallback onSave,
});

class const _SkillToolTextActions({
  required final VoidCallback onEditDescription,
  required final ValueChanged<UrlRequestMethod> onMethodChanged,
});

class const _SkillToolHeaderActions({
  required final VoidCallback onAdd,
  required final ValueChanged<_KeyValueField> onRemove,
});

class const _SkillToolQueryActions({
  required final VoidCallback onAdd,
  required final ValueChanged<_KeyValueField> onRemove,
});

class const _SkillToolBodyActions({
  required final ValueChanged<SkillUrlTemplateBodyFormat> onFormatChanged,
});

class const _SkillToolAdvancedActions({
  required final bool value,
  required final ValueChanged<bool> onChanged,
});

class const _SkillToolInputActions({
  required final VoidCallback onAdd,
  required final ValueChanged<_InputField> onRemove,
  required final VoidCallback onChanged,
});

class const _SkillToolOptionActions({
  required final ValueChanged<String?> onCredentialDefinitionChanged,
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
        if (!values.state._editRawDefinition)
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
        if (!values.state._editRawDefinition) ...[
          _RequestKeyValueFieldsSection(
            fields: values.state._headerFields,
            onAdd: actions.headers.onAdd,
            onRemove: actions.headers.onRemove,
            sectionTitleKey: LocaleKeys.skills_tool_headers_section_title,
            hintKey: LocaleKeys.skills_tool_headers_hint,
            addKey: LocaleKeys.skills_tool_add_header,
            keyLabelKey: LocaleKeys.skills_tool_header_key_label,
            valueLabelKey: LocaleKeys.skills_tool_header_value_label,
            valuePlaceholderKey:
                LocaleKeys.skills_tool_header_value_placeholder,
          ),
          _RequestKeyValueFieldsSection(
            fields: values.state._queryFields,
            onAdd: actions.query.onAdd,
            onRemove: actions.query.onRemove,
            sectionTitleKey: LocaleKeys.skills_tool_query_section_title,
            hintKey: LocaleKeys.skills_tool_query_hint,
            addKey: LocaleKeys.skills_tool_add_query,
            keyLabelKey: LocaleKeys.skills_tool_query_key_label,
            valueLabelKey: LocaleKeys.skills_tool_query_value_label,
            valuePlaceholderKey: LocaleKeys.skills_tool_query_value_placeholder,
          ),
          _SkillToolBodyFields(values: values, actions: actions),
        ],
        _SkillToolAdvancedDefinitionField(
          controller: values.state._definitionController,
          enabled: actions.advanced.value,
          onChanged: actions.advanced.onChanged,
        ),
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

class const _SkillToolAdvancedDefinitionField({
  required final TextEditingController controller,
  required final bool enabled,
  required final ValueChanged<bool> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraCheckboxListTile(
        value: enabled,
        onChanged: onChanged,
        title: const TextLocale(
          LocaleKeys.skills_tool_advanced_definition_toggle,
        ),
        subtitle: const TextLocale(
          LocaleKeys.skills_tool_advanced_definition_hint,
        ),
      ),
      if (enabled) _SkillToolAdvancedDefinitionInput(controller: controller),
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );
}

class const _SkillToolAdvancedDefinitionInput({
  required final TextEditingController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: controller,
    label: Text(
      LocaleKeys.skills_tool_advanced_definition_label.tr(context: context),
    ),
    keyboardType: .multiline,
    minLines: SkillToolEditScreen._minAdvancedDefinitionLines,
    maxLines: SkillToolEditScreen._maxAdvancedDefinitionLines,
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
        _SkillToolCredentialDefinitionOption(
          workspaceId: values.workspaceId,
          value: values.state._credentialDefinitionIdController.text.isEmpty
              ? null
              : values.state._credentialDefinitionIdController.text,
          skillCredentialDefinitionId: values.skillCredentialDefinitionId,
          onChanged: actions.options.onCredentialDefinitionChanged,
        ),
        _SkillToolCredentialToggleFields(
          requiresCredential: values.state._requiresCredential,
          isEnabled: values.state._isEnabled,
          onRequiresCredentialChanged:
              actions.options.onRequiresCredentialChanged,
          onEnabledChanged: actions.options.onEnabledChanged,
        ),
        _SkillToolSaveOption(
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

class const _SkillToolCredentialToggleFields({
  required final bool requiresCredential,
  required final bool isEnabled,
  required final ValueChanged<bool> onRequiresCredentialChanged,
  required final ValueChanged<bool> onEnabledChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _SkillToolCredentialField(
        value: requiresCredential,
        onChanged: onRequiresCredentialChanged,
      ),
      _SkillToolEnabledField(value: isEnabled, onChanged: onEnabledChanged),
    ],
    spacing: .lg,
    crossAxisAlignment: .start,
  );
}

class const _SkillToolCredentialDefinitionOption({
  required final String workspaceId,
  required final String? value,
  required final String? skillCredentialDefinitionId,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillToolCredentialDefinitionField(
    workspaceId: workspaceId,
    value: value,
    skillCredentialDefinitionId: skillCredentialDefinitionId,
    onChanged: onChanged,
  );
}

class const _SkillToolSaveOption({
  required final bool isSaving,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _SkillToolSaveButton(isSaving: isSaving, onPressed: onPressed);
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
    value: SkillUrlTemplateBodyFormat.form,
    label: Text(LocaleKeys.skills_tool_body_format_form.tr(context: context)),
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

class const _SkillToolCredentialDefinitionField({
  required final String workspaceId,
  required final String? value,
  required final String? skillCredentialDefinitionId,
  required final ValueChanged<String?> onChanged,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitionsAsync = ref.watch(
      skillCredentialDefinitionsProvider(workspaceId),
    );

    return switch (definitionsAsync) {
      AsyncData(:final value) => _SkillToolCredentialDefinitionDropdown(
        definitions: value,
        value: this.value,
        skillCredentialDefinitionId: skillCredentialDefinitionId,
        onChanged: onChanged,
      ),
      AsyncLoading() => const AuraSpinner(size: .small),
      AsyncError() => const AuraText(
        child: TextLocale(LocaleKeys.skill_credentials_definitions_error),
        tint: .error,
      ),
    };
  }
}

class _SkillToolCredentialDefinitionDropdown extends StatelessWidget {
  new({
    required this.definitions,
    required this.value,
    required this.skillCredentialDefinitionId,
    required this.onChanged,
  }) : _options = [
         const AuraDropdownOption<String>(
           value: '',
           child: TextLocale(LocaleKeys.skill_credentials_none),
         ),
         for (final definition in definitions)
           AuraDropdownOption<String>(
             value: definition.id,
             child: Text(definition.title),
           ),
       ];

  final List<SkillCredentialDefinitionEntity> definitions;
  final String? value;
  final String? skillCredentialDefinitionId;
  final ValueChanged<String?> onChanged;
  final List<AuraDropdownOption<String>> _options;

  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: _options,
    value: value ?? '',
    onChanged: _onChanged,
    label: Text(
      LocaleKeys.skills_tool_credential_definition_label.tr(context: context),
    ),
    hint: Text(_credentialDefinitionHint(context, skillCredentialDefinitionId)),
  );

  void _onChanged(String? selected) {
    onChanged(selected == null || selected.isEmpty ? null : selected);
  }
}

String _credentialDefinitionHint(
  BuildContext context,
  String? skillCredentialDefinitionId,
) {
  final hint = LocaleKeys.skills_tool_credential_definition_hint.tr(
    context: context,
  );

  return skillCredentialDefinitionId == null ? hint : '$hint (skill default)';
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

class const _RequestKeyValueFieldsSection({
  required final List<_KeyValueField> fields,
  required final VoidCallback onAdd,
  required final ValueChanged<_KeyValueField> onRemove,
  required final String sectionTitleKey,
  required final String hintKey,
  required final String addKey,
  required final String keyLabelKey,
  required final String valueLabelKey,
  required final String valuePlaceholderKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _RequestKeyValueFieldsHeader(
          sectionTitleKey: sectionTitleKey,
          hintKey: hintKey,
        ),
        for (final field in fields)
          _RequestKeyValueFieldRow(
            field: field,
            onRemove: onRemove,
            keyLabelKey: keyLabelKey,
            valueLabelKey: valueLabelKey,
            valuePlaceholderKey: valuePlaceholderKey,
          ),
        _AddRequestKeyValueFieldButton(onPressed: onAdd, labelKey: addKey),
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

class const _RequestKeyValueFieldRow({
  required final _KeyValueField field,
  required final ValueChanged<_KeyValueField> onRemove,
  required final String keyLabelKey,
  required final String valueLabelKey,
  required final String valuePlaceholderKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _RequestKeyValueFieldKey(field: field, labelKey: keyLabelKey),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _RequestKeyValueFieldValue(
          field: field,
          labelKey: valueLabelKey,
          placeholderKey: valuePlaceholderKey,
        ),
      ),
      _RemoveRequestKeyValueFieldButton(field: field, onRemove: onRemove),
    ],
  );
}

class const _RequestKeyValueFieldsHeader({
  required final String sectionTitleKey,
  required final String hintKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraText(child: TextLocale(sectionTitleKey), style: .heading4),
      AuraText(child: TextLocale(hintKey)),
    ],
    spacing: .sm,
    crossAxisAlignment: .start,
  );
}

class const _AddRequestKeyValueFieldButton({
  required final VoidCallback onPressed,
  required final String labelKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: AuraRow(
      children: [
        const AuraIcon(Icons.add),
        Text(labelKey.tr(context: context)),
      ],
      spacing: .xs,
      mainAxisSize: .min,
    ),
    variant: .text,
  );
}

class const _RequestKeyValueFieldKey({
  required final _KeyValueField field,
  required final String labelKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: field.keyController,
    label: Text(labelKey.tr(context: context)),
  );
}

class const _RequestKeyValueFieldValue({
  required final _KeyValueField field,
  required final String labelKey,
  required final String placeholderKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: field.valueController,
    placeholder: Text(placeholderKey.tr(context: context)),
    label: Text(labelKey.tr(context: context)),
  );
}

class const _RemoveRequestKeyValueFieldButton({
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
        _InputFieldDefault(field: field),
        _InputFieldEnum(field: field),
        if (field.type == 'number' || field.type == 'integer')
          _InputFieldConstraints(field: field),
        if (field.type == 'array')
          _InputFieldItemsType(field: field, onChanged: onChanged),
        if (field.type == 'object') _InputFieldNestedProperties(field: field),
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

class const _InputFieldDefault({required final _InputField field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: field.defaultController,
    placeholder: Text(
      LocaleKeys.skills_tool_input_default_hint.tr(context: context),
    ),
    label: Text(
      LocaleKeys.skills_tool_input_default_label.tr(context: context),
    ),
  );
}

class const _InputFieldEnum({required final _InputField field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: field.enumController,
    placeholder: Text(
      LocaleKeys.skills_tool_input_enum_hint.tr(context: context),
    ),
    label: Text(LocaleKeys.skills_tool_input_enum_label.tr(context: context)),
  );
}

class const _InputFieldConstraints({required final _InputField field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _InputFieldMinimum(field: field)),
      const SizedBox(width: 8),
      Expanded(child: _InputFieldMaximum(field: field)),
    ],
  );
}

class const _InputFieldMinimum({required final _InputField field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: field.minimumController,
    label: Text(
      LocaleKeys.skills_tool_input_minimum_label.tr(context: context),
    ),
    keyboardType: .number,
  );
}

class const _InputFieldMaximum({required final _InputField field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: field.maximumController,
    label: Text(
      LocaleKeys.skills_tool_input_maximum_label.tr(context: context),
    ),
    keyboardType: .number,
  );
}

class const _InputFieldItemsType({
  required final _InputField field,
  required final VoidCallback onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraDropdownSelector<String>(
    options: _inputFieldTypeOptions,
    value: field.itemType,
    onChanged: _onChanged,
    label: Text(
      LocaleKeys.skills_tool_input_items_type_label.tr(context: context),
    ),
  );

  void _onChanged(String? value) {
    if (value == null) return;
    field.itemType = value;
    onChanged();
  }
}

class const _InputFieldNestedProperties({required final _InputField field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: field.nestedPropertiesController,
    placeholder: Text(
      LocaleKeys.skills_tool_input_nested_properties_hint.tr(context: context),
    ),
    label: Text(
      LocaleKeys.skills_tool_input_nested_properties_label.tr(context: context),
    ),
    keyboardType: .multiline,
    minLines: 3,
    maxLines: 6,
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
  // ignore: unused_element_parameter - Primary constructor field populated by fromDefinition.
  var String type = 'string',
  String description = '',
  // ignore: unused_element_parameter - Primary constructor field populated by fromDefinition.
  var bool optional = false,
  String defaultValue = '',
  String enumValue = '',
  String minimum = '',
  String maximum = '',
  // ignore: unused_element_parameter - Primary constructor field populated by fromDefinition.
  var String itemType = 'string',
  String nestedProperties = '',
}) {
  // ignore: unnecessary_type_name_in_constructor - Required by Dart primary constructor syntax.
  _InputField.fromDefinition(
    String name,
    SkillTemplateInputDefinition definition,
  ) : this(
        name: name,
        type: definition.type,
        description: definition.description,
        optional: definition.optional,
        defaultValue: _inputValueText(definition.defaultValue),
        enumValue: _enumValueText(definition.enumValues),
        minimum: '${definition.minimum ?? ''}',
        maximum: '${definition.maximum ?? ''}',
        itemType: definition.items?.type ?? 'string',
        nestedProperties: _nestedPropertiesText(definition),
      );

  final TextEditingController nameController = .new(text: name);
  final TextEditingController descriptionController = .new(text: description);
  final TextEditingController defaultController = .new(text: defaultValue);
  final TextEditingController enumController = .new(text: enumValue);
  final TextEditingController minimumController = .new(text: minimum);
  final TextEditingController maximumController = .new(text: maximum);
  final TextEditingController nestedPropertiesController = .new(
    text: nestedProperties,
  );

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    defaultController.dispose();
    enumController.dispose();
    minimumController.dispose();
    maximumController.dispose();
    nestedPropertiesController.dispose();
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
