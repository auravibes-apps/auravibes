// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_chat_models_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(listCredentialsCredentials)
final listCredentialsCredentialsProvider =
    ListCredentialsCredentialsProvider._();

final class ListCredentialsCredentialsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CredentialsModelWithProviderEntity>>,
          List<CredentialsModelWithProviderEntity>,
          FutureOr<List<CredentialsModelWithProviderEntity>>
        >
    with
        $FutureModifier<List<CredentialsModelWithProviderEntity>>,
        $FutureProvider<List<CredentialsModelWithProviderEntity>> {
  ListCredentialsCredentialsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listCredentialsCredentialsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listCredentialsCredentialsHash();

  @$internal
  @override
  $FutureProviderElement<List<CredentialsModelWithProviderEntity>>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CredentialsModelWithProviderEntity>> create(Ref ref) {
    return listCredentialsCredentials(ref);
  }
}

String _$listCredentialsCredentialsHash() =>
    r'225f85566f451f494f08d15035a6f70c2c445aa5';

/// Groups models by provider name for two-step model selection.
/// Returns a map where keys are provider names and values are lists of models.

@ProviderFor(listModelsGroupedByProvider)
final listModelsGroupedByProviderProvider =
    ListModelsGroupedByProviderProvider._();

/// Groups models by provider name for two-step model selection.
/// Returns a map where keys are provider names and values are lists of models.

final class ListModelsGroupedByProviderProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, List<CredentialsModelWithProviderEntity>>>,
          Map<String, List<CredentialsModelWithProviderEntity>>,
          FutureOr<Map<String, List<CredentialsModelWithProviderEntity>>>
        >
    with
        $FutureModifier<Map<String, List<CredentialsModelWithProviderEntity>>>,
        $FutureProvider<Map<String, List<CredentialsModelWithProviderEntity>>> {
  /// Groups models by provider name for two-step model selection.
  /// Returns a map where keys are provider names and values are lists of models.
  ListModelsGroupedByProviderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listModelsGroupedByProviderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listModelsGroupedByProviderHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, List<CredentialsModelWithProviderEntity>>>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, List<CredentialsModelWithProviderEntity>>> create(
    Ref ref,
  ) {
    return listModelsGroupedByProvider(ref);
  }
}

String _$listModelsGroupedByProviderHash() =>
    r'2d58f6882f3e5fa228643c76d0ccb9232b056851';
