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
    r'08031740aca25f06a00df299980b82575e12a0b7';

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
        isAutoDispose: false,
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

String _$modelApiServiceHash() => r'8152e674cf24bdc7b0dd3ee6901003c690bfc690';

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
        isAutoDispose: false,
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

String _$modelSyncServiceHash() => r'7e48545bede38cf94285e03aed7c08ae354d0db9';

@ProviderFor(apiModelProviders)
final apiModelProvidersProvider = ApiModelProvidersFamily._();

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
  ApiModelProvidersProvider._({
    required ApiModelProvidersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'apiModelProvidersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$apiModelProvidersHash();

  @override
  String toString() {
    return r'apiModelProvidersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ApiModelProviderEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ApiModelProviderEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return apiModelProviders(ref, workspaceId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ApiModelProvidersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$apiModelProvidersHash() => r'd1eb5e84882f2f383fff7dd2236cdbd822cd6d68';

final class ApiModelProvidersFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ApiModelProviderEntity>>,
          String
        > {
  ApiModelProvidersFamily._()
    : super(
        retry: null,
        name: r'apiModelProvidersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ApiModelProvidersProvider call({required String workspaceId}) =>
      ApiModelProvidersProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'apiModelProvidersProvider';
}

@ProviderFor(getAllModels)
final getAllModelsProvider = GetAllModelsFamily._();

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
  GetAllModelsProvider._({
    required GetAllModelsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'getAllModelsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getAllModelsHash();

  @override
  String toString() {
    return r'getAllModelsProvider'
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
    return getAllModels(ref, workspaceId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetAllModelsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getAllModelsHash() => r'fb25941bc09b2c6109ca21b036d63685d0292890';

final class GetAllModelsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ApiModelEntity>>, String> {
  GetAllModelsFamily._()
    : super(
        retry: null,
        name: r'getAllModelsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetAllModelsProvider call({required String workspaceId}) =>
      GetAllModelsProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'getAllModelsProvider';
}

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
    required ({String workspaceId, String providerId, String modelId})
    super.argument,
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
    final argument =
        this.argument
            as ({String workspaceId, String providerId, String modelId});
    return getModelByProviderAndModelId(
      ref,
      workspaceId: argument.workspaceId,
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
    r'cd6018853e1c7bc32fda71379bbdbe40ccfca3d8';

final class GetModelByProviderAndModelIdFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ApiModelEntity?>,
          ({String workspaceId, String providerId, String modelId})
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
    required String workspaceId,
    required String providerId,
    required String modelId,
  }) => GetModelByProviderAndModelIdProvider._(
    argument: (
      workspaceId: workspaceId,
      providerId: providerId,
      modelId: modelId,
    ),
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
    required ({String workspaceId, String providerId}) super.argument,
  }) : super(
         retry: null,
         name: r'getModelsByProviderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getModelsByProviderHash();

  @override
  String toString() {
    return r'getModelsByProviderProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<ApiModelEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ApiModelEntity>> create(Ref ref) {
    final argument = this.argument as ({String workspaceId, String providerId});
    return getModelsByProvider(
      ref,
      workspaceId: argument.workspaceId,
      providerId: argument.providerId,
    );
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
    r'256879560167fb04203af313a61dd30a91153dd2';

final class GetModelsByProviderFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ApiModelEntity>>,
          ({String workspaceId, String providerId})
        > {
  GetModelsByProviderFamily._()
    : super(
        retry: null,
        name: r'getModelsByProviderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetModelsByProviderProvider call({
    required String workspaceId,
    required String providerId,
  }) => GetModelsByProviderProvider._(
    argument: (workspaceId: workspaceId, providerId: providerId),
    from: this,
  );

  @override
  String toString() => r'getModelsByProviderProvider';
}
