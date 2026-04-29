// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_connection_repositories_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(modelConnectionRepository)
final modelConnectionRepositoryProvider = ModelConnectionRepositoryProvider._();

final class ModelConnectionRepositoryProvider
    extends
        $FunctionalProvider<
          ModelConnectionRepository,
          ModelConnectionRepository,
          ModelConnectionRepository
        >
    with $Provider<ModelConnectionRepository> {
  ModelConnectionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelConnectionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelConnectionRepositoryHash();

  @$internal
  @override
  $ProviderElement<ModelConnectionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ModelConnectionRepository create(Ref ref) {
    return modelConnectionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModelConnectionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModelConnectionRepository>(value),
    );
  }
}

String _$modelConnectionRepositoryHash() =>
    r'9e0622cccf9d569f65eb69c5330548e208218d5a';

@ProviderFor(workspaceModelSelectionRepository)
final workspaceModelSelectionRepositoryProvider =
    WorkspaceModelSelectionRepositoryProvider._();

final class WorkspaceModelSelectionRepositoryProvider
    extends
        $FunctionalProvider<
          WorkspaceModelSelectionRepository,
          WorkspaceModelSelectionRepository,
          WorkspaceModelSelectionRepository
        >
    with $Provider<WorkspaceModelSelectionRepository> {
  WorkspaceModelSelectionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceModelSelectionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$workspaceModelSelectionRepositoryHash();

  @$internal
  @override
  $ProviderElement<WorkspaceModelSelectionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceModelSelectionRepository create(Ref ref) {
    return workspaceModelSelectionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceModelSelectionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceModelSelectionRepository>(
        value,
      ),
    );
  }
}

String _$workspaceModelSelectionRepositoryHash() =>
    r'5274806b03671cc09e859a635dc8a4c1d9166bd8';
