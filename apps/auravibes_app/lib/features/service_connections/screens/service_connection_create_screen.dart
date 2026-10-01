// Required: Feature widgets keep closely related private widgets together.

import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/chats/widgets/chat_readiness_summary.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/widgets/add_model_provider_widget.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_operations.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/task_return.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/bottom_padding.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/experimental/mutation.dart';

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
  final String? returnPath,
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
  final _exitGuard = DraftExitGuard();
  String _initialSnapshot = '';
  bool _saved = false;
  bool _handoff = false;
  bool _isSaving = false;

  String get _snapshot => jsonEncode({
    'name': _nameController.text,
    'type': _type.name,
    'definition': _definitionId,
    'appSkill': _appSkillId,
    'attributes': {
      for (final entry in _attributeControllers.entries)
        if (entry.value.text.isNotEmpty) entry.key: entry.value.text,
    },
  });

  bool get _isDirty =>
      !_saved &&
      (_snapshot != _initialSnapshot ||
          _type == .modelProvider &&
              ref
                  .read(addModelProviderStateProvider(widget.workspaceId))
                  .hasUnsavedChanges);
  bool get _isBusy =>
      _isSaving ||
      _type == .modelProvider &&
          ref.read(addCredentialsModelMutationProvider) is MutationPending;

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
    _initialSnapshot = _snapshot;
  }

  @override
  void dispose() {
    _disposeCreateState(this);
    super.dispose();
  }

  void updateState(VoidCallback callback) => setState(callback);

  @override
  Widget build(BuildContext context) {
    _exitGuard.bind(
      isDirty: () => _isDirty,
      isSaving: () => _isBusy,
      preferReturn:
          TaskReturn.validate(
            widget.returnPath,
            workspaceId: widget.workspaceId,
          ) !=
          null,
      onReturn: (context) => context.go(
        TaskReturn.validate(
              widget.returnPath,
              workspaceId: widget.workspaceId,
            ) ??
            ServiceConnectionsRoute(workspaceId: widget.workspaceId).location,
      ),
    );

    return DraftExitScope(
      guard: _exitGuard,
      child: _handoff
          ? AuraScreen(
              child: AuraColumn(
                children: [
                  const TextLocale('chat_readiness.saved'),
                  ChatReadinessSummary(
                    workspaceId: widget.workspaceId,
                    isSetupHandoff: true,
                  ),
                  AuraButton(
                    onPressed: () => unawaited(_closeAfterSave(this)),
                    child: const TextLocale('chat_readiness.continue_chat'),
                  ),
                ],
              ),
              appBar: const AuraAppBarWithDrawer(
                title: TextLocale('chat_readiness.saved'),
              ),
            )
          : _ServiceConnectionCreateView(form: .fromState(this)),
    );
  }
}

void _initializeCreateState(_ServiceConnectionCreateScreenState state) {
  if (state.widget.initialAppSkillId != null) {
    state._type = .appSkillCredential;
  } else if (state.widget.initialCredentialDefinitionId != null) {
    state._type = .skillCredential;
  } else {
    state._type = state.widget.initialType ?? .modelProvider;
  }
  state._definitionId = state.widget.initialCredentialDefinitionId;
  state._appSkillId = state.widget.initialAppSkillId;
}

Future<void> _createCredentialType(
  _ServiceConnectionCreateScreenState state,
) async {
  final created = await SkillCredentialDefinitionCreateRoute(
    workspaceId: state.widget.workspaceId,
    returnCreated: true,
  ).push<SkillCredentialDefinitionEntity>(state.context);
  if (!state.mounted ||
      created == null ||
      created.workspaceId != state.widget.workspaceId) {
    return;
  }
  state.ref.invalidate(
    skillCredentialDefinitionsProvider(state.widget.workspaceId),
  );
  _onDefinitionChanged(state, created.id);
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
  state.updateState(() {
    state._appSkillId = value;
    _resetAttributeControllers(state);
  });
}

void _handleModelProviderCreated(_ServiceConnectionCreateScreenState state) {
  if (TaskReturn.validate(
        state.widget.returnPath,
        workspaceId: state.widget.workspaceId,
      ) ==
      null) {
    unawaited(_closeAfterSave(state));

    return;
  }
  _resetAfterSave(state, true, true);
  state.updateState(() {
    state
      .._saved = true
      .._handoff = true;
  });
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
  final _ = await _createAndLogSkillCredential(state, definitionId, attributes);
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
  state
    .._saved = true
    .._isSaving = false;
  _resetAfterSave(state, refreshServiceConnections, resetModelMutation);
  final destination = TaskReturn.validate(
    state.widget.returnPath,
    workspaceId: state.widget.workspaceId,
  );
  if (state._handoff && destination != null) {
    state.context.go(destination);

    return;
  }
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
  if (value == null || value == state._type) return;
  unawaited(_replaceCreateType(state, value));
}

Future<void> _replaceCreateType(
  _ServiceConnectionCreateScreenState state,
  ServiceConnectionCreateType value,
) async {
  if (!await state._exitGuard.canExit(state.context) || !state.mounted) return;
  state.ref
      .read(addModelProviderStateProvider(state.widget.workspaceId).notifier)
      .reset();
  state.updateState(() {
    state
      .._type = value
      .._definitionId = null
      .._appSkillId = null;
    _resetAttributeControllers(state);
  });
  state._exitGuard.releaseApproval();
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
  required final DraftExitGuard routeExitGuard,
  required final bool contextual,
  required final bool fixedDefinition,
  required final bool fixedAppSkill,
  required final VoidCallback onCreateDefinition,
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
        contextual:
            state.widget.initialType != null ||
            state.widget.initialCredentialDefinitionId != null ||
            state.widget.initialAppSkillId != null,
        fixedDefinition: state.widget.initialCredentialDefinitionId != null,
        fixedAppSkill: state.widget.initialAppSkillId != null,
        onCreateDefinition: () => unawaited(_createCredentialType(state)),
        routeExitGuard: state._exitGuard,
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
      _appSkillCredentialOption(selectedAppSkillId) != null &&
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
      appBar: _ServiceConnectionCreateAppBar(form: form),
    );
  }
}

class const _ServiceConnectionCreateAppBar({
  required final _ServiceConnectionCreateForm form,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AuraAppBarWithDrawer(
      title: TextLocale(
        form.contextual
            ? switch (form.type) {
                .modelProvider => 'connection_setup.connect_ai',
                .skillCredential ||
                .appSkillCredential => 'connection_setup.add_access',
              }
            : LocaleKeys.service_connections_create_title,
      ),
      leading: AuraIconButton(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.of(context).maybePop(),
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
        if (!form.contextual) _CreateTypeSelectorPadding(form: form),
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
        routeExitGuard: form.routeExitGuard,
        onCreated: form.onModelProviderCreated,
        showHeader: false,
      ),
    );
  }
}

class const _SkillCredentialCreateContent({
  required final _ServiceConnectionCreateForm form,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = skillCredentialDefinitionsProvider(form.workspaceId);
    final result = ref.watch(provider);
    if (result case AsyncError()) {
      return AuraColumn(
        children: [
          const TextLocale('connection_setup.types_load_error'),
          AuraButton(
            onPressed: () => ref.invalidate(provider),
            child: const TextLocale(LocaleKeys.route_state_retry),
          ),
          AuraButton(
            onPressed: () => unawaited(form.routeExitGuard.pop(context)),
            child: const TextLocale('connection_setup.return_connections'),
          ),
        ],
      );
    }
    final definitions = _credentialDefinitions(result);
    if (definitions == null) return const Center(child: AuraSpinner());

    return ListView(
      padding: const EdgeInsets.all(12)
          .copyWith(bottom: BottomPadding.of(context, minimum: 12)),
      children: [
        _CredentialFormCard(
          definitions: definitions,
          selectedDefinitionId: form.selectedDefinitionId,
          nameController: form.nameController,
          attributeControllers: form.attributeControllers,
          isSaving: form.isSaving,
          onNameChanged: form.onNameChanged,
          onDefinitionChanged: form.onDefinitionChanged,
          onSave: form.onSkillCredentialSave,
          fixedDefinition: form.fixedDefinition,
        ),
        if (!form.fixedDefinition)
          AuraButton(
            onPressed: form.onCreateDefinition,
            child: const TextLocale('connection_setup.create_type'),
            disabled: form.isSaving,
          ),
        if (form.fixedDefinition &&
            !definitions.any((item) => item.id == form.selectedDefinitionId))
          AuraColumn(
            children: [
              const TextLocale('connection_setup.required_type_missing'),
              AuraButton(
                onPressed: () => ref.invalidate(provider),
                child: const TextLocale(LocaleKeys.route_state_retry),
              ),
              AuraButton(
                onPressed: () => unawaited(form.routeExitGuard.pop(context)),
                child: const TextLocale('connection_setup.return_task'),
              ),
            ],
          ),
      ],
      keyboardDismissBehavior: .onDrag,
    );
  }
}

class const _AppSkillCredentialCreateContent({
  required final _ServiceConnectionCreateForm form,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (form.fixedAppSkill &&
        _appSkillCredentialOption(form.selectedAppSkillId) == null) {
      return AuraColumn(
        children: [
          const TextLocale('connection_setup.required_service_missing'),
          AuraButton(
            onPressed: () => unawaited(form.routeExitGuard.pop(context)),
            child: const TextLocale('connection_setup.return_task'),
          ),
        ],
      );
    }

    return _AppSkillCredentialForm(
      selectedAppSkillId: form.selectedAppSkillId,
      fixedAppSkill: form.fixedAppSkill,
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

class const _AppSkillCredentialForm({
  required final String? selectedAppSkillId,
  required final bool fixedAppSkill,
  required final TextEditingController nameController,
  required final TextEditingController apiKeyController,
  required final bool isSaving,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String?> onAppSkillChanged,
  required final ValueChanged<String> onApiKeyChanged,
  required final VoidCallback onSave,
  required final bool canSave,
}) extends StatelessWidget {
  static const _contentPadding = 12.0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(
        _contentPadding,
      ).copyWith(bottom: BottomPadding.of(context, minimum: _contentPadding)),
      children: [_AppSkillCredentialCard._fromForm(this)],
      keyboardDismissBehavior: .onDrag,
    );
  }
}

class const _AppSkillCredentialCard({
  required final String? selectedAppSkillId,
  required final bool fixedAppSkill,
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
        fixedAppSkill: form.fixedAppSkill,
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
          if (fixedAppSkill)
            Text(_appSkillCredentialOption(selectedAppSkillId)?.title ?? '')
          else
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
  required final TextInputAction textInputAction,
  required final ValueChanged<String>? onSubmitted,
}) extends StatelessWidget {
  new _fromAppSkillCard(_AppSkillCredentialCard card)
    : this(
        controller: card.nameController,
        onChanged: card.onNameChanged,
        textInputAction: .next,
        onSubmitted: null,
      );

  new _fromCredentialCard(
    _CredentialFormCard card, {
    required bool hasAttributes,
  }) : this(
         controller: card.nameController,
         onChanged: card.onNameChanged,
         textInputAction: hasAttributes ? .next : .done,
         onSubmitted:
             hasAttributes ||
                 card.isSaving ||
                 card.nameController.text.trim().isEmpty
             ? null
             : (_) => card.onSave(),
       );

  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: controller,
      label: Text(LocaleKeys.skill_credentials_name_label.tr(context: context)),
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

class const _AppSkillCredentialValueField({
  required final String? appSkillId,
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
  required final VoidCallback onSave,
  required final bool canSubmit,
}) extends StatelessWidget {
  new fromCard(_AppSkillCredentialCard card)
    : this(
        appSkillId: card.selectedAppSkillId,
        controller: card.apiKeyController,
        onChanged: card.onApiKeyChanged,
        onSave: card.onSave,
        canSubmit: card.canSave && !card.isSaving,
      );

  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: controller,
      label: Text(_credentialValueLabel(context, appSkillId)),
      keyboardType: .visiblePassword,
      textInputAction: .done,
      obscureText: true,
      onChanged: onChanged,
      onSubmitted: canSubmit ? (_) => onSave() : null,
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
      skill.tools.any((tool) => tool.requiresCredential);
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

class const _CredentialFormCard({
  required final List<SkillCredentialDefinitionEntity> definitions,
  required final String? selectedDefinitionId,
  required final TextEditingController nameController,
  required final Map<String, TextEditingController> attributeControllers,
  required final bool isSaving,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String?> onDefinitionChanged,
  required final VoidCallback onSave,
  required final bool fixedDefinition,
}) extends StatelessWidget {
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
          _CredentialNameField._fromCredentialCard(card, hasAttributes: true),
          if (!card.fixedDefinition) _DefinitionSelector._fromCard(card),
          if (selectedDefinition case final definition?
              when card.fixedDefinition)
            Text(definition.title),
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
      return card.fixedDefinition
          ? const SizedBox.shrink()
          : const _NoCredentialDefinitionMessage();
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
      children: _CredentialFormFieldChildren(
        card: card,
        definition: definition,
      ).values,
      spacing: .md,
      crossAxisAlignment: .start,
      mainAxisSize: .min,
    );
  }
}

class _CredentialFormFieldChildren {
  new({
    required _CredentialFormCard card,
    required SkillCredentialDefinitionEntity definition,
  }) : values = [
         _CredentialAttributesFields._fromCredentialCard(
           card,
           definition,
           onSave: card.onSave,
           canSubmit:
               !card.isSaving && card.nameController.text.trim().isNotEmpty,
         ),
         _CredentialSaveAction._fromCredentialCard(card),
       ];

  final List<Widget> values;
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
  required final VoidCallback onSave,
  required final bool canSubmit,
}) extends StatelessWidget {
  new _fromCredentialCard(
    _CredentialFormCard card,
    SkillCredentialDefinitionEntity definition, {
    required VoidCallback onSave,
    required bool canSubmit,
  }) : this(
         definition: definition,
         controllers: card.attributeControllers,
         onSave: onSave,
         canSubmit: canSubmit,
       );

  @override
  Widget build(BuildContext context) {
    final attributes = SkillCredentialAttributeDefinition.parseMap(
      definition.attributesJson,
    );

    return _CredentialAttributeFieldsColumn(
      attributes: attributes,
      controllers: controllers,
      onSave: onSave,
      canSubmit: canSubmit,
    );
  }
}

class const _CredentialAttributeFieldsColumn({
  required final Map<String, SkillCredentialAttributeDefinition> attributes,
  required final Map<String, TextEditingController> controllers,
  required final VoidCallback onSave,
  required final bool canSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _CredentialAttributeFieldColumn(
    attributes: attributes,
    controllers: controllers,
    onSave: onSave,
    canSubmit: canSubmit,
  );
}

class const _CredentialAttributeFieldColumn({
  required final Map<String, SkillCredentialAttributeDefinition> attributes,
  required final Map<String, TextEditingController> controllers,
  required final VoidCallback onSave,
  required final bool canSubmit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lastKey = attributes.keys.lastOrNull;

    return AuraColumn(
      children: [
        for (final entry in attributes.entries)
          _CredentialAttributeFieldRow(
            entry: entry,
            controllers: controllers,
            onSave: onSave,
            canSubmit: canSubmit,
            isLast: entry.key == lastKey,
          ),
      ],
      spacing: .md,
      crossAxisAlignment: .start,
    );
  }
}

class const _CredentialAttributeFieldRow({
  required final MapEntry<String, SkillCredentialAttributeDefinition> entry,
  required final Map<String, TextEditingController> controllers,
  required final VoidCallback onSave,
  required final bool canSubmit,
  required final bool isLast,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _CredentialAttributeField(
    entry: entry,
    controller: _credentialAttributeController(controllers, entry.key),
    textInputAction: isLast ? .done : .next,
    onSubmitted: isLast && canSubmit ? (_) => onSave() : null,
  );
}

TextEditingController _credentialAttributeController(
  Map<String, TextEditingController> controllers,
  String key,
) => controllers.putIfAbsent(key, TextEditingController.new);

class const _CredentialAttributeField({
  required final MapEntry<String, SkillCredentialAttributeDefinition> entry,
  required final TextEditingController controller,
  required final TextInputAction textInputAction,
  required final ValueChanged<String>? onSubmitted,
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
      textInputAction: textInputAction,
      obscureText: attribute.secret,
      onSubmitted: onSubmitted,
    );
  }

  Text? _hint(String description) =>
      description.isEmpty ? null : Text(description);

  TextInputType _keyboardType(bool secret) => secret ? .visiblePassword : .text;
}
