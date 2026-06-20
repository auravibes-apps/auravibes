// Required: Existing test and UI helpers keep compact return flow.
// Required: Existing helpers remain top-level for local feature use.
import 'dart:async';

import 'package:auravibes_app/data/repositories/api_model_repository_impl.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/repositories/api_model_repository.dart';
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

  return ApiModelRepositoryImpl(appDatabase);
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

  final service = ModelSyncService(
    syncApiModelsUseCase: syncApiModelsUseCase,
  )..performFullSync();

  final timer = Timer.periodic(
    const Duration(hours: 5),
    (_) {
      service.performFullSync();
    },
  );

  final _ = ref.onDispose(timer.cancel);

  return service;
}

@riverpod
Future<List<ApiModelProviderEntity>> apiModelProviders(Ref ref) async {
  final providers = await ref
      .watch(apiModelRepositoryProvider)
      .getAllProviders();
  final realProviders = providers
      .where((p) => !isOpenAICodexProvider(p.id) && p.type != null)
      .toList();
  final openAIProvider = realProviders.firstWhereOrNull(
    (provider) => provider.id == 'openai',
  );
  if (openAIProvider == null || openAICodexClientId.isEmpty) {
    return realProviders;
  }

  return [
    ApiModelProviderEntity(
      id: openAICodexProviderId,
      name: openAICodexDisplayName,
      type: .openai,
      url: openAIProvider.url,
      doc: openAIProvider.doc,
    ),
    ...realProviders,
  ];
}

@Riverpod(keepAlive: true)
Future<List<ApiModelEntity>> getAllModels(Ref ref) {
  return ref.watch(apiModelRepositoryProvider).getAllModels();
}

@riverpod
Future<ApiModelEntity?> getModelByProviderAndModelId(
  Ref ref, {
  required String providerId,
  required String modelId,
}) {
  return ref
      .watch(apiModelRepositoryProvider)
      .getModelByProviderAndModelId(providerId, modelId);
}

@Riverpod(keepAlive: true)
Future<List<ApiModelEntity>> getModelsByProvider(
  Ref ref, {
  required String providerId,
}) {
  return ref.watch(apiModelRepositoryProvider).getModelsByProvider(providerId);
}
