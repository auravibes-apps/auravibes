// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth_status.dart';
import 'package:auravibes_app/features/models/models/add_model_provider_model.dart';
import 'package:auravibes_app/features/models/models/model_stores.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/models/services/cloud_model_gateway.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
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

  @override
  AddModelProviderModel build(String workspaceId) {
    _workspaceId = workspaceId;

    return const AddModelProviderModel();
  }
}

extension AddModelProviderStateFields on AddModelProviderState {
  void setName(String newName) {
    state = state.copyWith(name: newName);
  }

  void setKey(String newKey) {
    state = state.copyWith(key: newKey);
  }

  void setModel(String? newValue) {
    state = _stateForModel(newValue);
  }

  AddModelProviderModel _stateForModel(String? modelId) {
    final model = _modelForId(modelId);
    final isCodex = ModelProviderOAuthProfiles.isCodexProvider(modelId);
    final authMode = isCodex
        ? ModelProviderAuthMode.oauth2
        : ModelProviderAuthMode.apiKey;

    return state.copyWith(
      modelId: modelId,
      name:
          model?.name ??
          (isCodex ? ModelProviderOAuthProfiles.displayName : null),
      authMode: authMode,
      key: state.authMode == authMode ? state.key : null,
    );
  }

  ApiModelProviderEntity? _modelForId(String? modelId) => ref
      .watch(apiModelProvidersProvider(workspaceId: _workspaceId))
      .value
      ?.firstWhereOrNull((model) => model.id == modelId);

  void setUrl(String? newUrl) {
    state = state.copyWith(url: newUrl);
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

    try {
      return await _loadAndAddModelConnection((
        input: input,
        codexOAuthMethod: codexOAuthMethod,
        onCodexDeviceCode: onCodexDeviceCode,
        isCodexOAuthCancelled: isCodexOAuthCancelled,
      ));
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
    final authMode = state.authMode;
    final session = await ref.read(
      workspaceSessionForRouteProvider(_workspaceId).future,
    );
    _requireCapabilities(
      session: session,
      modelId: input.modelId,
      authMode: authMode,
      codexOAuthMethod: request.codexOAuthMethod,
    );
    final repo = await ref.read(
      modelConnectionStoreProvider(_workspaceId).future,
    );

    return _addModelConnection((
      repo: repo,
      session: session,
      name: input.name,
      modelId: input.modelId,
      authMode: authMode,
      codexOAuthMethod: request.codexOAuthMethod,
      onCodexDeviceCode: request.onCodexDeviceCode,
      isCodexOAuthCancelled: request.isCodexOAuthCancelled,
    ));
  }

  ({String name, String modelId})? _validatedInput() {
    if (!state.isValid()) return null;

    final name = state.name;
    final modelId = state.modelId;
    if (name == null || modelId == null) return null;

    return (name: name, modelId: modelId);
  }

  void _requireCapabilities({
    required WorkspaceSession session,
    required String modelId,
    required ModelProviderAuthMode authMode,
    required CodexOAuthMethod? codexOAuthMethod,
  }) {
    final capabilities = session.capabilities;
    capabilities.require(
      supported: capabilities.modelProviderIds.contains(modelId),
    );
    if (authMode != ModelProviderAuthMode.oauth2) return;

    capabilities.require(
      supported: codexOAuthMethod == CodexOAuthMethod.deviceCode
          ? capabilities.modelDeviceOAuth
          : capabilities.modelBrowserOAuth,
    );
  }
}

extension on AddModelProviderState {
  Future<ModelConnectionEntity?> _addModelConnection(
    _ModelConnectionRequest request,
  ) {
    if (request.authMode == ModelProviderAuthMode.oauth2) {
      return _addOAuthModelProviderForSession(request.session, (
        repo: request.repo,
        name: request.name,
        modelId: request.modelId,
        authMode: request.authMode,
        codexOAuthMethod: request.codexOAuthMethod,
        onCodexDeviceCode: request.onCodexDeviceCode,
        isCodexOAuthCancelled: request.isCodexOAuthCancelled,
      ));
    }

    return this._addApiKeyModelProvider(
      request.repo,
      request.name,
      request.modelId,
    );
  }

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
    final gateway = await ref.read(
      cloudWorkspaceStateGatewayForWorkspaceProvider(_workspaceId).future,
    );
    if (gateway == null) throw StateError('Cloud workspace unavailable');
    final connection = await request.repo.createModelConnection(
      .new(
        name: request.name,
        workspaceId: _workspaceId,
        modelId: request.modelId,
        authMode: request.authMode,
        url: state.url,
      ),
    );
    final oauth = await CloudModelGateway(gateway)
        .startCodexOAuth(connectionId: connection.id);
    await ref.read(openCodexAuthorizationProvider)(
      .parse(oauth.authorizationUrl),
    );

    return connection;
  }

  Future<ModelConnectionEntity?> _addApiKeyModelProvider(
    ModelConnectionStore repo,
    String name,
    String modelId,
  ) async {
    final key = state.key;
    if (key == null || key.trim().isEmpty) return null;

    return await repo.createModelConnection(
      .new(
        name: name,
        workspaceId: _workspaceId,
        modelId: modelId,
        key: key,
        url: state.url,
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
      workspaceId: _workspaceId,
      modelId: request.modelId,
      authMode: request.authMode,
      url: state.url,
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

  Future<OAuthTokenEntity> _authenticateCodex(
    _OAuthModelProviderRequest request,
  ) async {
    final oauthService = ref.read(codexOAuthServiceProvider);
    final isCancelled = request.isCodexOAuthCancelled;
    final token = switch (request.codexOAuthMethod) {
      .deviceCode => await oauthService.authenticateWithDeviceCode(
        onDeviceCode: request.onCodexDeviceCode,
        isCancelled: isCancelled,
      ),
      _ => await oauthService.authenticateWithBrowser(isCancelled: isCancelled),
    };

    if (isCancelled?.call() ?? false) {
      throw const CodexOAuthCanceledException();
    }

    return token;
  }

  Future<List<String>> _codexRuntimeModelIds() async {
    final catalog = await ref.read(
      modelCatalogStoreProvider(_workspaceId).future,
    );
    final openAIModels = await catalog.getModelsByProvider('openai');
    final modelIds = openAIModels
        .where((model) => model.isCodexRuntimeModel)
        .map((model) => model.id)
        .toList();
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
