// Required: Feature widgets keep closely related private widgets together.

import 'dart:async';

import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/widgets/add_model_provider_widget.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_operations.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';

final _logger = Logger('service_connection_create_screen');

typedef _AppSkillCredentialSaveData = ({
  String appSkillId,
  String apiKey,
  String name,
});

typedef _AppSkillCredentialFailureLogRequest = ({
  _ServiceConnectionCreateScreenState state,
  _AppSkillCredentialSaveData data,
  Object error,
  StackTrace stackTrace,
});

typedef _SkillCredentialSuccessLogRequest = ({
  _ServiceConnectionCreateScreenState state,
  String definitionId,
  SkillCredentialEntity credential,
  Map<String, String> attributes,
});

typedef _SkillCredentialFailureLogRequest = ({
  _ServiceConnectionCreateScreenState state,
  String definitionId,
  Object error,
  StackTrace stackTrace,
});

class const ServiceConnectionCreateScreen({
  required final String workspaceId,
  final ServiceConnectionCreateType? initialType,
  final String? initialCredentialDefinitionId,
  final String? initialAppSkillId,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<ServiceConnectionCreateScreen> createState() =>
      _ServiceConnectionCreateScreenState();
}

class _ServiceConnectionCreateScreenState
    extends ConsumerState<ServiceConnectionCreateScreen> {
  final _nameController = TextEditingController();
  final _attributeControllers = <String, TextEditingController>{};
  ServiceConnectionCreateType _type = .modelProvider;
  String? _definitionId;
  String? _appSkillId;
  bool _isSaving = false;

  TextEditingController get _apiKeyController {
    return _attributeControllers.putIfAbsent(
      'apiKey',
      TextEditingController.new,
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeCreateState(this);
  }

  @override
  void dispose() {
    _disposeCreateState(this);
    super.dispose();
  }

  void updateState(VoidCallback callback) => setState(callback);

  @override
  Widget build(BuildContext context) {
    return _ServiceConnectionCreateView(form: .fromState(this));
  }
}

void _initializeCreateState(_ServiceConnectionCreateScreenState state) {
  final initialAppSkill = _appSkillCredentialOption(
    state.widget.initialAppSkillId,
  );
  state._type = _initialCreateType(state, initialAppSkill);
  state._definitionId = state.widget.initialCredentialDefinitionId;
  state._appSkillId = initialAppSkill?.identifier;
}

ServiceConnectionCreateType _initialCreateType(
  _ServiceConnectionCreateScreenState state,
  AppSkillDefinition? initialAppSkill,
) {
  if (initialAppSkill != null || state.widget.initialAppSkillId == null) {
    return state.widget.initialType ?? state._type;
  }

  return .modelProvider;
}

void _disposeCreateState(_ServiceConnectionCreateScreenState state) {
  state._nameController.dispose();
  for (final controller in state._attributeControllers.values) {
    controller.dispose();
  }
}

void _handleFieldChanged(_ServiceConnectionCreateScreenState state, String _) {
  state.updateState(() {
    final _ = Object();
  });
}

void _handleAppSkillChanged(
  _ServiceConnectionCreateScreenState state,
  String? value,
) {
  state.updateState(() => state._appSkillId = value);
}

void _handleModelProviderCreated(_ServiceConnectionCreateScreenState state) {
  unawaited(_closeAfterSave(state));
}

void _handleSkillCredentialSave(_ServiceConnectionCreateScreenState state) {
  unawaited(_saveSkillCredential(state));
}

void _handleAppSkillCredentialSave(_ServiceConnectionCreateScreenState state) {
  unawaited(_saveAppSkillCredential(state));
}

Future<void> _saveAppSkillCredential(
  _ServiceConnectionCreateScreenState state,
) async {
  if (state._isSaving) return;
  final data = _appSkillCredentialSaveData(state);
  if (data == null) return;

  state.updateState(() => state._isSaving = true);
  await _saveAppSkillCredentialRequest(state, data);
}

Future<void> _saveAppSkillCredentialRequest(
  _ServiceConnectionCreateScreenState state,
  _AppSkillCredentialSaveData data,
) async {
  try {
    await _createAppSkillCredential(state, data);
    await _closeAfterSave(state, resetModelMutation: false);
  } on Object catch (error, stackTrace) {
    _handleAppSkillCredentialSaveFailure((
      state: state,
      data: data,
      error: error,
      stackTrace: stackTrace,
    ));
  } finally {
    _finishSaving(state);
  }
}

void _handleAppSkillCredentialSaveFailure(
  _AppSkillCredentialFailureLogRequest request,
) {
  _logAppSkillCredentialSaveFailure(request);
  _showCredentialSaveError(request.state);
}

_AppSkillCredentialSaveData? _appSkillCredentialSaveData(
  _ServiceConnectionCreateScreenState state,
) {
  final appSkillId = state._appSkillId;
  if (appSkillId == null) return null;

  final apiKey = state._apiKeyController.text.trim();
  if (apiKey.isEmpty) return null;

  final name = state._nameController.text.trim();
  if (name.isEmpty) return null;

  return (appSkillId: appSkillId, apiKey: apiKey, name: name);
}

Future<void> _createAppSkillCredential(
  _ServiceConnectionCreateScreenState state,
  _AppSkillCredentialSaveData data,
) async {
  final operations = await state.ref.read(
    serviceConnectionOperationsProvider(state.widget.workspaceId).future,
  );
  final _ = await operations.createAppSkillCredential(
    workspaceId: state.widget.workspaceId,
    appSkillServiceId: data.appSkillId,
    name: data.name,
    apiKey: data.apiKey,
  );
}

void _logAppSkillCredentialSaveFailure(
  _AppSkillCredentialFailureLogRequest request,
) {
  _logger.severe(
    'debug:app skill credential save failed '
    'workspace=${request.state.widget.workspaceId} '
    'appSkillId=${request.data.appSkillId} '
    'nameLength=${request.data.name.length}',
    request.error,
    request.stackTrace,
  );
}

Future<void> _saveSkillCredential(
  _ServiceConnectionCreateScreenState state,
) async {
  final definitionId = _skillCredentialDefinitionId(state);
  if (definitionId == null) return;

  state.updateState(() => state._isSaving = true);
  await _saveSkillCredentialRequest(state, definitionId);
}

Future<void> _saveSkillCredentialRequest(
  _ServiceConnectionCreateScreenState state,
  String definitionId,
) async {
  try {
    await _executeSkillCredentialSave(state, definitionId);
  } on Object catch (error, stackTrace) {
    _logSkillCredentialSaveFailure((
      state: state,
      definitionId: definitionId,
      error: error,
      stackTrace: stackTrace,
    ));
    _showCredentialSaveError(state);
  } finally {
    _finishSaving(state);
  }
}

Future<void> _executeSkillCredentialSave(
  _ServiceConnectionCreateScreenState state,
  String definitionId,
) async {
  final attributes = _attributeValues(state);
  await _createAndLogSkillCredential(state, definitionId, attributes);
  await _closeAfterSave(
    state,
    refreshServiceConnections: false,
    resetModelMutation: false,
  );
}

Future<SkillCredentialEntity> _createAndLogSkillCredential(
  _ServiceConnectionCreateScreenState state,
  String definitionId,
  Map<String, String> attributes,
) async {
  _logSkillCredentialSaveStart(state, definitionId, attributes);
  final credential = await _createSkillCredential(
    state,
    definitionId,
    attributes,
  );
  _logSkillCredentialSaveSuccess((
    state: state,
    definitionId: definitionId,
    credential: credential,
    attributes: attributes,
  ));
  return credential;
}

String? _skillCredentialDefinitionId(
  _ServiceConnectionCreateScreenState state,
) {
  if (state._isSaving) {
    _logSkillCredentialSaveIgnored(state);

    return null;
  }

  final definitionId = state._definitionId;
  if (definitionId == null) {
    _logSkillCredentialSaveBlocked(state);

    return null;
  }

  return definitionId;
}

void _logSkillCredentialSaveIgnored(_ServiceConnectionCreateScreenState state) {
  _logger.info(
    'debug:skill credential save ignored workspace=${state.widget.workspaceId} '
    'reason=already_saving type=${state._type.name}',
  );
}

void _logSkillCredentialSaveBlocked(_ServiceConnectionCreateScreenState state) {
  _logger.warning(
    'debug:skill credential save blocked workspace=${state.widget.workspaceId} '
    'reason=missing_definition type=${state._type.name}',
  );
}

Map<String, String> _attributeValues(
  _ServiceConnectionCreateScreenState state,
) => state._attributeControllers.map(
  (key, controller) => MapEntry(key, controller.text),
);

Future<SkillCredentialEntity> _createSkillCredential(
  _ServiceConnectionCreateScreenState state,
  String definitionId,
  Map<String, String> attributes,
) {
  return state.ref
      .read(skillCredentialOperationsProvider(state.widget.workspaceId))
      .create(
        state.widget.workspaceId,
        .new(
          credentialDefinitionId: definitionId,
          name: state._nameController.text.trim(),
          attributes: attributes,
        ),
      );
}

void _logSkillCredentialSaveStart(
  _ServiceConnectionCreateScreenState state,
  String definitionId,
  Map<String, String> attributes,
) {
  _logger.info(
    'debug:skill credential save start workspace=${state.widget.workspaceId} '
    'definitionId=$definitionId type=${state._type.name} '
    'nameLength=${state._nameController.text.trim().length} '
    'attributes=${_describeAttributes(attributes)}',
  );
}

void _logSkillCredentialSaveSuccess(_SkillCredentialSuccessLogRequest request) {
  _logger.info(
    'debug:skill credential save success '
    'workspace=${request.state.widget.workspaceId} '
    'definitionId=${request.definitionId} '
    'credentialId=${request.credential.id} '
    'attributeKeys=${request.attributes.keys.join(',')}',
  );
}

void _logSkillCredentialSaveFailure(_SkillCredentialFailureLogRequest request) {
  _logger.severe(
    'debug:skill credential save failed '
    'workspace=${request.state.widget.workspaceId} '
    'definitionId=${request.definitionId} type=${request.state._type.name} '
    'nameLength=${request.state._nameController.text.trim().length} '
    'attributeKeys=${request.state._attributeControllers.keys.join(',')}',
    request.error,
    request.stackTrace,
  );
}

void _showCredentialSaveError(_ServiceConnectionCreateScreenState state) {
  if (!state.mounted) return;
  final _ = AuraSnackBars.show(
    context: state.context,
    content: Text(
      LocaleKeys.skill_credentials_save_error.tr(context: state.context),
    ),
    variant: .error,
  );
}

void _finishSaving(_ServiceConnectionCreateScreenState state) {
  if (state.mounted) state.updateState(() => state._isSaving = false);
}

Future<void> _closeAfterSave(
  _ServiceConnectionCreateScreenState state, {
  bool refreshServiceConnections = true,
  bool resetModelMutation = true,
}) async {
  if (!state.mounted) return;
  _resetAfterSave(state, refreshServiceConnections, resetModelMutation);
  if (await Navigator.of(state.context).maybePop(true)) return;
  if (!state.mounted) return;
  _goToServiceConnections(state);
}

void _resetAfterSave(
  _ServiceConnectionCreateScreenState state,
  bool refreshServiceConnections,
  bool resetModelMutation,
) {
  if (resetModelMutation) {
    addCredentialsModelMutationProvider.reset(state.ref);
  }
  if (refreshServiceConnections) {
    state.ref.invalidate(serviceConnectionsProvider(state.widget.workspaceId));
  }
}

void _goToServiceConnections(_ServiceConnectionCreateScreenState state) {
  state.context.go(
    '/workspaces/${state.widget.workspaceId}/more/service-connections',
  );
}

void _onTypeChanged(
  _ServiceConnectionCreateScreenState state,
  ServiceConnectionCreateType? value,
) {
  if (value == null) return;
  state.updateState(() {
    state._type = value;
    state._definitionId = null;
    state._appSkillId = null;
    _resetAttributeControllers(state);
  });
}

void _onDefinitionChanged(
  _ServiceConnectionCreateScreenState state,
  String? value,
) {
  state.updateState(() {
    state._definitionId = value;
    _resetAttributeControllers(state);
  });
}

void _resetAttributeControllers(_ServiceConnectionCreateScreenState state) {
  for (final controller in state._attributeControllers.values) {
    controller.dispose();
  }
  state._attributeControllers.clear();
}

String _describeAttributes(Map<String, String> attributes) => attributes.entries
    .map(
      (entry) =>
          '${entry.key}:length=${entry.value.length},'
          'empty=${entry.value.isEmpty}',
    )
    .join('|');

class const _ServiceConnectionCreateForm({
  required final String workspaceId,
  required final ServiceConnectionCreateType type,
  required final String? selectedDefinitionId,
  required final String? selectedAppSkillId,
  required final TextEditingController nameController,
  required final Map<String, TextEditingController> attributeControllers,
  required final TextEditingController apiKeyController,
  required final bool isSaving,
  required final ValueChanged<ServiceConnectionCreateType?> onTypeChanged,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String?> onDefinitionChanged,
  required final ValueChanged<String?> onAppSkillChanged,
  required final ValueChanged<String> onApiKeyChanged,
  required final VoidCallback onModelProviderCreated,
  required final VoidCallback onSkillCredentialSave,
  required final VoidCallback onAppSkillCredentialSave,
}) {
  new fromState(_ServiceConnectionCreateScreenState state)
    : this(
        workspaceId: state.widget.workspaceId,
        type: state._type,
        selectedDefinitionId: state._definitionId,
        selectedAppSkillId: state._appSkillId,
        nameController: state._nameController,
        attributeControllers: state._attributeControllers,
        apiKeyController: state._apiKeyController,
        isSaving: state._isSaving,
        onTypeChanged: (value) => _onTypeChanged(state, value),
        onNameChanged: (value) => _handleFieldChanged(state, value),
        onDefinitionChanged: (value) => _onDefinitionChanged(state, value),
        onAppSkillChanged: (value) => _handleAppSkillChanged(state, value),
        onApiKeyChanged: (value) => _handleFieldChanged(state, value),
        onModelProviderCreated: () => _handleModelProviderCreated(state),
        onSkillCredentialSave: () => _handleSkillCredentialSave(state),
        onAppSkillCredentialSave: () => _handleAppSkillCredentialSave(state),
      );

  bool canSaveAppSkillCredential() =>
      selectedAppSkillId != null &&
      nameController.text.trim().isNotEmpty &&
      apiKeyController.text.trim().isNotEmpty;
}

class const _ServiceConnectionCreateView({
  required final _ServiceConnectionCreateForm form,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: _ServiceConnectionCreateBody(form: form),
      appBar: const _ServiceConnectionCreateAppBar(),
    );
  }
}

class const _ServiceConnectionCreateAppBar()
    extends StatelessWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AuraAppBar(
      title: const TextLocale(LocaleKeys.service_connections_create_title),
      leading: AuraIconButton(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class const _ServiceConnectionCreateBody({
  required final _ServiceConnectionCreateForm form,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _CreateTypeSelectorPadding(form: form),
        Expanded(child: _CreateConnectionTypeContent(form: form)),
      ],
    );
  }
}

class const _CreateTypeSelectorPadding({
  required final _ServiceConnectionCreateForm form,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: _TypeSelector(value: form.type, onChanged: form.onTypeChanged),
    );
  }
}

class const _CreateConnectionTypeContent({
  required final _ServiceConnectionCreateForm form,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return switch (form.type) {
      .modelProvider => _ModelProviderCreateContent(form: form),
      .skillCredential => _SkillCredentialCreateContent(form: form),
      .appSkillCredential => _AppSkillCredentialCreateContent(form: form),
    };
  }
}

class const _ModelProviderCreateContent({
  required final _ServiceConnectionCreateForm form,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: AddModelProviderWidget(
        workspaceId: form.workspaceId,
        onCreated: form.onModelProviderCreated,
        showHeader: false,
      ),
    );
  }
}

class const _SkillCredentialCreateContent({
  required final _ServiceConnectionCreateForm form,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CredentialForm(
      workspaceId: form.workspaceId,
      selectedDefinitionId: form.selectedDefinitionId,
      nameController: form.nameController,
      attributeControllers: form.attributeControllers,
      isSaving: form.isSaving,
      onNameChanged: form.onNameChanged,
      onDefinitionChanged: form.onDefinitionChanged,
      onSave: form.onSkillCredentialSave,
    );
  }
}

class const _AppSkillCredentialCreateContent({
  required final _ServiceConnectionCreateForm form,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _AppSkillCredentialForm(
      selectedAppSkillId: form.selectedAppSkillId,
      nameController: form.nameController,
      apiKeyController: form.apiKeyController,
      isSaving: form.isSaving,
      onNameChanged: form.onNameChanged,
      onAppSkillChanged: form.onAppSkillChanged,
      onApiKeyChanged: form.onApiKeyChanged,
      onSave: form.onAppSkillCredentialSave,
      canSave: form.canSaveAppSkillCredential(),
    );
  }
}

enum ServiceConnectionCreateType {
  modelProvider,
  skillCredential,
  appSkillCredential,
}

extension ServiceConnectionCreateTypeQuery on ServiceConnectionCreateType {
  static ServiceConnectionCreateType? fromQueryValue(String? value) {
    return switch (value) {
      'modelProvider' => ServiceConnectionCreateType.modelProvider,
      'skillCredential' => ServiceConnectionCreateType.skillCredential,
      'appSkillCredential' => ServiceConnectionCreateType.appSkillCredential,
      _ => null,
    };
  }
}

class const _TypeSelector({
  required final ServiceConnectionCreateType value,
  required final ValueChanged<ServiceConnectionCreateType?> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraChoicePicker<ServiceConnectionCreateType>(
      options: _serviceConnectionCreateTypeOptions(context),
      value: [value],
      onChanged: _handleChanged,
      label: Text(
        LocaleKeys.service_connections_create_type_label.tr(context: context),
      ),
    );
  }

  void _handleChanged(List<ServiceConnectionCreateType> values) {
    final selected = values.firstOrNull;
    if (selected == null) return;
    onChanged(selected);
  }
}

List<AuraChoiceOption<ServiceConnectionCreateType>>
_serviceConnectionCreateTypeOptions(BuildContext context) {
  return [
    for (final type in ServiceConnectionCreateType.values)
      AuraChoiceOption(
        value: type,
        label: Text(_createTypeLabel(context, type)),
      ),
  ];
}

String _createTypeLabel(
  BuildContext context,
  ServiceConnectionCreateType type,
) {
  final key = switch (type) {
    .modelProvider => LocaleKeys.service_connections_type_model_provider,
    .skillCredential => LocaleKeys.service_connections_type_skill_credential,
    .appSkillCredential =>
      LocaleKeys.service_connections_type_app_skill_credential,
  };

  return key.tr(context: context);
}

List<SkillCredentialDefinitionEntity>? _credentialDefinitions(
  AsyncValue<List<SkillCredentialDefinitionEntity>> value,
) => switch (value) {
  AsyncData(:final value) => value,
  AsyncLoading(value: final value?, hasValue: true) => value,
  AsyncLoading() => null,
  AsyncError() => null,
};

class const _CredentialForm({
  required final String workspaceId,
  required final String? selectedDefinitionId,
  required final TextEditingController nameController,
  required final Map<String, TextEditingController> attributeControllers,
  required final bool isSaving,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String?> onDefinitionChanged,
  required final VoidCallback onSave,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitions = _credentialDefinitions(
      ref.watch(skillCredentialDefinitionsProvider(workspaceId)),
    );

    if (definitions == null) {
      return const Center(child: AuraSpinner());
    }

    return _CredentialFormContent.fromCredentialForm(this, definitions);
  }
}

class const _AppSkillCredentialForm({
  required final String? selectedAppSkillId,
  required final TextEditingController nameController,
  required final TextEditingController apiKeyController,
  required final bool isSaving,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String?> onAppSkillChanged,
  required final ValueChanged<String> onApiKeyChanged,
  required final VoidCallback onSave,
  required final bool canSave,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [_AppSkillCredentialCard._fromForm(this)],
    );
  }
}

class const _AppSkillCredentialCard({
  required final String? selectedAppSkillId,
  required final TextEditingController nameController,
  required final TextEditingController apiKeyController,
  required final bool isSaving,
  required final bool canSave,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String?> onAppSkillChanged,
  required final ValueChanged<String> onApiKeyChanged,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  new _fromForm(_AppSkillCredentialForm form)
    : this(
        selectedAppSkillId: form.selectedAppSkillId,
        nameController: form.nameController,
        apiKeyController: form.apiKeyController,
        isSaving: form.isSaving,
        canSave: form.canSave,
        onNameChanged: form.onNameChanged,
        onAppSkillChanged: form.onAppSkillChanged,
        onApiKeyChanged: form.onApiKeyChanged,
        onSave: form.onSave,
      );

  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: AuraColumn(
        children: [
          _AppSkillCredentialSelector.fromCard(this),
          _CredentialNameField._fromAppSkillCard(this),
          _AppSkillCredentialValueField.fromCard(this),
          _CredentialSaveAction._fromAppSkillCard(this),
        ],
        spacing: .md,
        crossAxisAlignment: .start,
      ),
    );
  }
}

class const _AppSkillCredentialSelector({
  required final String? value,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  new fromCard(_AppSkillCredentialCard card)
    : this(value: card.selectedAppSkillId, onChanged: card.onAppSkillChanged);

  @override
  Widget build(BuildContext context) {
    return AuraDropdownSelector<String>(
      options: _appSkillCredentialOptions().map(_option).toList(),
      value: value,
      onChanged: onChanged,
      label: Text(
        LocaleKeys.service_connections_create_app_skill_label.tr(
          context: context,
        ),
      ),
    );
  }

  AuraDropdownOption<String> _option(AppSkillDefinition skill) =>
      AuraDropdownOption(value: skill.identifier, child: Text(skill.title));
}

class const _CredentialNameField({
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  new _fromAppSkillCard(_AppSkillCredentialCard card)
    : this(controller: card.nameController, onChanged: card.onNameChanged);

  new _fromCredentialCard(_CredentialFormCard card)
    : this(controller: card.nameController, onChanged: card.onNameChanged);

  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: controller,
      label: Text(LocaleKeys.skill_credentials_name_label.tr(context: context)),
      onChanged: onChanged,
    );
  }
}

class const _AppSkillCredentialValueField({
  required final String? appSkillId,
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
}) extends StatelessWidget {
  new fromCard(_AppSkillCredentialCard card)
    : this(
        appSkillId: card.selectedAppSkillId,
        controller: card.apiKeyController,
        onChanged: card.onApiKeyChanged,
      );

  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: controller,
      label: Text(_credentialValueLabel(context, appSkillId)),
      keyboardType: .visiblePassword,
      obscureText: true,
      onChanged: onChanged,
    );
  }
}

class const _CredentialSaveAction({
  required final VoidCallback onSave,
  required final bool isSaving,
  required final bool disabled,
}) extends StatelessWidget {
  new _fromAppSkillCard(_AppSkillCredentialCard card)
    : this(
        onSave: card.onSave,
        isSaving: card.isSaving,
        disabled: !card.canSave,
      );

  new _fromCredentialCard(_CredentialFormCard card)
    : this(
        onSave: card.onSave,
        isSaving: card.isSaving,
        disabled: card.nameController.text.trim().isEmpty,
      );

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: AuraButton(
        onPressed: onSave,
        child: const TextLocale(LocaleKeys.common_save),
        isLoading: isSaving,
        disabled: isSaving || disabled,
      ),
    );
  }
}

List<AppSkillDefinition> _appSkillCredentialOptions() {
  return serviceSkillDefinitions.where(_canCreateAppSkillCredential).toList();
}

AppSkillDefinition? _appSkillCredentialOption(String? appSkillId) {
  if (appSkillId == null) return null;

  return _appSkillCredentialOptions()
      .where((skill) => skill.identifier == appSkillId)
      .firstOrNull;
}

bool _canCreateAppSkillCredential(AppSkillDefinition skill) {
  if (skill.compatibleModelProviderIds.isNotEmpty) return false;

  return skill.requiresCredential ||
      skill.nativeTools.any((tool) => tool.requiresCredential);
}

String _credentialValueLabel(BuildContext context, String? appSkillId) {
  if (appSkillId == 'searxng') {
    return LocaleKeys.service_connections_create_base_url_label.tr(
      context: context,
    );
  }

  return LocaleKeys.service_connections_create_api_key_label.tr(
    context: context,
  );
}

class const _CredentialFormContent({
  required final List<SkillCredentialDefinitionEntity> definitions,
  required final String? selectedDefinitionId,
  required final TextEditingController nameController,
  required final Map<String, TextEditingController> attributeControllers,
  required final bool isSaving,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String?> onDefinitionChanged,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  new fromCredentialForm(
    _CredentialForm form,
    List<SkillCredentialDefinitionEntity> definitions,
  ) : this(
        definitions: definitions,
        selectedDefinitionId: form.selectedDefinitionId,
        nameController: form.nameController,
        attributeControllers: form.attributeControllers,
        isSaving: form.isSaving,
        onNameChanged: form.onNameChanged,
        onDefinitionChanged: form.onDefinitionChanged,
        onSave: form.onSave,
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [_CredentialFormCard.fromContent(this)],
    );
  }
}

class const _CredentialFormCard({
  required final List<SkillCredentialDefinitionEntity> definitions,
  required final String? selectedDefinitionId,
  required final TextEditingController nameController,
  required final Map<String, TextEditingController> attributeControllers,
  required final bool isSaving,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String?> onDefinitionChanged,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  new fromContent(_CredentialFormContent content)
    : this(
        definitions: content.definitions,
        selectedDefinitionId: content.selectedDefinitionId,
        nameController: content.nameController,
        attributeControllers: content.attributeControllers,
        isSaving: content.isSaving,
        onNameChanged: content.onNameChanged,
        onDefinitionChanged: content.onDefinitionChanged,
        onSave: content.onSave,
      );

  @override
  Widget build(BuildContext context) {
    final selectedDefinition = definitions
        .where((definition) => definition.id == selectedDefinitionId)
        .firstOrNull;

    return _CredentialFormCardLayout(
      card: this,
      selectedDefinition: selectedDefinition,
    );
  }
}

class const _CredentialFormCardLayout({
  required final _CredentialFormCard card,
  required final SkillCredentialDefinitionEntity? selectedDefinition,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: AuraColumn(
        children: [
          _DefinitionSelector._fromCard(card),
          _CredentialFormDetails(
            card: card,
            selectedDefinition: selectedDefinition,
          ),
        ],
        spacing: .md,
        crossAxisAlignment: .start,
      ),
    );
  }
}

class const _CredentialFormDetails({
  required final _CredentialFormCard card,
  required final SkillCredentialDefinitionEntity? selectedDefinition,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final definition = selectedDefinition;
    if (definition == null) {
      return const _NoCredentialDefinitionMessage();
    }

    return _CredentialFormFieldsColumn(card: card, definition: definition);
  }
}

class const _NoCredentialDefinitionMessage() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(
      child: Text(
        LocaleKeys.skill_credentials_no_definitions.tr(context: context),
      ),
    );
  }
}

class const _CredentialFormFieldsColumn({
  required final _CredentialFormCard card,
  required final SkillCredentialDefinitionEntity definition,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _CredentialNameField._fromCredentialCard(card),
        _CredentialAttributesFields._fromCredentialCard(card, definition),
        _CredentialSaveAction._fromCredentialCard(card),
      ],
      mainAxisSize: .min,
      spacing: .md,
      crossAxisAlignment: .start,
    );
  }
}

class const _DefinitionSelector({
  required final List<SkillCredentialDefinitionEntity> definitions,
  required final String? selectedDefinitionId,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  new _fromCard(_CredentialFormCard card)
    : this(
        definitions: card.definitions,
        selectedDefinitionId: card.selectedDefinitionId,
        onChanged: card.onDefinitionChanged,
      );

  @override
  Widget build(BuildContext context) {
    return AuraDropdownSelector<String>(
      options: definitions.map(_option).toList(),
      value: selectedDefinitionId,
      onChanged: onChanged,
      label: Text(
        LocaleKeys.skill_credentials_definition_label.tr(context: context),
      ),
    );
  }

  AuraDropdownOption<String> _option(
    SkillCredentialDefinitionEntity definition,
  ) => AuraDropdownOption(value: definition.id, child: Text(definition.title));
}

class const _CredentialAttributesFields({
  required final SkillCredentialDefinitionEntity definition,
  required final Map<String, TextEditingController> controllers,
}) extends StatelessWidget {
  new _fromCredentialCard(
    _CredentialFormCard card,
    SkillCredentialDefinitionEntity definition,
  ) : this(definition: definition, controllers: card.attributeControllers);

  @override
  Widget build(BuildContext context) {
    final attributes = SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );

    return _CredentialAttributeFieldsColumn(
      attributes: attributes,
      controllers: controllers,
    );
  }
}

class const _CredentialAttributeFieldsColumn({
  required final Map<String, SkillCredentialAttributeDefinition> attributes,
  required final Map<String, TextEditingController> controllers,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      for (final entry in attributes.entries)
        _CredentialAttributeField(
          entry: entry,
          controller: _credentialAttributeController(controllers, entry.key),
        ),
    ],
    spacing: .md,
    crossAxisAlignment: .start,
  );
}

TextEditingController _credentialAttributeController(
  Map<String, TextEditingController> controllers,
  String key,
) => controllers.putIfAbsent(key, TextEditingController.new);

class const _CredentialAttributeField({
  required final MapEntry<String, SkillCredentialAttributeDefinition> entry,
  required final TextEditingController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final attribute = entry.value;

    return AuraInput(
      controller: controller,
      label: Text(entry.key),
      hint: _hint(attribute.description),
      isRequired: !attribute.optional,
      keyboardType: _keyboardType(attribute.secret),
      obscureText: attribute.secret,
    );
  }

  Text? _hint(String description) =>
      description.isEmpty ? null : Text(description);

  TextInputType _keyboardType(bool secret) => secret ? .visiblePassword : .text;
}
