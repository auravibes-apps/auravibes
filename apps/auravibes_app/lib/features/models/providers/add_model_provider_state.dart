// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.

import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/service_connection_auth.dart';
import 'package:auravibes_app/domain/repositories/model_connection_repository.dart';
import 'package:auravibes_app/features/models/models/add_model_provider_model.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/services/codex_oauth_service.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_model_provider_state.g.dart';

final _log = Logger('add_model_providers');

@riverpod
class AddModelProviderState extends _$AddModelProviderState {
  String _workspaceId = '';

  @override
  AddModelProviderModel build(String workspaceId) {
    _workspaceId = workspaceId;

    return const AddModelProviderModel();
  }

  void setName(String newName) {
    state = state.copyWith(
      name: newName,
    );
  }

  void setKey(String newKey) {
    state = state.copyWith(
      key: newKey,
    );
  }

  void setModel(String? newValue) {
    final models = ref.watch(apiModelProvidersProvider).value;
    final model = models?.firstWhereOrNull(
      (element) {
        return element.id == newValue;
      },
    );
    final nextAuthMode = isOpenAICodexProvider(newValue)
        ? ModelProviderAuthMode.oauth2
        : ModelProviderAuthMode.apiKey;
    final authModeChanged = state.authMode != nextAuthMode;
    state = state.copyWith(
      modelId: newValue,
      name:
          model?.name ??
          (isOpenAICodexProvider(newValue) ? openAICodexDisplayName : null),
      authMode: nextAuthMode,
      key: authModeChanged ? null : state.key,
    );
  }

  void setUrl(String? newUrl) {
    state = state.copyWith(
      url: newUrl,
    );
  }

  Future<ModelConnectionEntity?> addModelProvider({
    CodexOAuthMethod? codexOAuthMethod,
    void Function(CodexDeviceCode deviceCode)? onCodexDeviceCode,
    bool Function()? isCodexDeviceCodeCancelled,
  }) async {
    if (!state.isValid()) {
      return null;
    }

    final name = state.name;
    final key = state.key;
    final modelId = state.modelId;
    if (name == null || modelId == null) {
      return null;
    }

    try {
      final repo = ref.read(modelConnectionRepositoryProvider);
      final authMode = state.authMode;
      if (authMode == ModelProviderAuthMode.oauth2) {
        if (!isOpenAICodexProvider(modelId)) {
          throw ModelConnectionException('OAuth profile not found: $modelId');
        }
        if (openAICodexClientId.isEmpty) {
          throw const ModelConnectionException(
            'OAuth client ID is not configured for $openAICodexDisplayName',
          );
        }
        final openAIModels = await ref
            .read(apiModelRepositoryProvider)
            .getModelsByProvider('openai');
        final modelIds = openAIModels
            .where((model) => model.isCodexRuntimeModel)
            .map((model) => model.id)
            .toList();
        if (modelIds.isEmpty) {
          throw const ModelConnectionException(
            'OpenAI model catalog is unavailable. Retry after model sync.',
          );
        }
        final token = switch (codexOAuthMethod) {
          CodexOAuthMethod.deviceCode =>
            await CodexOAuthService().authenticateWithDeviceCode(
              onDeviceCode: onCodexDeviceCode,
              isCancelled: isCodexDeviceCodeCancelled,
            ),
          _ => await CodexOAuthService().authenticateWithBrowser(),
        };

        return await repo.createModelConnection(
          ModelConnectionToCreate(
            name: name,
            workspaceId: _workspaceId,
            modelId: modelId,
            authMode: authMode,
            url: state.url,
            oauthToken: token,
            oauthMetadata: ServiceConnectionMetadata(
              clientId: openAICodexClientId,
              issuer: openAICodexIssuer,
              authorizationEndpoint: openAICodexAuthorizationEndpoint,
              tokenEndpoint: openAICodexTokenEndpoint,
              scopes: openAICodexScopes,
              accountId: CodexOAuthService.accountIdFromToken(token),
              provider: openAICodexProviderId,
            ),
            modelIds: modelIds,
          ),
        );
      }

      if (key == null || key.trim().isEmpty) return null;

      return await repo.createModelConnection(
        ModelConnectionToCreate(
          name: name,
          workspaceId: _workspaceId,
          modelId: modelId,
          key: key,
          url: state.url,
        ),
      );
    } on CodexOAuthCanceledException {
      return null;
    } on Exception catch (e, s) {
      _log.severe('addModelProvider error', e, s);
      rethrow;
    }
  }
}

final addCredentialsModelMutationProvider = Mutation<void>();
