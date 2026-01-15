// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_providers_repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(modelProvidersRepository)
final modelProvidersRepositoryProvider = ModelProvidersRepositoryProvider._();

final class ModelProvidersRepositoryProvider
    extends
        $FunctionalProvider<
          CredentialsRepository,
          CredentialsRepository,
          CredentialsRepository
        >
    with $Provider<CredentialsRepository> {
  ModelProvidersRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelProvidersRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelProvidersRepositoryHash();

  @$internal
  @override
  $ProviderElement<CredentialsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CredentialsRepository create(Ref ref) {
    return modelProvidersRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CredentialsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CredentialsRepository>(value),
    );
  }
}

String _$modelProvidersRepositoryHash() =>
    r'e24c0d43d62bdfc68db800de929581d68c73ecf7';

@ProviderFor(credentialsModelsRepository)
final credentialsModelsRepositoryProvider =
    CredentialsModelsRepositoryProvider._();

final class CredentialsModelsRepositoryProvider
    extends
        $FunctionalProvider<
          CredentialsModelsRepository,
          CredentialsModelsRepository,
          CredentialsModelsRepository
        >
    with $Provider<CredentialsModelsRepository> {
  CredentialsModelsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'credentialsModelsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$credentialsModelsRepositoryHash();

  @$internal
  @override
  $ProviderElement<CredentialsModelsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CredentialsModelsRepository create(Ref ref) {
    return credentialsModelsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CredentialsModelsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CredentialsModelsRepository>(value),
    );
  }
}

String _$credentialsModelsRepositoryHash() =>
    r'f0bd8801789cee3831fe7a8dbbe78310f3a314f3';
