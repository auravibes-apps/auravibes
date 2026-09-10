// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/features/models/models/add_model_provider_model.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/models/services/cloud_model_gateway.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/codex_oauth_service.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_app/utils/open_system_browser.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod/riverpod.dart' show Provider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_model_provider_state.g.dart';

typedef _OAuthModelProviderRequest = ({
  ModelConnectionStore repo,
  String name,
  String modelId,
  ModelProviderAuthMode authMode,
  CodexOAuthMethod? codexOAuthMethod,
  void Function(CodexDeviceCode deviceCode)? onCodexDeviceCode,
  bool Function()? isCodexOAuthCancelled,
});

typedef _ModelConnectionRequest = ({
  ModelConnectionStore repo,
  WorkspaceSession session,
  String name,
  String modelId,
  ModelProviderAuthMode authMode,
  CodexOAuthMethod? codexOAuthMethod,
  void Function(CodexDeviceCode deviceCode)? onCodexDeviceCode,
  bool Function()? isCodexOAuthCancelled,
});

typedef _LoadAndAddRequest = ({
  ({String name, String modelId}) input,
  CodexOAuthMethod? codexOAuthMethod,
  void Function(CodexDeviceCode deviceCode)? onCodexDeviceCode,
  bool Function()? isCodexOAuthCancelled,
});

typedef _CapabilityRequest = ({
  WorkspaceSession session,
  String modelId,
  ModelProviderAuthMode authMode,
  CodexOAuthMethod? codexOAuthMethod,
});

final _log = Logger('add_model_providers');
final codexOAuthServiceProvider = Provider<CodexOAuthService>(
  (_) => CodexOAuthService(),
);
final openCodexAuthorizationProvider = Provider<Future<void> Function(Uri)>(
  (_) => OpenSystemBrowser.call,
);

@riverpod
class AddModelProviderState extends _$AddModelProviderState {
  String _workspaceId = '';

  AddModelProviderModel get _value => state;
  Ref get _providerRef => ref;
  String get _workspace => _workspaceId;
  set _value(AddModelProviderModel value) => state = value;

  @override
  AddModelProviderModel build(String workspaceId) {
    _workspaceId = workspaceId;

    return const AddModelProviderModel();
  }
}

extension AddModelProviderStateFields on AddModelProviderState {
  void setName(String newName) {
    _value = _value.copyWith(name: newName);
  }

  void setKey(String newKey) {
    _value = _value.copyWith(key: newKey);
  }

  void setModel(String? newValue) {
    _value = _stateForModel(newValue);
  }

  AddModelProviderModel _stateForModel(String? modelId) {
    final model = _modelForId(modelId);
    final authMode = _authModeFor(modelId);

    return _value.copyWith(
      modelId: modelId,
      name: model?.name ?? _providerNameFor(modelId),
      authMode: authMode,
      key: _value.authMode == authMode ? _value.key : null,
    );
  }

  ModelProviderAuthMode _authModeFor(String? modelId) =>
      ModelProviderOAuthProfiles.isCodexProvider(modelId) ? .oauth2 : .apiKey;

  String? _providerNameFor(String? modelId) =>
      ModelProviderOAuthProfiles.isCodexProvider(modelId)
      ? ModelProviderOAuthProfiles.displayName
      : null;

  ApiModelProviderEntity? _modelForId(String? modelId) => _providerRef
      .watch(apiModelProvidersProvider(workspaceId: _workspace))
      .value
      ?.firstWhereOrNull((model) => model.id == modelId);

  void setUrl(String? newUrl) {
    _value = _value.copyWith(url: newUrl);
  }
}

extension AddModelProviderStateActions on AddModelProviderState {
  Future<ModelConnectionEntity?> addModelProvider({
    CodexOAuthMethod? codexOAuthMethod,
    void Function(CodexDeviceCode deviceCode)? onCodexDeviceCode,
    bool Function()? isCodexOAuthCancelled,
  }) async {
    final input = _validatedInput();
    if (input == null) return null;

    return _addValidatedModelProvider(input, (
      codexOAuthMethod: codexOAuthMethod,
      onCodexDeviceCode: onCodexDeviceCode,
      isCodexOAuthCancelled: isCodexOAuthCancelled,
    ));
  }

  Future<ModelConnectionEntity?> _addValidatedModelProvider(
    ({String name, String modelId}) input,
    ({
      CodexOAuthMethod? codexOAuthMethod,
      void Function(CodexDeviceCode deviceCode)? onCodexDeviceCode,
      bool Function()? isCodexOAuthCancelled,
    })
    oauth,
  ) async {
    try {
      return await _loadAndAddModelConnection(_loadRequest(input, oauth));
    } on CodexOAuthCanceledException {
      return null;
    } on Exception catch (e, s) {
      _log.severe('addModelProvider error', e, s);
      rethrow;
    }
  }

  Future<ModelConnectionEntity?> _loadAndAddModelConnection(
    _LoadAndAddRequest request,
  ) async {
    final input = request.input;
    final session = await this._workspaceSession();
    _requireCapabilities((
      session: session,
      modelId: input.modelId,
      authMode: _value.authMode,
      codexOAuthMethod: request.codexOAuthMethod,
    ));

    return _addModelConnection(await this._connectionRequest(request, session));
  }

  ({String name, String modelId})? _validatedInput() {
    if (!_value.isValid()) return null;

    final name = _value.name;
    final modelId = _value.modelId;
    if (name == null || modelId == null) return null;

    return (name: name, modelId: modelId);
  }
}

_LoadAndAddRequest _loadRequest(
  ({String name, String modelId}) input,
  ({
    CodexOAuthMethod? codexOAuthMethod,
    void Function(CodexDeviceCode deviceCode)? onCodexDeviceCode,
    bool Function()? isCodexOAuthCancelled,
  })
  oauth,
) => (
  input: input,
  codexOAuthMethod: oauth.codexOAuthMethod,
  onCodexDeviceCode: oauth.onCodexDeviceCode,
  isCodexOAuthCancelled: oauth.isCodexOAuthCancelled,
);

extension _AddModelProviderStateDependencies on AddModelProviderState {
  Future<_ModelConnectionRequest> _connectionRequest(
    _LoadAndAddRequest request,
    WorkspaceSession session,
  ) async {
    final input = request.input;
    return (
      repo: await this._modelConnectionStore(),
      session: session,
      name: input.name,
      modelId: input.modelId,
      authMode: _value.authMode,
      codexOAuthMethod: request.codexOAuthMethod,
      onCodexDeviceCode: request.onCodexDeviceCode,
      isCodexOAuthCancelled: request.isCodexOAuthCancelled,
    );
  }

  Future<WorkspaceSession> _workspaceSession() =>
      _providerRef.read(workspaceSessionForRouteProvider(_workspace).future);

  Future<ModelConnectionStore> _modelConnectionStore() =>
      _providerRef.read(modelConnectionStoreProvider(_workspace).future);

  void _requireCapabilities(_CapabilityRequest request) {
    final capabilities = request.session.capabilities;
    capabilities.require(
      supported: capabilities.modelProviderIds.contains(request.modelId),
    );
    if (request.authMode != ModelProviderAuthMode.oauth2) return;

    capabilities.require(
      supported: _supportsOAuth(capabilities, request.codexOAuthMethod),
    );
  }

  bool _supportsOAuth(
    WorkspaceCapabilities capabilities,
    CodexOAuthMethod? method,
  ) => method == CodexOAuthMethod.deviceCode
      ? capabilities.modelDeviceOAuth
      : capabilities.modelBrowserOAuth;
}

extension on AddModelProviderState {
  Future<ModelConnectionEntity?> _addModelConnection(
    _ModelConnectionRequest request,
  ) {
    if (request.authMode == ModelProviderAuthMode.oauth2) {
      return _addOAuthModelProviderForSession(
        request.session,
        _oauthRequest(request),
      );
    }

    return this._addApiKeyModelProvider(
      request.repo,
      request.name,
      request.modelId,
    );
  }

  _OAuthModelProviderRequest _oauthRequest(_ModelConnectionRequest request) => (
    repo: request.repo,
    name: request.name,
    modelId: request.modelId,
    authMode: request.authMode,
    codexOAuthMethod: request.codexOAuthMethod,
    onCodexDeviceCode: request.onCodexDeviceCode,
    isCodexOAuthCancelled: request.isCodexOAuthCancelled,
  );

  Future<ModelConnectionEntity?> _addOAuthModelProviderForSession(
    WorkspaceSession session,
    _OAuthModelProviderRequest request,
  ) {
    if (session.cloud != null) {
      return this._addCloudOAuthModelProvider(request);
    }

    return this._addOAuthModelProvider(request);
  }
}

extension on AddModelProviderState {
  Future<ModelConnectionEntity> _addCloudOAuthModelProvider(
    _OAuthModelProviderRequest request,
  ) async {
    final gateway = await _providerRef.read(
      cloudWorkspaceStateGatewayForWorkspaceProvider(_workspace).future,
    );
    if (gateway == null) throw StateError('Cloud workspace unavailable');
    final connection = await _createCloudConnection(request);
    await _startCloudOAuth(CloudModelGateway(gateway), connection.id);

    return connection;
  }

  Future<ModelConnectionEntity> _createCloudConnection(
    _OAuthModelProviderRequest request,
  ) => request.repo.createModelConnection(
    .new(
      name: request.name,
      workspaceId: _workspace,
      modelId: request.modelId,
      authMode: request.authMode,
      url: _value.url,
    ),
  );

  Future<void> _startCloudOAuth(CloudModelGateway gateway, String id) async {
    final oauth = await gateway.startCodexOAuth(connectionId: id);
    await _providerRef.read(openCodexAuthorizationProvider)(
      .parse(oauth.authorizationUrl),
    );
  }

  Future<ModelConnectionEntity?> _addApiKeyModelProvider(
    ModelConnectionStore repo,
    String name,
    String modelId,
  ) async {
    final key = _value.key;
    if (key == null || key.trim().isEmpty) return null;

    return await repo.createModelConnection(
      .new(
        name: name,
        workspaceId: _workspace,
        modelId: modelId,
        key: key,
        url: _value.url,
      ),
    );
  }

  Future<ModelConnectionEntity> _addOAuthModelProvider(
    _OAuthModelProviderRequest request,
  ) async {
    _validateOAuthProfile(request.modelId);
    _validateOAuthClient();
    final modelIds = await _codexRuntimeModelIds();
    final token = await _authenticateCodex(request);
    return _createOAuthConnection(request, modelIds, token);
  }
}

extension on AddModelProviderState {
  void _validateOAuthProfile(String modelId) {
    if (ModelProviderOAuthProfiles.isCodexProvider(modelId)) return;

    throw ModelConnectionException(
      LocaleKeys.models_screens_add_provider_errors_oauth_profile_not_found.tr(
        args: [modelId],
      ),
    );
  }

  void _validateOAuthClient() {
    if (ModelProviderOAuthProfiles.clientId.isNotEmpty) return;

    throw ModelConnectionException(
      LocaleKeys.models_screens_add_provider_errors_oauth_client_id_missing.tr(
        args: [ModelProviderOAuthProfiles.displayName],
      ),
    );
  }

  Future<ModelConnectionEntity> _createOAuthConnection(
    _OAuthModelProviderRequest request,
    List<String> modelIds,
    OAuthTokenEntity token,
  ) => request.repo.createModelConnection(
    .new(
      name: request.name,
      workspaceId: _workspace,
      modelId: request.modelId,
      authMode: request.authMode,
      url: _value.url,
      oauthToken: token,
      oauthMetadata: _oauthMetadata(token),
      modelIds: modelIds,
    ),
  );

  ServiceConnectionMetadata _oauthMetadata(OAuthTokenEntity token) =>
      ServiceConnectionMetadata(
        clientId: ModelProviderOAuthProfiles.clientId,
        issuer: ModelProviderOAuthProfiles.issuer,
        authorizationEndpoint: ModelProviderOAuthProfiles.authorizationEndpoint,
        tokenEndpoint: ModelProviderOAuthProfiles.tokenEndpoint,
        scopes: ModelProviderOAuthProfiles.scopes,
        accountId: CodexOAuthService.accountIdFromToken(token),
        provider: ModelProviderOAuthProfiles.providerId,
      );
}

extension on AddModelProviderState {
  Future<OAuthTokenEntity> _authenticateCodex(
    _OAuthModelProviderRequest request,
  ) async {
    final oauthService = _providerRef.read(codexOAuthServiceProvider);
    final isCancelled = request.isCodexOAuthCancelled;
    final token = await _authenticate(oauthService, request);

    if (isCancelled?.call() ?? false) {
      throw const CodexOAuthCanceledException();
    }

    return token;
  }

  Future<OAuthTokenEntity> _authenticate(
    CodexOAuthService service,
    _OAuthModelProviderRequest request,
  ) => switch (request.codexOAuthMethod) {
    .deviceCode => service.authenticateWithDeviceCode(
      onDeviceCode: request.onCodexDeviceCode,
      isCancelled: request.isCodexOAuthCancelled,
    ),
    _ => service.authenticateWithBrowser(
      isCancelled: request.isCodexOAuthCancelled,
    ),
  };

  Future<List<String>> _codexRuntimeModelIds() async {
    final catalog = await _providerRef.read(
      modelCatalogStoreProvider(_workspace).future,
    );
    final openAIModels = await catalog.getModelsByProvider('openai');
    return _requireRuntimeModelIds(
      openAIModels
          .where((model) => model.isCodexRuntimeModel)
          .map((model) => model.id)
          .toList(),
    );
  }

  List<String> _requireRuntimeModelIds(List<String> modelIds) {
    if (modelIds.isEmpty) {
      throw ModelConnectionException(
        LocaleKeys.models_screens_add_provider_errors_openai_catalog_unavailable
            .tr(),
      );
    }

    return modelIds;
  }
}

final addCredentialsModelMutationProvider = Mutation<void>();
