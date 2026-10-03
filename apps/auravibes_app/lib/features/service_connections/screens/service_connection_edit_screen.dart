// Required: Feature widgets keep closely related private widgets together.

import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/models/models/model_provider_verification.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/models/mcp_server_for_edit.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_operations_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_operations.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_app/widgets/bottom_padding.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_app/widgets/unsaved_changes_dialog.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show SkillCredentialAttributeDefinition;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const ServiceConnectionEditScreen({
  required final String workspaceId,
  required final String connectionId,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<ServiceConnectionEditScreen> createState() =>
      _ServiceConnectionEditScreenState();
}

class _ServiceConnectionEditScreenState
    extends ConsumerState<ServiceConnectionEditScreen> {
  final _nameController = TextEditingController();
  final _modelKeyController = TextEditingController();
  final _modelUrlController = TextEditingController();
  final _mcpUrlController = TextEditingController();
  final _mcpSecretController = TextEditingController();
  final _nonSecretControllers = <String, TextEditingController>{};
  final _secretControllers = <String, TextEditingController>{};
  final _clearedSecrets = <String>{};
  Future<_ConnectionEditState>? _futureValue;
  bool _initialized = false;
  bool _isDirty = false;
  String _savedSnapshot = '';
  _ConnectionEditState? _editState;
  bool _isSaving = false;
  bool _isTestingModelProvider = false;
  ModelProviderVerification? _modelProviderVerification;
  McpTransportTypeOptions? _mcpTransport;
  McpServerAuthMode? _mcpAuthMode;
  Timer? _modelProviderVerificationExpiryTimer;
  Exception? _modelProviderVerificationError;
  var _modelProviderVerificationVersion = 0;

  Future<_ConnectionEditState> get _future =>
      _futureValue ?? (throw StateError('Edit state is not initialized'));

  String? get _modelProviderVerificationErrorMessage {
    final error = _modelProviderVerificationError;
    if (error == null) return null;
    if (error case ModelConnectionException(:final message)
        when message.trim().isNotEmpty) {
      return message;
    }

    return switch (error) {
      ProviderVerificationExpiredException() =>
        LocaleKeys.mcp_modal_verification_expired.tr(),
      ProviderVerificationRequiredException() ||
      ProviderVerificationMismatchException() =>
        LocaleKeys.mcp_modal_verification_required.tr(),
      _ => LocaleKeys.models_screens_add_provider_errors_unknown.tr(),
    };
  }

  @override
  void initState() {
    super.initState();
    _futureValue = _loadConnectionEditState(
      ref,
      widget.workspaceId,
      widget.connectionId,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelKeyController.dispose();
    _modelUrlController.dispose();
    _mcpUrlController.dispose();
    _mcpSecretController.dispose();
    for (final controller in _nonSecretControllers.values) {
      controller.dispose();
    }
    for (final controller in _secretControllers.values) {
      controller.dispose();
    }
    _modelProviderVerificationExpiryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: _ConnectionEditScreenView(owner: this),
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack(context));
      },
    );
  }

  void _initialize(_ConnectionEditState state) {
    if (_initialized) return;
    _editState = state;
    _initializeConnectionEditControllers(state, this);
    _initialized = true;
    _savedSnapshot = _currentSnapshot();
    _isDirty = false;
  }

  void _refreshForm([VoidCallback? update]) {
    setState(() {
      update?.call();
      _initialized = true;
      final state = _editState;
      if (state != null) _isDirty = _currentSnapshot() != _savedSnapshot;
    });
  }

  Future<void> _saveSkillCredential(BuildContext context) async {
    setState(() => _isSaving = true);
    await _runEditSave(
      context,
      () => _updateSkillCredential(
        ref,
        widget.workspaceId,
        _skillCredentialUpdateData(this, widget.connectionId),
      ),
      LocaleKeys.skill_credentials_save_error,
      onSaved: _markSaved,
    );
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _saveGenericConnection(
    BuildContext context,
    _GenericServiceConnectionEditState state,
  ) async {
    setState(() => _isSaving = true);
    await _runEditSave(
      context,
      () => _updateGenericConnection(
        ref,
        widget.workspaceId,
        _genericConnectionUpdateData(state, this),
      ),
      LocaleKeys.service_connections_save_error,
      onSaved: _markSaved,
    );
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _saveMcpServer(
    BuildContext context,
    _McpServerEditState state,
  ) async {
    if (!mounted || !context.mounted) return;
    setState(() => _isSaving = true);
    await _runMcpServerEditSave(context, state, this);
    if (mounted) setState(() => _isSaving = false);
  }
}

void _initializeConnectionEditControllers(
  _ConnectionEditState state,
  _ServiceConnectionEditScreenState owner,
) {
  _initializeEditControllers(
    state,
    .new(
      nameController: owner._nameController,
      modelUrlController: owner._modelUrlController,
      nonSecretControllers: owner._nonSecretControllers,
      secretControllers: owner._secretControllers,
    ),
  );
  if (state case final _McpServerEditState mcpState) {
    owner._initializeMcpServerControllers(mcpState);
  }
}

extension _McpServerEditInitialization on _ServiceConnectionEditScreenState {
  void _initializeMcpServerControllers(_McpServerEditState state) {
    _mcpUrlController.text = state.server.url;
    _mcpTransport = _mcpTransportOption(state.server.transport);
    _mcpAuthMode = state.server.authMode;
  }
}

Future<void> _runMcpServerEditSave(
  BuildContext context,
  _McpServerEditState state,
  _ServiceConnectionEditScreenState owner,
) => _runEditSave(
  context,
  () => _saveMcpServerSettings(
    owner.ref,
    owner.widget.workspaceId,
    state.server,
    _mcpServerSettingsUpdate(state, owner),
  ),
  LocaleKeys.service_connections_save_error,
  onSaved: owner._markSaved,
);

Future<void> _saveMcpServerSettings(
  WidgetRef ref,
  String workspaceId,
  McpServerForEdit server,
  McpServerSettingsUpdate update,
) async {
  final operations = await ref.read(
    serviceConnectionOperationsProvider(workspaceId).future,
  );
  final save = operations.updateMcp;
  if (save == null) throw StateError('MCP edit operation is unavailable.');
  await save(server, update);
}

extension ServiceConnectionEditUnsavedChanges
    on _ServiceConnectionEditScreenState {
  String _currentSnapshot() {
    final state = _editState;
    if (state == null) return '';

    final name = _nameController.text.trim();

    return switch (state) {
      final _SkillCredentialEditState skillState => _skillCredentialSnapshot(
        skillState,
        name,
      ),
      final _ModelProviderEditState modelState => _modelProviderSnapshot(
        modelState,
        name,
      ),
      final _GenericServiceConnectionEditState genericState =>
        _genericConnectionSnapshot(genericState, name),
      final _McpServerEditState mcpState => _mcpServerSnapshot(mcpState, name),
    };
  }

  String _skillCredentialSnapshot(
    _SkillCredentialEditState state,
    String name,
  ) {
    final nonSecretNames = _nonSecretControllers.keys.toList()..sort();
    final secretNames = _secretControllers.keys.toList()..sort();

    return jsonEncode({
      'type': 'skillCredential',
      'connectionId': state.credential.id,
      'name': name,
      'nonSecretAttributes': _nonSecretAttributeSnapshots(nonSecretNames),
      'secretIntents': _secretIntentSnapshots(secretNames),
    });
  }

  List<List<String>> _nonSecretAttributeSnapshots(List<String> names) => [
    for (final name in names) [name, _nonSecretControllers[name]!.text],
  ];

  List<List<String>> _secretIntentSnapshots(List<String> names) => [
    for (final name in names)
      [
        name,
        _secretEditFor(
          _secretControllers[name]!.text,
          _clearedSecrets.contains(name),
        ).name,
      ],
  ];

  String _modelProviderSnapshot(_ModelProviderEditState state, String name) =>
      jsonEncode({
        'type': 'modelProvider',
        'connectionId': state.connection.id,
        'name': name,
        'url': _modelUrlController.text.trim(),
        'keyIntent': _secretEditFor(
          _modelKeyController.text.trim(),
          false,
        ).name,
      });

  String _genericConnectionSnapshot(
    _GenericServiceConnectionEditState state,
    String name,
  ) => jsonEncode({
    'type': 'genericConnection',
    'connectionId': state.connection.id,
    'name': name,
    'secretIntent': _secretEditFor(
      _modelKeyController.text.trim(),
      _clearedSecrets.contains('secret'),
    ).name,
  });

  String _mcpServerSnapshot(_McpServerEditState state, String name) =>
      jsonEncode({
        'type': 'mcpServer',
        'serverId': state.server.id,
        'name': name,
        'url': _mcpUrlController.text.trim(),
        'transport': _mcpTransport?.name,
        'authMode': _mcpAuthMode?.name,
        'secretIntent': _secretEditFor(
          _mcpSecretController.text.trim(),
          false,
        ).name,
      });

  void _markSaved() => _refreshForm(() => _savedSnapshot = _currentSnapshot());

  Future<void> _handleBack(BuildContext context) async {
    if (_isSaving || !context.mounted) return;
    if (!_isDirty) {
      Navigator.of(context).pop();

      return;
    }

    final shouldDiscard = await UnsavedChangesDialog.confirm(context);
    if (shouldDiscard != true || !context.mounted) return;

    _refreshForm(() => _savedSnapshot = _currentSnapshot());
    Navigator.of(context).pop();
  }
}

extension _ModelProviderEditActions on _ServiceConnectionEditScreenState {
  String? get _replacementModelProviderKey {
    final key = _modelKeyController.text.trim();

    return key.isEmpty ? null : key;
  }

  void _invalidateModelProviderVerification() {
    _modelProviderVerificationVersion++;
    _modelProviderVerificationExpiryTimer?.cancel();
    _modelProviderVerificationExpiryTimer = null;
    _modelProviderVerification = null;
    _modelProviderVerificationError = null;
    _isTestingModelProvider = false;
    _refreshForm();
  }

  Future<void> _verifyModelProvider(
    BuildContext context,
    _ModelProviderEditState state,
  ) => _runModelProviderVerification(context, state);

  ModelProviderVerificationRequest _modelProviderVerificationRequest(
    ModelConnectionForEdit connection,
  ) => ModelProviderVerificationRequest(
    workspaceId: widget.workspaceId,
    providerId: connection.modelId,
    connectionId: connection.id,
    expectedRevision: connection.revision,
    url: _normalizedModelProviderUrl(_modelUrlController.text),
    key: _replacementModelProviderKey,
  );

  String? _normalizedModelProviderUrl(String value) {
    final url = value.trim();

    return url.isEmpty ? null : url;
  }

  bool _modelProviderRequiresVerification(_ModelProviderEditState state) {
    final urlChanged =
        _normalizedModelProviderUrl(_modelUrlController.text) !=
        state.connection.url;

    return urlChanged || _replacementModelProviderKey != null;
  }

  bool _modelProviderVerificationIsCurrent(_ModelProviderEditState state) {
    final verification = _modelProviderVerification;

    return verification != null &&
        verification.matches(
          _modelProviderVerificationRequest(state.connection),
        );
  }

  bool _modelProviderCanSave(_ModelProviderEditState state) {
    if (_nameController.text.trim().isEmpty || _isSaving) return false;
    if (!_modelProviderRequiresVerification(state)) return true;

    return !_isTestingModelProvider &&
        _modelProviderVerificationIsCurrent(state);
  }

  Future<void> _saveModelProvider(BuildContext context) async {
    _refreshForm(() {
      _isSaving = true;
    });
    await _runEditSave(
      context,
      () => _updateModelProvider(
        ref,
        widget.workspaceId,
        _modelProviderUpdateData(this, widget.connectionId),
      ),
      LocaleKeys.service_connections_save_error,
      onSaved: _markSaved,
    );
    if (mounted) {
      _refreshForm(() {
        _isSaving = false;
      });
    }
  }
}

extension _ModelProviderVerificationActions
    on _ServiceConnectionEditScreenState {
  void _scheduleModelProviderVerificationExpiry(
    ModelProviderVerification verification,
  ) {
    final remaining = verification.expiresAt.difference(DateTime.now().toUtc());
    _modelProviderVerificationExpiryTimer = .new(
      remaining.isNegative ? Duration.zero : remaining,
      () => _expireModelProviderVerification(verification),
    );
  }

  void _expireModelProviderVerification(
    ModelProviderVerification verification,
  ) {
    if (!identical(_modelProviderVerification, verification) || !mounted) {
      return;
    }

    _refreshForm(() {
      _modelProviderVerification = null;
      _modelProviderVerificationExpiryTimer = null;
      _modelProviderVerificationError =
          const ProviderVerificationExpiredException();
    });
  }

  Future<void> _runModelProviderVerification(
    BuildContext context,
    _ModelProviderEditState state,
  ) async {
    if (_isSaving || _isTestingModelProvider) return;

    final version = _startModelProviderVerification();
    try {
      final verification = await _requestModelProviderVerification(state);
      if (!_isCurrentModelProviderVerification(version)) return;

      _acceptModelProviderVerification(verification);
      if (context.mounted) {
        _showModelProviderVerificationSuccess(context, verification);
      }
    } on Exception catch (error) {
      if (!_isCurrentModelProviderVerification(version)) return;

      _setModelProviderVerificationError(error);
    }
  }

  int _startModelProviderVerification() {
    final version = ++_modelProviderVerificationVersion;
    _modelProviderVerificationExpiryTimer?.cancel();
    _modelProviderVerificationExpiryTimer = null;
    _modelProviderVerification = null;
    _modelProviderVerificationError = null;
    _refreshForm(() {
      _isTestingModelProvider = true;
    });

    return version;
  }

  Future<ModelProviderVerification> _requestModelProviderVerification(
    _ModelProviderEditState state,
  ) async {
    final store = await ref.read(
      modelConnectionStoreProvider(widget.workspaceId).future,
    );

    return await store.verifyModelConnection(
      _modelProviderVerificationRequest(state.connection),
    );
  }

  bool _isCurrentModelProviderVerification(int version) =>
      mounted && version == _modelProviderVerificationVersion;

  void _acceptModelProviderVerification(
    ModelProviderVerification verification,
  ) {
    _refreshForm(() {
      _modelProviderVerification = verification;
      _isTestingModelProvider = false;
    });
    _scheduleModelProviderVerificationExpiry(verification);
  }

  void _setModelProviderVerificationError(Exception error) {
    _refreshForm(() {
      _isTestingModelProvider = false;
      _modelProviderVerificationError = error;
    });
  }

  void _showModelProviderVerificationSuccess(
    BuildContext context,
    ModelProviderVerification verification,
  ) {
    final connectedLabel = LocaleKeys.service_connections_status_connected.tr();
    final modelCountLabel = LocaleKeys.status_bar_models_available.plural(
      verification.modelCount,
    );
    final _ = AuraSnackBars.show(
      context: context,
      content: Text('$connectedLabel - $modelCountLabel'),
      variant: .success,
    );
  }
}

Future<_ConnectionEditState> _loadConnectionEditState(
  WidgetRef ref,
  String workspaceId,
  String connectionId,
) async {
  final operations = await ref.read(
    serviceConnectionOperationsProvider(workspaceId).future,
  );
  final connection = await _loadMcpOrGenericEditState(operations, connectionId);
  if (connection != null) return connection;

  return await _loadCredentialOrModel(ref, workspaceId, connectionId);
}

Future<_ConnectionEditState?> _loadMcpOrGenericEditState(
  ServiceConnectionOperations operations,
  String connectionId,
) async {
  final mcp = await operations.getMcpForEdit?.call(connectionId);
  if (mcp != null) return _McpServerEditState(server: mcp);
  final generic = await operations.getGenericForEdit(connectionId);
  if (generic == null) return null;

  return _GenericServiceConnectionEditState(connection: generic);
}

Future<_ConnectionEditState> _loadCredentialOrModel(
  WidgetRef ref,
  String workspaceId,
  String connectionId,
) async {
  final credential = await _loadSkillCredentialForEdit(
    ref,
    workspaceId,
    connectionId,
  );
  if (credential != null) return credential;

  return await _loadModelOrThrow(ref, workspaceId, connectionId);
}

Future<_ConnectionEditState> _loadModelOrThrow(
  WidgetRef ref,
  String workspaceId,
  String connectionId,
) async {
  final model = await _loadModelProviderForEdit(ref, workspaceId, connectionId);
  if (model != null) return model;
  throw StateError('Service connection not found: $connectionId');
}

Future<_SkillCredentialEditState?> _loadSkillCredentialForEdit(
  WidgetRef ref,
  String workspaceId,
  String connectionId,
) async {
  final credential = await ref
      .read(skillCredentialOperationsProvider(workspaceId))
      .getForEdit(connectionId);
  if (credential == null) return null;

  final definition = await _loadSkillCredentialDefinition(
    ref,
    workspaceId,
    credential.credentialDefinitionId,
  );

  return _SkillCredentialEditState(
    credential: credential,
    definition: definition,
  );
}

Future<SkillCredentialDefinitionEntity> _loadSkillCredentialDefinition(
  WidgetRef ref,
  String workspaceId,
  String definitionId,
) async {
  final definition = await ref.read(
    skillCredentialDefinitionProvider(workspaceId, definitionId).future,
  );
  if (definition == null) {
    throw StateError('Skill credential definition not found.');
  }

  return definition;
}

Future<_ModelProviderEditState?> _loadModelProviderForEdit(
  WidgetRef ref,
  String workspaceId,
  String connectionId,
) async {
  final store = await ref.read(
    modelConnectionStoreProvider(workspaceId).future,
  );
  final connection = await store.getModelConnectionForEdit(connectionId);
  if (connection == null) return null;

  return _ModelProviderEditState(connection: connection);
}

class const _ConnectionEditControllers({
  required final TextEditingController nameController,
  required final TextEditingController modelUrlController,
  required final Map<String, TextEditingController> nonSecretControllers,
  required final Map<String, TextEditingController> secretControllers,
});

void _initializeEditControllers(
  _ConnectionEditState state,
  _ConnectionEditControllers controllers,
) {
  switch (state) {
    case final _SkillCredentialEditState skillState:
      _initializeSkillCredentialControllers(skillState, controllers);
    case final _ModelProviderEditState modelState:
      _initializeModelProviderControllers(modelState, controllers);
    case final _GenericServiceConnectionEditState genericState:
      _initializeNameController(genericState.connection.name, controllers);
    case final _McpServerEditState mcpState:
      _initializeNameController(mcpState.server.name, controllers);
  }
}

void _initializeModelProviderControllers(
  _ModelProviderEditState state,
  _ConnectionEditControllers controllers,
) {
  controllers.nameController.text = state.connection.name;
  controllers.modelUrlController.text = state.connection.url ?? '';
}

void _initializeNameController(
  String name,
  _ConnectionEditControllers controllers,
) {
  controllers.nameController.text = name;
}

void _initializeSkillCredentialControllers(
  _SkillCredentialEditState state,
  _ConnectionEditControllers controllers,
) {
  controllers.nameController.text = state.credential.name;
  final attributes = SkillCredentialAttributeDefinition.parseMap(
    state.definition.attributesJson,
  );
  for (final entry in attributes.entries) {
    _initializeCredentialAttribute(entry, state.credential, controllers);
  }
}

void _initializeCredentialAttribute(
  MapEntry<String, SkillCredentialAttributeDefinition> entry,
  SkillCredentialForEdit credential,
  _ConnectionEditControllers controllers,
) {
  if (entry.value.secret) {
    _initializeSecretController(entry.key, controllers.secretControllers);

    return;
  }

  _initializeNonSecretController(
    entry,
    credential.nonSecretAttributes,
    controllers.nonSecretControllers,
  );
}

void _initializeSecretController(
  String name,
  Map<String, TextEditingController> controllers,
) {
  final _ = controllers.putIfAbsent(name, TextEditingController.new);
}

void _initializeNonSecretController(
  MapEntry<String, SkillCredentialAttributeDefinition> entry,
  Map<String, String> values,
  Map<String, TextEditingController> controllers,
) {
  final _ = controllers.putIfAbsent(
    entry.key,
    () => TextEditingController(text: values[entry.key] ?? ''),
  );
}

class const _SkillCredentialUpdateData({
  required final String connectionId,
  required final String name,
  required final Map<String, String> nonSecretAttributes,
  required final Map<String, String> secretAttributes,
  required final Set<String> clearSecretAttributeNames,
});

_SkillCredentialUpdateData _skillCredentialUpdateData(
  _ServiceConnectionEditScreenState state,
  String connectionId,
) => _SkillCredentialUpdateData(
  connectionId: connectionId,
  name: state._nameController.text.trim(),
  nonSecretAttributes: _controllerValues(state._nonSecretControllers),
  secretAttributes: _nonEmptyControllerValues(state._secretControllers),
  clearSecretAttributeNames: state._clearedSecrets,
);

Future<void> _updateSkillCredential(
  WidgetRef ref,
  String workspaceId,
  _SkillCredentialUpdateData data,
) async {
  final _ = await ref
      .read(skillCredentialOperationsProvider(workspaceId))
      .update(
        data.connectionId,
        .new(
          name: data.name,
          nonSecretAttributes: data.nonSecretAttributes,
          secretAttributes: data.secretAttributes,
          clearSecretAttributeNames: data.clearSecretAttributeNames,
        ),
      );
}

Map<String, String> _controllerValues(
  Map<String, TextEditingController> controllers,
) => controllers.map((key, controller) => MapEntry(key, controller.text));

Map<String, String> _nonEmptyControllerValues(
  Map<String, TextEditingController> controllers,
) => Map.fromEntries(
  controllers.entries
      .map((entry) => MapEntry(entry.key, entry.value.text))
      .where((entry) => entry.value.isNotEmpty),
);

class const _ModelProviderUpdateData({
  required final String connectionId,
  required final String name,
  required final String? key,
  required final String url,
  required final ModelProviderVerification? verification,
});

_ModelProviderUpdateData _modelProviderUpdateData(
  _ServiceConnectionEditScreenState state,
  String connectionId,
) {
  final key = state._modelKeyController.text.trim();

  return _ModelProviderUpdateData(
    connectionId: connectionId,
    name: state._nameController.text.trim(),
    key: key.isEmpty ? null : key,
    url: state._modelUrlController.text.trim(),
    verification: state._modelProviderVerification,
  );
}

Future<void> _updateModelProvider(
  WidgetRef ref,
  String workspaceId,
  _ModelProviderUpdateData data,
) async {
  final store = await ref.read(
    modelConnectionStoreProvider(workspaceId).future,
  );
  final _ = await store.updateModelConnection(
    data.connectionId,
    .new(name: data.name, key: data.key, url: data.url),
    verification: data.verification,
  );
}

class const _GenericConnectionUpdateData({
  required final GenericServiceConnectionForEdit connection,
  required final String name,
  required final ServiceConnectionSecretEdit secretEdit,
  required final String? secret,
});

_GenericConnectionUpdateData _genericConnectionUpdateData(
  _GenericServiceConnectionEditState state,
  _ServiceConnectionEditScreenState screenState,
) {
  final secretUpdate = _genericSecretUpdateForScreen(screenState);

  return _GenericConnectionUpdateData(
    connection: state.connection,
    name: screenState._nameController.text.trim(),
    secretEdit: secretUpdate.secretEdit,
    secret: secretUpdate.secret,
  );
}

({ServiceConnectionSecretEdit secretEdit, String? secret})
_genericSecretUpdateForScreen(_ServiceConnectionEditScreenState state) =>
    _genericSecretUpdate(
      state._modelKeyController.text.trim(),
      state._clearedSecrets.contains('secret'),
    );

({ServiceConnectionSecretEdit secretEdit, String? secret}) _genericSecretUpdate(
  String secret,
  bool isCleared,
) {
  final secretEdit = _secretEditFor(secret, isCleared);

  return (
    secretEdit: secretEdit,
    secret: secretEdit == ServiceConnectionSecretEdit.replace ? secret : null,
  );
}

ServiceConnectionSecretEdit _secretEditFor(String secret, bool isCleared) {
  return switch ((isCleared: isCleared, isEmpty: secret.isEmpty)) {
    (isCleared: true, isEmpty: _) => ServiceConnectionSecretEdit.clear,
    (isCleared: false, isEmpty: true) => ServiceConnectionSecretEdit.preserve,
    (isCleared: false, isEmpty: false) => ServiceConnectionSecretEdit.replace,
  };
}

Future<void> _updateGenericConnection(
  WidgetRef ref,
  String workspaceId,
  _GenericConnectionUpdateData data,
) async {
  final operations = await ref.read(
    serviceConnectionOperationsProvider(workspaceId).future,
  );
  await operations.updateGeneric(
    data.connection,
    .new(name: data.name, secretEdit: data.secretEdit, secret: data.secret),
  );
}

Future<void> _runEditSave(
  BuildContext context,
  Future<void> Function() operation,
  String errorKey, {
  required VoidCallback onSaved,
}) async {
  try {
    await operation();
    if (!context.mounted) return;
    onSaved();
    Navigator.of(context).pop(true);
  } on Object {
    if (!context.mounted) return;
    _showEditSaveError(context, errorKey);
  }
}

void _showEditSaveError(BuildContext context, String localeKey) {
  final _ = AuraSnackBars.show(
    context: context,
    content: TextLocale(localeKey),
    variant: .error,
  );
}

class const _ConnectionEditScreenView({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraScreen(
      child: _ConnectionEditBody(owner: owner),
      appBar: _ConnectionEditAppBar(owner: owner),
    );
  }
}

class const _ConnectionEditAppBar({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AuraAppBarWithDrawer(
      title: const TextLocale(LocaleKeys.service_connections_edit_title),
      leading: AuraIconButton(
        icon: Icons.arrow_back,
        onPressed: () => owner._handleBack(context),
      ),
    );
  }
}

class const _ConnectionEditBody({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ConnectionEditState>(
      future: owner._future,
      builder: (context, snapshot) =>
          _ConnectionEditSnapshotView(snapshot: snapshot, owner: owner),
    );
  }
}

class const _ConnectionEditSnapshotView({
  required final AsyncSnapshot<_ConnectionEditState> snapshot,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return const Center(
        child: TextLocale(LocaleKeys.service_connections_load_error),
      );
    }
    final state = snapshot.data;
    if (state == null) return const Center(child: AuraSpinner());
    owner._initialize(state);

    return _ConnectionEditFormSelector(state: state, owner: owner);
  }
}

class const _ConnectionEditFormSelector({
  required final _ConnectionEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return switch (state) {
      final _SkillCredentialEditState skillState => _SkillCredentialEditForm(
        state: skillState,
        owner: owner,
      ),
      final _ModelProviderEditState modelState => _ModelProviderEditForm(
        state: modelState,
        owner: owner,
      ),
      final _GenericServiceConnectionEditState genericState =>
        _GenericServiceConnectionEditForm(state: genericState, owner: owner),
      final _McpServerEditState mcpState => _McpServerEditForm(
        state: mcpState,
        owner: owner,
      ),
    };
  }
}

sealed class _ConnectionEditState;

class _SkillCredentialEditState({
  required final SkillCredentialForEdit credential,
  required final SkillCredentialDefinitionEntity definition,
}) extends _ConnectionEditState;

class _ModelProviderEditState({
  required final ModelConnectionForEdit connection,
}) extends _ConnectionEditState;

class _GenericServiceConnectionEditState({
  required final GenericServiceConnectionForEdit connection,
}) extends _ConnectionEditState;

class _McpServerEditState({required final McpServerForEdit server})
    extends _ConnectionEditState;

McpTransportTypeOptions _mcpTransportOption(McpTransportType transport) =>
    switch (transport) {
      McpTransportTypeSSE() => .sse,
      McpTransportTypeStreamableHttp() => .streamableHttp,
    };

McpTransportType _mcpTransportValue(
  McpTransportTypeOptions option,
  McpTransportType current,
) => switch (option) {
  .sse => const McpTransportTypeSSE(),
  .streamableHttp => McpTransportTypeStreamableHttp(
    useHttp2: current is McpTransportTypeStreamableHttp && current.useHttp2,
  ),
};

McpServerSettingsUpdate _mcpServerSettingsUpdate(
  _McpServerEditState state,
  _ServiceConnectionEditScreenState owner,
) => _McpServerEditFormValues.fromOwner(state, owner).toUpdate(state.server);

McpTransportType _selectedMcpTransport(
  _McpServerEditState state,
  _ServiceConnectionEditScreenState owner,
) => _mcpTransportValue(
  owner._mcpTransport ?? _mcpTransportOption(state.server.transport),
  state.server.transport,
);

class const _McpServerEditFormValues({
  required final String name,
  required final String url,
  required final McpTransportType transport,
  required final McpServerAuthMode authMode,
  required final McpServerSecretChange secretChange,
  required final String? secret,
}) {
  new fromOwner(
    _McpServerEditState state,
    _ServiceConnectionEditScreenState owner,
  ) : this(
        name: owner._nameController.text.trim(),
        url: owner._mcpUrlController.text.trim(),
        transport: _selectedMcpTransport(state, owner),
        authMode: _mcpServerEditAuthMode(state, owner),
        secretChange: _mcpSecretChange(
          state,
          _mcpServerEditAuthMode(state, owner),
          owner._mcpSecretController.text.trim(),
        ),
        secret: _mcpServerEditSecret(state, owner),
      );

  McpServerSettingsUpdate toUpdate(McpServerForEdit server) =>
      McpServerSettingsUpdate(
        serverId: server.id,
        name: name,
        url: url,
        transport: transport,
        authMode: authMode,
        secretChange: secretChange,
        secret: secret,
        expectedRevision: server.revision,
        expectedSecretRevision: server.secretRevision,
      );
}

McpServerAuthMode _mcpServerEditAuthMode(
  _McpServerEditState state,
  _ServiceConnectionEditScreenState owner,
) => owner._mcpAuthMode ?? state.server.authMode;

String? _mcpServerEditSecret(
  _McpServerEditState state,
  _ServiceConnectionEditScreenState owner,
) {
  final secret = owner._mcpSecretController.text.trim();
  final authMode = _mcpServerEditAuthMode(state, owner);

  return _mcpSecretChange(state, authMode, secret) == .replace ? secret : null;
}

McpServerSecretChange _mcpSecretChange(
  _McpServerEditState state,
  McpServerAuthMode authMode,
  String secret,
) {
  if (authMode == .none && state.server.authMode != .none) {
    return .clear;
  }
  if (secret.isNotEmpty) return .replace;

  return .preserve;
}

bool _mcpServerCanSave(
  _McpServerEditState state,
  _ServiceConnectionEditScreenState owner,
) {
  if (owner._isSaving ||
      owner._nameController.text.trim().isEmpty ||
      owner._mcpUrlController.text.trim().isEmpty) {
    return false;
  }

  return _mcpAuthCanSave(state, owner);
}

bool _mcpAuthCanSave(
  _McpServerEditState state,
  _ServiceConnectionEditScreenState owner,
) {
  final authMode = owner._mcpAuthMode ?? state.server.authMode;
  final replacing = owner._mcpSecretController.text.trim().isNotEmpty;

  return _canSaveMcpAuthMode(authMode, state.server, replacing);
}

bool _canSaveMcpAuthMode(
  McpServerAuthMode authMode,
  McpServerForEdit server,
  bool replacing,
) => switch (authMode) {
  .oauth => server.authMode == .oauth,
  .bearerToken || .httpHeaders =>
    replacing || (authMode == server.authMode && server.hasSecret),
  .none => true,
};

class const _McpServerEditForm({
  required final _McpServerEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ConnectionEditFormShell(
    children: [
      const _ConnectionEditHeader(
        text: LocaleKeys.service_connections_type_mcp_server,
      ),
      _McpServerEditIdentityInputs(owner: owner),
      _McpServerEditCredentials(state: state, owner: owner),
      _ConnectionEditSaveButton(
        onPressed: () => owner._saveMcpServer(context, state),
        isSaving: owner._isSaving,
        canSave: _mcpServerCanSave(state, owner),
      ),
    ],
  );
}

class const _McpServerEditIdentityInputs({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _McpServerEditNameInput(owner: owner),
      _McpServerEditUrlInput(owner: owner),
      _McpServerEditTransportInput(owner: owner),
    ],
    spacing: .md,
    crossAxisAlignment: .start,
  );
}

class const _McpServerEditCredentials({
  required final _McpServerEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _McpServerEditAuthInput(state: state, owner: owner),
      if (_showsMcpSecret(owner._mcpAuthMode ?? state.server.authMode))
        _McpServerEditSecretInput(state: state, owner: owner),
    ],
    spacing: .md,
    crossAxisAlignment: .start,
  );
}

bool _showsMcpSecret(McpServerAuthMode mode) =>
    mode == .bearerToken || mode == .httpHeaders;

class const _McpServerEditNameInput({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: owner._nameController,
    label: const TextLocale(LocaleKeys.mcp_modal_fields_name_label),
    onChanged: (_) => owner._refreshForm(),
  );
}

class const _McpServerEditUrlInput({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: owner._mcpUrlController,
    label: const TextLocale(LocaleKeys.mcp_modal_fields_url_label),
    keyboardType: .url,
    onChanged: (_) => owner._refreshForm(),
  );
}

class const _McpServerEditTransportInput({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  static const List<AuraDropdownOption<McpTransportTypeOptions>> _options = [
    AuraDropdownOption(
      value: McpTransportTypeOptions.streamableHttp,
      child: TextLocale(LocaleKeys.mcp_modal_transport_streamable_http),
    ),
    AuraDropdownOption(
      value: McpTransportTypeOptions.sse,
      child: TextLocale(LocaleKeys.mcp_modal_transport_sse),
    ),
  ];

  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const AuraText(
        child: TextLocale(LocaleKeys.mcp_modal_fields_transport_label),
        style: .bodySmall,
      ),
      AuraDropdownSelector<McpTransportTypeOptions>(
        options: _options,
        value: owner._mcpTransport,
        onChanged: _onChanged,
      ),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );

  void _onChanged(McpTransportTypeOptions? value) {
    if (value == null) return;
    owner._refreshForm(() => owner._mcpTransport = value);
  }
}

class const _McpServerEditAuthInput({
  required final _McpServerEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        const AuraText(
          child: TextLocale(LocaleKeys.mcp_modal_fields_authentication_label),
          style: .bodySmall,
        ),
        _McpServerEditAuthSelector(
          authMode: state.server.authMode,
          value: owner._mcpAuthMode,
          onChanged: _onChanged,
        ),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
    );
  }

  void _onChanged(McpServerAuthMode? value) {
    if (value == null) return;
    owner._refreshForm(() => owner._mcpAuthMode = value);
  }
}

class const _McpServerEditAuthSelector({
  required final McpServerAuthMode authMode,
  required final McpServerAuthMode? value,
  required final ValueChanged<McpServerAuthMode?> onChanged,
}) extends StatelessWidget {
  static const List<AuraDropdownOption<McpServerAuthMode>> _commonOptions = [
    AuraDropdownOption(
      value: McpServerAuthMode.none,
      child: TextLocale(LocaleKeys.mcp_modal_auth_none),
    ),
    AuraDropdownOption(
      value: McpServerAuthMode.bearerToken,
      child: TextLocale(LocaleKeys.mcp_modal_auth_bearer_token),
    ),
    AuraDropdownOption(
      value: McpServerAuthMode.httpHeaders,
      child: TextLocale(LocaleKeys.mcp_modal_auth_http_headers),
    ),
  ];

  @override
  Widget build(BuildContext context) => AuraDropdownSelector<McpServerAuthMode>(
    options: [
      ..._commonOptions,
      if (authMode == .oauth)
        const AuraDropdownOption(
          value: McpServerAuthMode.oauth,
          child: TextLocale(LocaleKeys.mcp_modal_auth_oauth),
        ),
    ],
    value: value,
    onChanged: onChanged,
  );
}

class const _McpServerEditSecretInput({
  required final _McpServerEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraInput(
    controller: owner._mcpSecretController,
    placeholder: _savedSecretPlaceholder(context),
    label: Text(_secretFieldLabel(context)),
    hint: _savedSecretHint(context),
    keyboardType: .visiblePassword,
    obscureText: true,
    onChanged: (_) => owner._refreshForm(),
  );

  Text? _savedSecretPlaceholder(BuildContext context) => state.server.hasSecret
      ? Text(LocaleKeys.mcp_edit_secret_saved.tr(context: context))
      : null;

  Text? _savedSecretHint(BuildContext context) => state.server.hasSecret
      ? Text(LocaleKeys.mcp_edit_secret_hint.tr(context: context))
      : null;

  String _secretFieldLabel(BuildContext context) {
    final isHeaders =
        (owner._mcpAuthMode ?? state.server.authMode) == .httpHeaders;
    final labelKey = isHeaders
        ? LocaleKeys.mcp_modal_fields_http_headers_label
        : LocaleKeys.mcp_modal_fields_bearer_token_label;

    return labelKey.tr(context: context);
  }
}

class const _SkillCredentialEditForm({
  required final _SkillCredentialEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ConnectionEditFormShell(
      children: [
        _ConnectionEditHeader(text: state.definition.title),
        _SkillCredentialEditFields(state: state, owner: owner),
        _SkillCredentialEditSaveButton(owner: owner),
      ],
    );
  }
}

class const _ConnectionEditFormShell({required final List<Widget> children})
    extends StatelessWidget {
  static const _contentPadding = 12.0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(
        _contentPadding,
      ).copyWith(bottom: BottomPadding.of(context, minimum: _contentPadding)),
      children: [
        AuraCard(
          child: AuraColumn(
            children: children,
            spacing: .md,
            crossAxisAlignment: .start,
          ),
        ),
      ],
      keyboardDismissBehavior: .onDrag,
    );
  }
}

class const _ConnectionEditSaveButton({
  required final VoidCallback onPressed,
  required final bool isSaving,
  required final bool canSave,
  final String label = LocaleKeys.common_save,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: AuraButton(
        onPressed: onPressed,
        child: TextLocale(label),
        isLoading: isSaving,
        disabled: isSaving || !canSave,
      ),
    );
  }
}

class const _ConnectionEditHeader({required final String text})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraText(child: Text(text), style: .heading6);
  }
}

class const _SkillCredentialEditSaveButton({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ConnectionEditSaveButton(
      onPressed: () => owner._saveSkillCredential(context),
      isSaving: owner._isSaving,
      canSave: owner._nameController.text.trim().isNotEmpty,
    );
  }
}

class const _SkillCredentialEditFields({
  required final _SkillCredentialEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final attributes = SkillCredentialAttributeDefinition.parseMap(
      state.definition.attributesJson,
    );

    return AuraColumn(
      children: [
        _SkillCredentialNameInput(
          owner: owner,
          hasAttributes: attributes.isNotEmpty,
        ),
        _SkillCredentialEditAttributes(
          state: state,
          owner: owner,
          attributes: attributes,
        ),
      ],
      spacing: .md,
      crossAxisAlignment: .start,
    );
  }
}

class const _SkillCredentialNameInput({
  required final _ServiceConnectionEditScreenState owner,
  required final bool hasAttributes,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: owner._nameController,
      label: Text(LocaleKeys.skill_credentials_name_label.tr(context: context)),
      textInputAction: hasAttributes ? .next : .done,
      onChanged: (_) => owner._refreshForm(),
      onSubmitted: _onSubmitted(context),
    );
  }

  ValueChanged<String>? _onSubmitted(BuildContext context) =>
      hasAttributes ||
          owner._isSaving ||
          owner._nameController.text.trim().isEmpty
      ? null
      : (_) => owner._saveSkillCredential(context);
}

class const _SkillCredentialEditAttributes({
  required final _SkillCredentialEditState state,
  required final _ServiceConnectionEditScreenState owner,
  required final Map<String, SkillCredentialAttributeDefinition> attributes,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillCredentialEditAttributeColumn(
    state: state,
    owner: owner,
    attributes: attributes,
  );
}

class const _SkillCredentialEditAttributeColumn({
  required final _SkillCredentialEditState state,
  required final _ServiceConnectionEditScreenState owner,
  required final Map<String, SkillCredentialAttributeDefinition> attributes,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lastKey = attributes.keys.lastOrNull;

    return AuraColumn(
      children: [
        for (final entry in attributes.entries)
          _SkillCredentialEditAttributeInputRow(
            entry: entry,
            state: state,
            owner: owner,
            isLast: entry.key == lastKey,
          ),
      ],
      spacing: .md,
      crossAxisAlignment: .start,
    );
  }
}

class const _SkillCredentialEditAttributeInputRow({
  required final MapEntry<String, SkillCredentialAttributeDefinition> entry,
  required final _SkillCredentialEditState state,
  required final _ServiceConnectionEditScreenState owner,
  required final bool isLast,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _SkillCredentialAttributeInput(
    entry,
    editState: state,
    owner: owner,
    textInputAction: isLast ? .done : .next,
    onSubmitted: _onSubmitted(context),
  );

  ValueChanged<String>? _onSubmitted(BuildContext context) =>
      isLast && !owner._isSaving && owner._nameController.text.trim().isNotEmpty
      ? (_) => owner._saveSkillCredential(context)
      : null;
}

abstract class _SkillCredentialAttributeInput extends StatelessWidget {
  factory(
    MapEntry<String, SkillCredentialAttributeDefinition> entry, {
    required _SkillCredentialEditState editState,
    required _ServiceConnectionEditScreenState owner,
    required TextInputAction textInputAction,
    required ValueChanged<String>? onSubmitted,
  }) {
    if (entry.value.secret) {
      return _SecretAttributeInput.fromEntry(
        entry,
        editState,
        owner,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
      );
    }

    return _NonSecretAttributeInput.fromEntry(
      entry,
      owner,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
    );
  }
  const new _();
}

class _NonSecretAttributeInput extends _SkillCredentialAttributeInput {
  const new({
    required this.name,
    required this.definition,
    required this.controller,
    required this.onChanged,
    required this.textInputAction,
    required this.onSubmitted,
  }) : super._();

  new fromEntry(
    MapEntry<String, SkillCredentialAttributeDefinition> entry,
    _ServiceConnectionEditScreenState owner, {
    required TextInputAction textInputAction,
    required ValueChanged<String>? onSubmitted,
  }) : this(
         name: entry.key,
         definition: entry.value,
         controller: owner._nonSecretControllers[entry.key],
         onChanged: owner._refreshForm,
         textInputAction: textInputAction,
         onSubmitted: onSubmitted,
       );

  final String name;
  final SkillCredentialAttributeDefinition definition;
  final TextEditingController? controller;
  final VoidCallback onChanged;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final description = definition.description;

    return AuraInput(
      controller: controller,
      label: Text(name),
      hint: description.isEmpty ? null : Text(description),
      isRequired: !definition.optional,
      textInputAction: textInputAction,
      onChanged: (_) => onChanged(),
      onSubmitted: onSubmitted,
    );
  }
}

class _SecretAttributeInput extends _SkillCredentialAttributeInput {
  const new({
    required this.name,
    required this.definition,
    required this.state,
    required this.controller,
    required this.clearedSecrets,
    required this.onChanged,
    required this.textInputAction,
    required this.onSubmitted,
  }) : super._();

  new fromEntry(
    MapEntry<String, SkillCredentialAttributeDefinition> entry,
    _SkillCredentialEditState editState,
    _ServiceConnectionEditScreenState owner, {
    required TextInputAction textInputAction,
    required ValueChanged<String>? onSubmitted,
  }) : this(
         name: entry.key,
         definition: entry.value,
         state: editState.credential.secretAttributes[entry.key],
         controller: owner._secretControllers[entry.key]!,
         clearedSecrets: owner._clearedSecrets,
         onChanged: owner._refreshForm,
         textInputAction: textInputAction,
         onSubmitted: onSubmitted,
       );

  final String name;
  final SkillCredentialAttributeDefinition definition;
  final SkillCredentialSecretState? state;
  final TextEditingController controller;
  final Set<String> clearedSecrets;
  final VoidCallback onChanged;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) =>
      _SecretAttributeAuraInput(this, context);

  void _onChanged(String _) {
    final _ = clearedSecrets.remove(name);
    onChanged();
  }

  void _clearSecret() {
    controller.clear();
    final _ = clearedSecrets.add(name);
    onChanged();
  }
}

class _SecretAttributeAuraInput extends AuraInput {
  new(_SecretAttributeInput input, BuildContext context)
    : super(
        controller: input.controller,
        placeholder: switch (_secretPlaceholder(context, input.state)) {
          final value? => Text(value),
          _ => null,
        },
        label: Text(input.name),
        hint: _descriptionHint(input.definition.description),
        isRequired: !input.definition.optional,
        suffixIcon: input.definition.optional
            ? _SecretAttributeClearButton(onPressed: input._clearSecret)
            : null,
        keyboardType: .visiblePassword,
        obscureText: true,
        textInputAction: input.textInputAction,
        onChanged: input._onChanged,
        onSubmitted: input.onSubmitted,
      );
}

String? _secretPlaceholder(
  BuildContext context,
  SkillCredentialSecretState? state,
) {
  if (state?.hasValue != true) return null;
  final suffix = state?.keySuffix == null ? '' : ' ****${state?.keySuffix}';

  return '${LocaleKeys.skill_credentials_secret_saved.tr(context: context)}'
      '$suffix';
}

Text? _descriptionHint(String description) {
  return description.isEmpty ? null : Text(description);
}

class const _SecretAttributeClearButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.clear,
      onPressed: onPressed,
      tooltip: LocaleKeys.skill_credentials_clear_secret.tr(context: context),
    );
  }
}

class const _ModelProviderEditForm({
  required final _ModelProviderEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final connection = state.connection;

    return _ConnectionEditFormShell(
      children: [
        _ConnectionEditHeader(text: connection.modelId),
        _ModelProviderEditFields(
          state: state,
          owner: owner,
          suffix: connection.keySuffix,
        ),
        _ModelProviderVerificationError(owner: owner),
        _ModelProviderVerifyButton(state: state, owner: owner),
        _ModelProviderEditSaveButton(state: state, owner: owner),
      ],
    );
  }
}

class const _ModelProviderEditFields({
  required final _ModelProviderEditState state,
  required final _ServiceConnectionEditScreenState owner,
  required final String? suffix,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _ModelProviderNameInput(owner: owner),
        _ModelProviderKeyInput(owner: owner, suffix: suffix),
        _ModelProviderUrlInput(owner: owner, state: state),
      ],
      spacing: .md,
      crossAxisAlignment: .start,
    );
  }
}

class const _ModelProviderEditSaveButton({
  required final _ModelProviderEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ConnectionEditSaveButton(
      onPressed: () => owner._saveModelProvider(context),
      isSaving: owner._isSaving,
      canSave: owner._modelProviderCanSave(state),
      label: LocaleKeys.models_screens_add_provider_save_changes,
    );
  }
}

class const _ModelProviderVerifyButton({
  required final _ModelProviderEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => owner._verifyModelProvider(context, state),
    child: const TextLocale(LocaleKeys.mcp_modal_test_connection),
    variant: .outlined,
    isLoading: owner._isTestingModelProvider,
    isFullWidth: true,
    disabled: owner._isSaving || owner._isTestingModelProvider,
  );
}

class const _ModelProviderVerificationError({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final message = owner._modelProviderVerificationErrorMessage;
    if (message == null) return const SizedBox.shrink();

    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: context.auraColors.error),
    );
  }
}

class const _ModelProviderNameInput({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: owner._nameController,
      label: const TextLocale(
        LocaleKeys.models_screens_add_provider_fields_name_label,
      ),
      textInputAction: .next,
      onChanged: (_) => owner._refreshForm(),
    );
  }
}

class const _ModelProviderKeyInput({
  required final _ServiceConnectionEditScreenState owner,
  required final String? suffix,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _ModelProviderKeyAuraInput(this, context);
}

class _ModelProviderKeyAuraInput extends AuraInput {
  new(_ModelProviderKeyInput input, BuildContext context)
    : super(
        controller: input.owner._modelKeyController,
        placeholder: Text(_modelProviderKeyPlaceholder(context, input.suffix)),
        label: const TextLocale(
          LocaleKeys.models_screens_add_provider_fields_key_label,
        ),
        keyboardType: .visiblePassword,
        obscureText: true,
        textInputAction: .next,
        onChanged: (_) => input.owner._invalidateModelProviderVerification(),
      );
}

class const _ModelProviderUrlInput({
  required final _ServiceConnectionEditScreenState owner,
  required final _ModelProviderEditState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: owner._modelUrlController,
      label: const TextLocale(
        LocaleKeys.models_screens_add_provider_fields_url_label,
      ),
      keyboardType: .url,
      textInputAction: .done,
      onChanged: (_) => owner._invalidateModelProviderVerification(),
      onSubmitted: owner._modelProviderCanSave(state)
          ? (_) => owner._saveModelProvider(context)
          : null,
    );
  }
}

class const _GenericServiceConnectionEditForm({
  required final _GenericServiceConnectionEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final connection = state.connection;

    return _ConnectionEditFormShell(
      children: [
        _ConnectionEditHeader(text: connection.serviceId),
        _GenericServiceConnectionEditFields(state: state, owner: owner),
        _GenericServiceConnectionEditSaveButton(state: state, owner: owner),
      ],
    );
  }
}

class const _GenericServiceConnectionEditFields({
  required final _GenericServiceConnectionEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraColumn(
      children: [
        _GenericServiceConnectionNameInput(owner: owner),
        _GenericServiceConnectionSecretInput(state: state, owner: owner),
      ],
      spacing: .md,
      crossAxisAlignment: .start,
    );
  }
}

class const _GenericServiceConnectionEditSaveButton({
  required final _GenericServiceConnectionEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _ConnectionEditSaveButton(
      onPressed: () => owner._saveGenericConnection(context, state),
      isSaving: owner._isSaving,
      canSave: owner._nameController.text.trim().isNotEmpty,
    );
  }
}

class const _GenericServiceConnectionNameInput({
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraInput(
      controller: owner._nameController,
      label: Text(LocaleKeys.skill_credentials_name_label.tr(context: context)),
      textInputAction: .next,
      onChanged: (_) => owner._refreshForm(),
    );
  }
}

class const _GenericServiceConnectionSecretInput({
  required final _GenericServiceConnectionEditState state,
  required final _ServiceConnectionEditScreenState owner,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      _GenericServiceConnectionSecretAuraInput(this, context);

  void _clearSecret() {
    owner._modelKeyController.clear();
    final _ = owner._clearedSecrets.add('secret');
    owner._refreshForm();
  }

  void _onChanged(String _) {
    final _ = owner._clearedSecrets.remove('secret');
    owner._refreshForm();
  }
}

class _GenericServiceConnectionSecretAuraInput extends AuraInput {
  new(_GenericServiceConnectionSecretInput input, BuildContext context)
    : super(
        controller: input.owner._modelKeyController,
        placeholder: switch (_genericSecretPlaceholder(
          context,
          input.state.connection.hasSecret &&
              !input.owner._clearedSecrets.contains('secret'),
          input.state.connection.keySuffix,
        )) {
          final value? => Text(value),
          _ => null,
        },
        label: Text(
          _genericCredentialValueLabel(
            context,
            input.state.connection.serviceId,
          ),
        ),
        suffixIcon: _GenericSecretClearButton(onPressed: input._clearSecret),
        keyboardType: .visiblePassword,
        obscureText: true,
        textInputAction: .done,
        onChanged: input._onChanged,
        onSubmitted:
            !input.owner._isSaving &&
                input.owner._nameController.text.trim().isNotEmpty
            ? (_) => input.owner._saveGenericConnection(context, input.state)
            : null,
      );
}

String _modelProviderKeyPlaceholder(BuildContext context, String? suffix) {
  final label = LocaleKeys.skill_credentials_secret_saved.tr(context: context);

  return suffix == null ? label : '$label ****$suffix';
}

class const _GenericSecretClearButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraIconButton(
      icon: Icons.clear,
      onPressed: onPressed,
      tooltip: LocaleKeys.skill_credentials_clear_secret.tr(context: context),
    );
  }
}

String? _genericSecretPlaceholder(
  BuildContext context,
  bool hasSavedSecret,
  String? suffix,
) {
  if (!hasSavedSecret) return null;
  final label = LocaleKeys.skill_credentials_secret_saved.tr(context: context);
  final suffixText = suffix == null ? '' : ' ****$suffix';

  return '$label$suffixText';
}

String _genericCredentialValueLabel(BuildContext context, String serviceId) {
  final key = switch (serviceId) {
    'searxng' => LocaleKeys.service_connections_create_base_url_label,
    _ => LocaleKeys.service_connections_create_api_key_label,
  };

  return key.tr(context: context);
}
