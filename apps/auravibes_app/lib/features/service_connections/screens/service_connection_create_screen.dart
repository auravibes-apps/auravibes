// Required: Feature widgets keep closely related private widgets together.

import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/features/chats/widgets/chat_readiness_summary.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/widgets/add_model_provider_widget.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connections_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_access_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/task_return.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/app_screen.dart';
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

typedef _ConnectorConnectionSaveData = ({
  String connectorId,
  String apiKey,
  String name,
});

typedef _ConnectorConnectionFailureLogRequest = ({
  _ServiceConnectionCreateScreenState state,
  _ConnectorConnectionSaveData data,
  Object error,
  StackTrace stackTrace,
});

class const ServiceConnectionCreateScreen({
  required final String workspaceId,
  final ServiceConnectionCreateType? initialType,
  final String? initialConnectorId,
  final String? initialModelProviderId,
  final String? returnPath,
  final GlobalKey<NavigatorState>? returnNavigatorKey,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<ServiceConnectionCreateScreen> createState() =>
      _ServiceConnectionCreateScreenState();
}

class _ServiceConnectionCreateScreenState
    extends ConsumerState<ServiceConnectionCreateScreen> {
  final _nameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  ServiceConnectionCreateType _type = .modelProvider;
  String? _connectorId;
  final _exitGuard = DraftExitGuard();
  String _initialSnapshot = '';
  bool _saved = false;
  bool _handoff = false;
  bool _isSaving = false;

  String get _snapshot => jsonEncode({
    'name': _nameController.text,
    'type': _type.name,
    'connector': _connectorId,
    if (_type == .connector) 'apiKey': _apiKeyController.text,
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
    final access = ref.watch(workspaceAccessProvider(widget.workspaceId));
    if (!ref.watch(canManageWorkspaceProvider(widget.workspaceId))) {
      return _ManagementDenied(access: access);
    }

    _bindCreateExitGuard(this);

    return DraftExitScope(
      guard: _exitGuard,
      child: _ServiceConnectionCreateScreenContent(state: this),
    );
  }
}

void _bindCreateExitGuard(_ServiceConnectionCreateScreenState state) {
  final destination = _createReturnDestination(state);
  state._exitGuard.bind(
    readers: (isDirty: () => state._isDirty, isSaving: () => state._isBusy),
    preferReturn: destination != null,
    callbacks: _createExitCallbacks(state, destination),
  );
}

DraftExitGuardCallbacks _createExitCallbacks(
  _ServiceConnectionCreateScreenState state,
  String? destination,
) {
  final navigatorKey = state.widget.returnNavigatorKey;

  return DraftExitGuardCallbacks(
    onReturn: (context) =>
        _returnFromCreate(context, state.widget.workspaceId, destination),
    onPop: navigatorKey == null
        ? null
        : (context, result) =>
              _popOrReturnFromCreate(state, destination, context, result),
  );
}

void _popOrReturnFromCreate(
  _ServiceConnectionCreateScreenState state,
  String? destination,
  BuildContext context,
  Object? result,
) {
  if (_popCreateReturnNavigator(state, result)) return;
  _returnFromCreate(context, state.widget.workspaceId, destination);
}

bool _popCreateReturnNavigator(
  _ServiceConnectionCreateScreenState state,
  Object? result,
) {
  final navigator = state.widget.returnNavigatorKey?.currentState;
  if (navigator == null || !navigator.canPop()) return false;
  navigator.pop(result);

  return true;
}

String? _createReturnDestination(_ServiceConnectionCreateScreenState state) =>
    TaskReturn.validate(
      state.widget.returnPath,
      workspaceId: state.widget.workspaceId,
    );

void _returnFromCreate(
  BuildContext context,
  String workspaceId,
  String? destination,
) => context.go(
  destination ?? ServiceConnectionsRoute(workspaceId: workspaceId).location,
);

class const _ServiceConnectionCreateScreenContent({
  required final _ServiceConnectionCreateScreenState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => state._handoff
      ? _CreateScreenHandoff(state: state)
      : _ServiceConnectionCreateView(form: .fromState(state));
}

class const _CreateScreenHandoff({
  required final _ServiceConnectionCreateScreenState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppScreen(
    child: AuraColumn(
      children: [
        const TextLocale('chat_readiness.saved'),
        ChatReadinessSummary(
          workspaceId: state.widget.workspaceId,
          isSetupHandoff: true,
        ),
        AuraButton(
          onPressed: () => unawaited(_closeAfterSave(state)),
          child: const TextLocale('chat_readiness.continue_chat'),
        ),
      ],
    ),
    appBar: const AuraAppBarWithDrawer(
      title: TextLocale('chat_readiness.saved'),
    ),
  );
}

void _initializeCreateState(_ServiceConnectionCreateScreenState state) {
  state._type = state.widget.initialConnectorId != null
      ? .connector
      : state.widget.initialType ?? .modelProvider;
  state._connectorId = state.widget.initialConnectorId;
}

void _disposeCreateState(_ServiceConnectionCreateScreenState state) {
  state._nameController.dispose();
  state._apiKeyController.dispose();
}

void _handleFieldChanged(_ServiceConnectionCreateScreenState state, String _) {
  state.updateState(() {
    final _ = Object();
  });
}

void _handleConnectorChanged(
  _ServiceConnectionCreateScreenState state,
  String? value,
) {
  state.updateState(() {
    state._connectorId = value;
    state._apiKeyController.clear();
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

void _handleConnectorConnectionSave(_ServiceConnectionCreateScreenState state) {
  unawaited(_saveConnectorConnection(state));
}

Future<void> _saveConnectorConnection(
  _ServiceConnectionCreateScreenState state,
) async {
  if (state._isSaving) return;
  final data = _connectorSaveData(state);
  if (data == null) return;

  state.updateState(() => state._isSaving = true);
  await _saveConnectorConnectionRequest(state, data);
}

Future<void> _saveConnectorConnectionRequest(
  _ServiceConnectionCreateScreenState state,
  _ConnectorConnectionSaveData data,
) async {
  try {
    await _createConnectorConnection(state, data);
    await _closeAfterSave(state, resetModelMutation: false);
  } on Object catch (error, stackTrace) {
    _handleConnectorConnectionSaveFailure((
      state: state,
      data: data,
      error: error,
      stackTrace: stackTrace,
    ));
  } finally {
    _finishSaving(state);
  }
}

void _handleConnectorConnectionSaveFailure(
  _ConnectorConnectionFailureLogRequest request,
) {
  _logConnectorConnectionSaveFailure(request);
  _showConnectorConnectionSaveError(request.state);
}

void _showConnectorConnectionSaveError(
  _ServiceConnectionCreateScreenState state,
) {
  if (!state.mounted) return;
  final _ = AuraSnackBars.show(
    context: state.context,
    content: const TextLocale(LocaleKeys.service_connections_save_error),
    variant: .error,
  );
}

_ConnectorConnectionSaveData? _connectorSaveData(
  _ServiceConnectionCreateScreenState state,
) {
  final connectorId = state._connectorId;
  if (connectorId == null) return null;

  final apiKey = state._apiKeyController.text.trim();
  if (apiKey.isEmpty) return null;

  final name = state._nameController.text.trim();
  if (name.isEmpty) return null;

  return (connectorId: connectorId, apiKey: apiKey, name: name);
}

Future<void> _createConnectorConnection(
  _ServiceConnectionCreateScreenState state,
  _ConnectorConnectionSaveData data,
) async {
  final operations = await state.ref.read(
    serviceConnectionOperationsProvider(state.widget.workspaceId).future,
  );
  final _ = await operations.createConnectorConnection(
    workspaceId: state.widget.workspaceId,
    connectorId: data.connectorId,
    name: data.name,
    apiKey: data.apiKey,
  );
}

void _logConnectorConnectionSaveFailure(
  _ConnectorConnectionFailureLogRequest request,
) {
  _logger.severe(
    'debug:connector connection save failed '
    'workspace=${request.state.widget.workspaceId} '
    'connectorId=${request.data.connectorId} '
    'nameLength=${request.data.name.length}',
    request.error,
    request.stackTrace,
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
  _markCreateSaved(state, refreshServiceConnections, resetModelMutation);
  await _navigateAfterCreateSave(state);
}

void _markCreateSaved(
  _ServiceConnectionCreateScreenState state,
  bool refreshServiceConnections,
  bool resetModelMutation,
) {
  state
    .._saved = true
    .._isSaving = false;
  _resetAfterSave(state, refreshServiceConnections, resetModelMutation);
}

Future<void> _navigateAfterCreateSave(
  _ServiceConnectionCreateScreenState state,
) async {
  final destination = _createReturnDestination(state);
  if (state._handoff && destination != null) {
    state.context.go(destination);

    return;
  }
  if (_popCreateReturnNavigator(state, true)) return;
  if (await Navigator.of(state.context).maybePop(true)) return;
  if (!state.mounted) return;
  _returnFromCreate(state.context, state.widget.workspaceId, destination);
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
  if (!await _canReplaceCreateType(state)) return;
  state.ref
      .read(addModelProviderStateProvider(state.widget.workspaceId).notifier)
      .reset();
  _applyCreateType(state, value);
  state._exitGuard.releaseApproval();
}

Future<bool> _canReplaceCreateType(
  _ServiceConnectionCreateScreenState state,
) async => await state._exitGuard.canExit(state.context) && state.mounted;

void _applyCreateType(
  _ServiceConnectionCreateScreenState state,
  ServiceConnectionCreateType value,
) {
  state.updateState(() {
    state
      .._type = value
      .._connectorId = null;
    state._apiKeyController.clear();
  });
}

class const _ServiceConnectionCreateForm({
  required final String workspaceId,
  required final DraftExitGuard routeExitGuard,
  required final bool contextual,
  required final bool fixedConnector,
  required final ServiceConnectionCreateType type,
  required final String? selectedConnectorId,
  required final String? initialModelProviderId,
  required final TextEditingController nameController,
  required final TextEditingController apiKeyController,
  required final bool isSaving,
  required final ValueChanged<ServiceConnectionCreateType?> onTypeChanged,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String?> onConnectorChanged,
  required final ValueChanged<String> onApiKeyChanged,
  required final VoidCallback onModelProviderCreated,
  required final VoidCallback onConnectorConnectionSave,
}) {
  new fromState(_ServiceConnectionCreateScreenState state)
    : this(
        workspaceId: state.widget.workspaceId,
        contextual:
            state.widget.initialType != null ||
            state.widget.initialConnectorId != null,
        fixedConnector: state.widget.initialConnectorId != null,
        routeExitGuard: state._exitGuard,
        type: state._type,
        selectedConnectorId: state._connectorId,
        initialModelProviderId: state.widget.initialModelProviderId,
        nameController: state._nameController,
        apiKeyController: state._apiKeyController,
        isSaving: state._isSaving,
        onTypeChanged: (value) => _onTypeChanged(state, value),
        onNameChanged: (value) => _handleFieldChanged(state, value),
        onConnectorChanged: (value) => _handleConnectorChanged(state, value),
        onApiKeyChanged: (value) => _handleFieldChanged(state, value),
        onModelProviderCreated: () => _handleModelProviderCreated(state),
        onConnectorConnectionSave: () => _handleConnectorConnectionSave(state),
      );

  bool canSaveConnectorConnection() =>
      _connectorOption(selectedConnectorId) != null &&
      nameController.text.trim().isNotEmpty &&
      apiKeyController.text.trim().isNotEmpty;
}

class const _ServiceConnectionCreateView({
  required final _ServiceConnectionCreateForm form,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppScreen(
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
                .connector => 'connection_setup.add_access',
              }
            : LocaleKeys.service_connections_create_title,
      ),
      leading: AuraIconButton(
        icon: Icons.arrow_back,
        onPressed: () => unawaited(form.routeExitGuard.pop(context)),
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
      .connector => _ConnectorConnectionCreateContent(form: form),
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
        initialModelProviderId: form.initialModelProviderId,
      ),
    );
  }
}

class const _ConnectorConnectionCreateContent({
  required final _ServiceConnectionCreateForm form,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (_isMissingFixedAppSkill(form)) {
      return _MissingFixedAppSkillContent(routeExitGuard: form.routeExitGuard);
    }

    return _ConnectorConnectionForm.fromCreateForm(form);
  }
}

bool _isMissingFixedAppSkill(_ServiceConnectionCreateForm form) =>
    form.fixedConnector && _connectorOption(form.selectedConnectorId) == null;

class const _MissingFixedAppSkillContent({
  required final DraftExitGuard routeExitGuard,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const TextLocale('connection_setup.required_service_missing'),
      AuraButton(
        onPressed: () => unawaited(routeExitGuard.pop(context)),
        child: const TextLocale('connection_setup.return_task'),
      ),
    ],
  );
}

enum ServiceConnectionCreateType { modelProvider, connector }

extension ServiceConnectionCreateTypeQuery on ServiceConnectionCreateType {
  static ServiceConnectionCreateType? fromQueryValue(String? value) {
    return switch (value) {
      'modelProvider' => ServiceConnectionCreateType.modelProvider,
      'connector' => ServiceConnectionCreateType.connector,
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
    .connector => LocaleKeys.service_connections_type_connector,
  };

  return key.tr(context: context);
}

class const _ConnectorConnectionForm({
  required final String? selectedConnectorId,
  required final bool fixedConnector,
  required final TextEditingController nameController,
  required final TextEditingController apiKeyController,
  required final bool isSaving,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String?> onConnectorChanged,
  required final ValueChanged<String> onApiKeyChanged,
  required final VoidCallback onSave,
  required final bool canSave,
}) extends StatelessWidget {
  static const _contentPadding = 12.0;

  new fromCreateForm(_ServiceConnectionCreateForm form)
    : this(
        selectedConnectorId: form.selectedConnectorId,
        fixedConnector: form.fixedConnector,
        nameController: form.nameController,
        apiKeyController: form.apiKeyController,
        isSaving: form.isSaving,
        onNameChanged: form.onNameChanged,
        onConnectorChanged: form.onConnectorChanged,
        onApiKeyChanged: form.onApiKeyChanged,
        onSave: form.onConnectorConnectionSave,
        canSave: form.canSaveConnectorConnection(),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(
        _contentPadding,
      ).copyWith(bottom: BottomPadding.of(context, minimum: _contentPadding)),
      children: [_ConnectorConnectionCard._fromForm(this)],
      keyboardDismissBehavior: .onDrag,
    );
  }
}

class const _ConnectorConnectionCard({
  required final String? selectedConnectorId,
  required final bool fixedConnector,
  required final TextEditingController nameController,
  required final TextEditingController apiKeyController,
  required final bool isSaving,
  required final bool canSave,
  required final ValueChanged<String> onNameChanged,
  required final ValueChanged<String?> onConnectorChanged,
  required final ValueChanged<String> onApiKeyChanged,
  required final VoidCallback onSave,
}) extends StatelessWidget {
  new _fromForm(_ConnectorConnectionForm form)
    : this(
        selectedConnectorId: form.selectedConnectorId,
        fixedConnector: form.fixedConnector,
        nameController: form.nameController,
        apiKeyController: form.apiKeyController,
        isSaving: form.isSaving,
        canSave: form.canSave,
        onNameChanged: form.onNameChanged,
        onConnectorChanged: form.onConnectorChanged,
        onApiKeyChanged: form.onApiKeyChanged,
        onSave: form.onSave,
      );

  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: AuraColumn(
        children: [
          if (fixedConnector)
            Text(_connectorOption(selectedConnectorId)?.title ?? '')
          else
            _ConnectorConnectionSelector.fromCard(this),
          _CredentialNameField._fromConnectorCard(this),
          _ConnectorConnectionValueField.fromCard(this),
          _CredentialSaveAction._fromConnectorCard(this),
        ],
        spacing: .md,
        crossAxisAlignment: .start,
      ),
    );
  }
}

class const _ConnectorConnectionSelector({
  required final String? value,
  required final ValueChanged<String?> onChanged,
}) extends StatelessWidget {
  new fromCard(_ConnectorConnectionCard card)
    : this(value: card.selectedConnectorId, onChanged: card.onConnectorChanged);

  @override
  Widget build(BuildContext context) {
    return AuraDropdownSelector<String>(
      options: _connectorOptions().map(_option).toList(),
      value: value,
      onChanged: onChanged,
      label: Text(
        LocaleKeys.service_connections_create_connector_label.tr(
          context: context,
        ),
      ),
    );
  }

  AuraDropdownOption<String> _option(ConnectorDefinition connector) =>
      AuraDropdownOption(
        value: connector.identifier,
        child: Text(connector.title),
      );
}

class const _CredentialNameField({
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
  required final TextInputAction textInputAction,
  required final ValueChanged<String>? onSubmitted,
}) extends StatelessWidget {
  new _fromConnectorCard(_ConnectorConnectionCard card)
    : this(
        controller: card.nameController,
        onChanged: card.onNameChanged,
        textInputAction: .next,
        onSubmitted: null,
      );

  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: controller,
      label: Text(
        LocaleKeys.service_connections_create_name_label.tr(context: context),
      ),
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

class const _ConnectorConnectionValueField({
  required final String? connectorId,
  required final TextEditingController controller,
  required final ValueChanged<String> onChanged,
  required final VoidCallback onSave,
  required final bool canSubmit,
}) extends StatelessWidget {
  new fromCard(_ConnectorConnectionCard card)
    : this(
        connectorId: card.selectedConnectorId,
        controller: card.apiKeyController,
        onChanged: card.onApiKeyChanged,
        onSave: card.onSave,
        canSubmit: card.canSave && !card.isSaving,
      );

  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: controller,
      label: Text(_credentialValueLabel(context, connectorId)),
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
  new _fromConnectorCard(_ConnectorConnectionCard card)
    : this(
        onSave: card.onSave,
        isSaving: card.isSaving,
        disabled: !card.canSave,
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

List<ConnectorDefinition> _connectorOptions() => connectorDefinitions
    .where(
      (connector) => connector.tools.any(
        (tool) => tool.requiresConnection && tool.urlTemplate != null,
      ),
    )
    .toList();

ConnectorDefinition? _connectorOption(String? connectorId) {
  if (connectorId == null) return null;

  return _connectorOptions()
      .where((connector) => connector.identifier == connectorId)
      .firstOrNull;
}

String _credentialValueLabel(BuildContext context, String? connectorId) {
  if (connectorId == 'searxng') {
    return LocaleKeys.service_connections_create_base_url_label.tr(
      context: context,
    );
  }

  return LocaleKeys.service_connections_create_api_key_label.tr(
    context: context,
  );
}

class const _ManagementDenied({required final AsyncValue<Object?> access})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppScreen(
    child: Center(
      child: switch (access) {
        AsyncLoading() => const AuraSpinner(),
        AsyncData() || AsyncError() => const TextLocale(
          LocaleKeys.cloud_errors_permission_denied,
        ),
      },
    ),
  );
}
