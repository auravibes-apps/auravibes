// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_model_repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the API model repository.

@ProviderFor(apiModelRepository)
final apiModelRepositoryProvider = ApiModelRepositoryProvider._();

/// Provider for the API model repository.

final class ApiModelRepositoryProvider
    extends
        $FunctionalProvider<
          ApiModelRepository,
          ApiModelRepository,
          ApiModelRepository
        >
    with $Provider<ApiModelRepository> {
  /// Provider for the API model repository.
  ApiModelRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiModelRepositoryProvider',
        isAutoDispose: false,
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
    r'ce28c9a1ada0e032e779e224d152730e2fb9ad85';

/// Provider for the model API service.

@ProviderFor(modelApiService)
final modelApiServiceProvider = ModelApiServiceProvider._();

/// Provider for the model API service.

final class ModelApiServiceProvider
    extends
        $FunctionalProvider<ModelApiService, ModelApiService, ModelApiService>
    with $Provider<ModelApiService> {
  /// Provider for the model API service.
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

String _$modelApiServiceHash() => r'a248c4da513fe5e9d8379a5c922027e51f194b38';

/// Provider for the model sync service.

@ProviderFor(modelSyncService)
final modelSyncServiceProvider = ModelSyncServiceProvider._();

/// Provider for the model sync service.

final class ModelSyncServiceProvider
    extends
        $FunctionalProvider<
          ModelSyncService,
          ModelSyncService,
          ModelSyncService
        >
    with $Provider<ModelSyncService> {
  /// Provider for the model sync service.
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

String _$modelSyncServiceHash() => r'9dca60fd70a80ac02195ba080a65f5f2eedc3a02';

@ProviderFor(apiModelProviders)
final apiModelProvidersProvider = ApiModelProvidersProvider._();

final class ApiModelProvidersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ApiModelProviderEntity>>,
          List<ApiModelProviderEntity>,
          FutureOr<List<ApiModelProviderEntity>>
        >
    with
        $FutureModifier<List<ApiModelProviderEntity>>,
        $FutureProvider<List<ApiModelProviderEntity>> {
  ApiModelProvidersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiModelProvidersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiModelProvidersHash();

  @$internal
  @override
  $FutureProviderElement<List<ApiModelProviderEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ApiModelProviderEntity>> create(Ref ref) {
    return apiModelProviders(ref);
  }
}

String _$apiModelProvidersHash() => r'23a8b4262aed02572dd3bfd82ee0e1126265e1e4';

@ProviderFor(getAllModels)
final getAllModelsProvider = GetAllModelsProvider._();

final class GetAllModelsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ApiModelEntity>>,
          List<ApiModelEntity>,
          FutureOr<List<ApiModelEntity>>
        >
    with
        $FutureModifier<List<ApiModelEntity>>,
        $FutureProvider<List<ApiModelEntity>> {
  GetAllModelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getAllModelsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getAllModelsHash();

  @$internal
  @override
  $FutureProviderElement<List<ApiModelEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ApiModelEntity>> create(Ref ref) {
    return getAllModels(ref);
  }
}

String _$getAllModelsHash() => r'667a38ad9fcffdb4b9eb86395910a77c92be00f1';

@ProviderFor(getModelByProviderAndModelId)
final getModelByProviderAndModelIdProvider =
    GetModelByProviderAndModelIdFamily._();

final class GetModelByProviderAndModelIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<ApiModelEntity?>,
          ApiModelEntity?,
          FutureOr<ApiModelEntity?>
        >
    with $FutureModifier<ApiModelEntity?>, $FutureProvider<ApiModelEntity?> {
  GetModelByProviderAndModelIdProvider._({
    required GetModelByProviderAndModelIdFamily super.from,
    required ({String providerId, String modelId}) super.argument,
  }) : super(
         retry: null,
         name: r'getModelByProviderAndModelIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getModelByProviderAndModelIdHash();

  @override
  String toString() {
    return r'getModelByProviderAndModelIdProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ApiModelEntity?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ApiModelEntity?> create(Ref ref) {
    final argument = this.argument as ({String providerId, String modelId});
    return getModelByProviderAndModelId(
      ref,
      providerId: argument.providerId,
      modelId: argument.modelId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GetModelByProviderAndModelIdProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getModelByProviderAndModelIdHash() =>
    r'12dbcbfd0ed09838b2f1fb2b8e5dd19234509a3e';

final class GetModelByProviderAndModelIdFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ApiModelEntity?>,
          ({String providerId, String modelId})
        > {
  GetModelByProviderAndModelIdFamily._()
    : super(
        retry: null,
        name: r'getModelByProviderAndModelIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetModelByProviderAndModelIdProvider call({
    required String providerId,
    required String modelId,
  }) => GetModelByProviderAndModelIdProvider._(
    argument: (providerId: providerId, modelId: modelId),
    from: this,
  );

  @override
  String toString() => r'getModelByProviderAndModelIdProvider';
}

@ProviderFor(getModelsByProvider)
final getModelsByProviderProvider = GetModelsByProviderFamily._();

final class GetModelsByProviderProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ApiModelEntity>>,
          List<ApiModelEntity>,
          FutureOr<List<ApiModelEntity>>
        >
    with
        $FutureModifier<List<ApiModelEntity>>,
        $FutureProvider<List<ApiModelEntity>> {
  GetModelsByProviderProvider._({
    required GetModelsByProviderFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'getModelsByProviderProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getModelsByProviderHash();

  @override
  String toString() {
    return r'getModelsByProviderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ApiModelEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ApiModelEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return getModelsByProvider(ref, providerId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetModelsByProviderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getModelsByProviderHash() =>
    r'a3461761af99e4001476851db2bdb908e18073e2';

final class GetModelsByProviderFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ApiModelEntity>>, String> {
  GetModelsByProviderFamily._()
    : super(
        retry: null,
        name: r'getModelsByProviderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  GetModelsByProviderProvider call({required String providerId}) =>
      GetModelsByProviderProvider._(argument: providerId, from: this);

  @override
  String toString() => r'getModelsByProviderProvider';
}
