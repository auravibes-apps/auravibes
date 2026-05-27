// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
import 'dart:async';

import 'package:auravibes_app/data/repositories/api_model_repository_impl.dart';
import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/repositories/api_model_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/model_api_service.dart';
import 'package:auravibes_app/services/model_sync_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_model_repository_providers.g.dart';

/// Provider for the API model repository
@Riverpod(keepAlive: true)
ApiModelRepository apiModelRepository(Ref ref) {
  final appDatabase = ref.watch(appDatabaseProvider);
  return ApiModelRepositoryImpl(appDatabase);
}

/// Provider for the model API service
@riverpod
ModelApiService modelApiService(Ref _) {
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
    (_) {
      final _ = service.performFullSync();
    },
  );

  final _ = ref.onDispose(timer.cancel);
  return service;
}

@riverpod
Future<List<ApiModelProviderEntity>> apiModelProviders(Ref ref) {
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
