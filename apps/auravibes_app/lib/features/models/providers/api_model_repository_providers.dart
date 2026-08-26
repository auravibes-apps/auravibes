// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:auravibes_app/data/repositories/api_model_repository.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/models/usecases/sync_api_models_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/model_api_service.dart';
import 'package:auravibes_app/services/model_provider_oauth_profiles.dart';
import 'package:auravibes_app/services/model_sync_service.dart';
import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_model_repository_providers.g.dart';

/// Provider for the API model repository.
@Riverpod(keepAlive: true)
ApiModelRepository apiModelRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);

  return ApiModelRepository(appDatabase);
}

/// Provider for the model API service.
@Riverpod(keepAlive: true)
ModelApiService modelApiService(Ref _) {
  return ModelApiService();
}

/// Provider for the model sync service.
@Riverpod(keepAlive: true)
ModelSyncService modelSyncService(Ref ref) {
  final repository = ref.watch(apiModelRepositoryProvider);
  final apiService = ref.watch(modelApiServiceProvider);
  final syncApiModelsUseCase = SyncApiModelsUseCase(
    repository: repository,
    apiService: apiService,
  );

  final service = ModelSyncService(syncApiModelsUseCase: syncApiModelsUseCase);

  final timer = Timer.periodic(const Duration(hours: 5), (_) {
    service.performFullSync();
  });

  final _ = ref.onDispose(timer.cancel);

  return service;
}

@riverpod
Future<List<ApiModelProviderEntity>> apiModelProviders(
  Ref ref, {
  required String workspaceId,
}) async {
  final catalog = await ref.watch(
    modelCatalogStoreProvider(workspaceId).future,
  );
  final providers = await catalog.getAllProviders();
  final realProviders = providers
      .where(
        (p) =>
            !ModelProviderOAuthProfiles.isCodexProvider(p.id) && p.type != null,
      )
      .toList();
  final openAIProvider = realProviders.firstWhereOrNull(
    (provider) => provider.id == 'openai',
  );
  if (openAIProvider == null || ModelProviderOAuthProfiles.clientId.isEmpty) {
    return realProviders;
  }

  return [
    ApiModelProviderEntity(
      id: ModelProviderOAuthProfiles.providerId,
      name: ModelProviderOAuthProfiles.displayName,
      type: .openai,
      url: openAIProvider.url,
      doc: openAIProvider.doc,
    ),
    ...realProviders,
  ];
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<List<ApiModelEntity>> getAllModels(
  Ref ref, {
  required String workspaceId,
}) async {
  final catalog = await ref.watch(
    modelCatalogStoreProvider(workspaceId).future,
  );

  return await catalog.getAllModels();
}

@riverpod
// ignore: prefer-static-class (required framework top-level declaration)
Future<ApiModelEntity?> getModelByProviderAndModelId(
  Ref ref, {
  required String workspaceId,
  required String providerId,
  required String modelId,
}) async {
  final catalog = await ref.watch(
    modelCatalogStoreProvider(workspaceId).future,
  );

  return await catalog.getModelByProviderAndModelId(providerId, modelId);
}

@riverpod
Future<List<ApiModelEntity>> getModelsByProvider(
  Ref ref, {
  required String workspaceId,
  required String providerId,
}) async {
  final catalog = await ref.watch(
    modelCatalogStoreProvider(workspaceId).future,
  );

  return await catalog.getModelsByProvider(providerId);
}
// Top-level API/provider declarations are required by their consumers.
