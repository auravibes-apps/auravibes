import 'dart:async';

import 'package:auravibes_app/data/repositories/api_model_repository_impl.dart';
import 'package:auravibes_app/domain/entities/api_model.dart';
import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:auravibes_app/domain/repositories/api_model_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/model_api_service.dart';
import 'package:auravibes_app/services/model_sync_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_model_repository_providers.g.dart';

/// Provider for the API model repository
@riverpod
ApiModelRepository apiModelRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);
  return ApiModelRepositoryImpl(appDatabase);
}

/// Provider for the model API service
@riverpod
ModelApiService modelApiService(Ref ref) {
  return ModelApiService();
}

/// Provider for the model sync service
@riverpod
ModelSyncService modelSyncService(Ref ref) {
  final repository = ref.watch(apiModelRepositoryProvider);
  final apiService = ref.watch(modelApiServiceProvider);

  final service = ModelSyncService(
    repository: repository,
    apiService: apiService,
  )..performFullSync();

  final timer = Timer.periodic(
    const Duration(hours: 5),
    (timer) {
      service.performFullSync();
    },
  );

  ref.onDispose(timer.cancel);
  return service;
}

@riverpod
Future<List<ApiModelProviderEntity>> modelProvidersNotifier(Ref ref) {
  return ref.watch(apiModelRepositoryProvider).getAllProviders();
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
