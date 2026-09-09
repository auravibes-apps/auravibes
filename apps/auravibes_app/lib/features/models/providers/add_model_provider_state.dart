// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/data/repositories/model_connection_repository.dart';
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

  void setName(String newName) {
    state = state.copyWith(name: newName);
  }

  void setKey(String newKey) {
    state = state.copyWith(key: newKey);
  }

  void setModel(String? newValue) {
    final models = ref
        .watch(apiModelProvidersProvider(workspaceId: _workspaceId))
        .value;
    final model = models?.firstWhereOrNull((element) {
      return element.id == newValue;
    });
    final nextAuthMode = ModelProviderOAuthProfiles.isCodexProvider(newValue)
        ? ModelProviderAuthMode.oauth2
        : ModelProviderAuthMode.apiKey;
    final authModeChanged = state.authMode != nextAuthMode;
    state = state.copyWith(
      modelId: newValue,
      name:
          model?.name ??
          (ModelProviderOAuthProfiles.isCodexProvider(newValue)
              ? ModelProviderOAuthProfiles.displayName
              : null),
      authMode: nextAuthMode,
      key: authModeChanged ? null : state.key,
    );
  }

  void setUrl(String? newUrl) {
    state = state.copyWith(url: newUrl);
  }

  Future<ModelConnectionEntity?> addModelProvider({
    CodexOAuthMethod? codexOAuthMethod,
    void Function(CodexDeviceCode deviceCode)? onCodexDeviceCode,
    bool Function()? isCodexOAuthCancelled,
  }) async {
    final input = _validatedInput();
    if (input == null) return null;

    try {
      final authMode = state.authMode;
      final session = await ref.read(
        workspaceSessionForRouteProvider(_workspaceId).future,
      );
      _requireCapabilities(
        session: session,
        modelId: input.modelId,
        authMode: authMode,
        codexOAuthMethod: codexOAuthMethod,
      );
      final repo = await ref.read(
        modelConnectionStoreProvider(_workspaceId).future,
      );

      return await _addModelConnection(
        repo: repo,
        session: session,
        name: input.name,
        modelId: input.modelId,
        authMode: authMode,
        codexOAuthMethod: codexOAuthMethod,
        onCodexDeviceCode: onCodexDeviceCode,
        isCodexOAuthCancelled: isCodexOAuthCancelled,
      );
    } on CodexOAuthCanceledException {
      return null;
    } on Exception catch (e, s) {
      _log.severe('addModelProvider error', e, s);
      rethrow;
    }
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

  Future<ModelConnectionEntity?> _addModelConnection({
    required ModelConnectionStore repo,
    required WorkspaceSession session,
    required String name,
    required String modelId,
    required ModelProviderAuthMode authMode,
    required CodexOAuthMethod? codexOAuthMethod,
    required void Function(CodexDeviceCode deviceCode)? onCodexDeviceCode,
    required bool Function()? isCodexOAuthCancelled,
  }) {
    if (authMode == ModelProviderAuthMode.oauth2) {
      return _addOAuthModelProviderForSession(
        repo,
        session,
        name,
        modelId,
        authMode,
        codexOAuthMethod,
        onCodexDeviceCode,
        isCodexOAuthCancelled,
      );
    }

    return _addApiKeyModelProvider(repo, name, modelId);
  }

  Future<ModelConnectionEntity?> _addOAuthModelProviderForSession(
    ModelConnectionStore repo,
    WorkspaceSession session,
    String name,
    String modelId,
    ModelProviderAuthMode authMode,
    CodexOAuthMethod? codexOAuthMethod,
    void Function(CodexDeviceCode deviceCode)? onCodexDeviceCode,
    bool Function()? isCodexOAuthCancelled,
  ) {
    if (session.cloud != null) {
      return _addCloudOAuthModelProvider(repo, name, modelId, authMode);
    }

    return _addOAuthModelProvider(
      repo,
      name,
      modelId,
      authMode,
      codexOAuthMethod,
      onCodexDeviceCode,
      isCodexOAuthCancelled,
    );
  }

  Future<ModelConnectionEntity> _addCloudOAuthModelProvider(
    ModelConnectionStore repo,
    String name,
    String modelId,
    ModelProviderAuthMode authMode,
  ) async {
    final gateway = await ref.read(
      cloudWorkspaceStateGatewayForWorkspaceProvider(_workspaceId).future,
    );
    if (gateway == null) throw StateError('Cloud workspace unavailable');
    final connection = await repo.createModelConnection(
      .new(
        name: name,
        workspaceId: _workspaceId,
        modelId: modelId,
        authMode: authMode,
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
    ModelConnectionStore repo,
    String name,
    String modelId,
    ModelProviderAuthMode authMode,
    CodexOAuthMethod? codexOAuthMethod,
    void Function(CodexDeviceCode deviceCode)? onCodexDeviceCode,
    bool Function()? isCodexOAuthCancelled,
  ) async {
    if (!ModelProviderOAuthProfiles.isCodexProvider(modelId)) {
      throw ModelConnectionException(
        LocaleKeys.models_screens_add_provider_errors_oauth_profile_not_found
            .tr(args: [modelId]),
      );
    }
    if (ModelProviderOAuthProfiles.clientId.isEmpty) {
      throw ModelConnectionException(
        LocaleKeys.models_screens_add_provider_errors_oauth_client_id_missing
            .tr(args: [ModelProviderOAuthProfiles.displayName]),
      );
    }
    final modelIds = await _codexRuntimeModelIds();
    final oauthService = ref.read(codexOAuthServiceProvider);
    final token = switch (codexOAuthMethod) {
      .deviceCode => await oauthService.authenticateWithDeviceCode(
        onDeviceCode: onCodexDeviceCode,
        isCancelled: isCodexOAuthCancelled,
      ),
      _ => await oauthService.authenticateWithBrowser(
        isCancelled: isCodexOAuthCancelled,
      ),
    };

    if (isCodexOAuthCancelled?.call() ?? false) {
      throw const CodexOAuthCanceledException();
    }

    return await repo.createModelConnection(
      .new(
        name: name,
        workspaceId: _workspaceId,
        modelId: modelId,
        authMode: authMode,
        url: state.url,
        oauthToken: token,
        oauthMetadata: ServiceConnectionMetadata(
          clientId: ModelProviderOAuthProfiles.clientId,
          issuer: ModelProviderOAuthProfiles.issuer,
          authorizationEndpoint:
              ModelProviderOAuthProfiles.authorizationEndpoint,
          tokenEndpoint: ModelProviderOAuthProfiles.tokenEndpoint,
          scopes: ModelProviderOAuthProfiles.scopes,
          accountId: CodexOAuthService.accountIdFromToken(token),
          provider: ModelProviderOAuthProfiles.providerId,
        ),
        modelIds: modelIds,
      ),
    );
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
