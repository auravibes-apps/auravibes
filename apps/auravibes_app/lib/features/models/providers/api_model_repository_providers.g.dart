// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_model_repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the API model repository

@ProviderFor(apiModelRepository)
final apiModelRepositoryProvider = ApiModelRepositoryProvider._();

/// Provider for the API model repository

final class ApiModelRepositoryProvider
    extends
        $FunctionalProvider<
          ApiModelRepository,
          ApiModelRepository,
          ApiModelRepository
        >
    with $Provider<ApiModelRepository> {
  /// Provider for the API model repository
  ApiModelRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiModelRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiModelRepositoryHash();

  @$internal
  @override
  $ProviderElement<ApiModelRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ApiModelRepository create(Ref ref) {
    return apiModelRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiModelRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiModelRepository>(value),
    );
  }
}

String _$apiModelRepositoryHash() =>
    r'9f10065210102105fdbff3757c08f5b3708f97dc';

/// Provider for the model API service

@ProviderFor(modelApiService)
final modelApiServiceProvider = ModelApiServiceProvider._();

/// Provider for the model API service

final class ModelApiServiceProvider
    extends
        $FunctionalProvider<ModelApiService, ModelApiService, ModelApiService>
    with $Provider<ModelApiService> {
  /// Provider for the model API service
  ModelApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelApiServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelApiServiceHash();

  @$internal
  @override
  $ProviderElement<ModelApiService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ModelApiService create(Ref ref) {
    return modelApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModelApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModelApiService>(value),
    );
  }
}

String _$modelApiServiceHash() => r'70c8085560c48e76c15e205f4614b8c731ed1099';

/// Provider for the model sync service

@ProviderFor(modelSyncService)
final modelSyncServiceProvider = ModelSyncServiceProvider._();

/// Provider for the model sync service

final class ModelSyncServiceProvider
    extends
        $FunctionalProvider<
          ModelSyncService,
          ModelSyncService,
          ModelSyncService
        >
    with $Provider<ModelSyncService> {
  /// Provider for the model sync service
  ModelSyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelSyncServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelSyncServiceHash();

  @$internal
  @override
  $ProviderElement<ModelSyncService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ModelSyncService create(Ref ref) {
    return modelSyncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModelSyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModelSyncService>(value),
    );
  }
}

String _$modelSyncServiceHash() => r'858309c7530c0e52cb6fc7aecc5099033ac8a34b';

@ProviderFor(modelProvidersNotifier)
final modelProvidersProvider = ModelProvidersNotifierProvider._();

final class ModelProvidersNotifierProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ApiModelProviderEntity>>,
          List<ApiModelProviderEntity>,
          FutureOr<List<ApiModelProviderEntity>>
        >
    with
        $FutureModifier<List<ApiModelProviderEntity>>,
        $FutureProvider<List<ApiModelProviderEntity>> {
  ModelProvidersNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelProvidersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelProvidersNotifierHash();

  @$internal
  @override
  $FutureProviderElement<List<ApiModelProviderEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ApiModelProviderEntity>> create(Ref ref) {
    return modelProvidersNotifier(ref);
  }
}

String _$modelProvidersNotifierHash() =>
    r'5d05741a4b0a934221b3cae01dbbde5e6b46dc79';
