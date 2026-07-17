// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_store_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(modelConnectionStore)
final modelConnectionStoreProvider = ModelConnectionStoreFamily._();

final class ModelConnectionStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<ModelConnectionStore>,
          ModelConnectionStore,
          FutureOr<ModelConnectionStore>
        >
    with
        $FutureModifier<ModelConnectionStore>,
        $FutureProvider<ModelConnectionStore> {
  ModelConnectionStoreProvider._({
    required ModelConnectionStoreFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'modelConnectionStoreProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$modelConnectionStoreHash();

  @override
  String toString() {
    return r'modelConnectionStoreProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ModelConnectionStore> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ModelConnectionStore> create(Ref ref) {
    final argument = this.argument as String;
    return modelConnectionStore(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ModelConnectionStoreProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$modelConnectionStoreHash() =>
    r'64d2c67b702c8899317713673cfe7f706a5765c6';

final class ModelConnectionStoreFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ModelConnectionStore>, String> {
  ModelConnectionStoreFamily._()
    : super(
        retry: null,
        name: r'modelConnectionStoreProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ModelConnectionStoreProvider call(String workspaceId) =>
      ModelConnectionStoreProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'modelConnectionStoreProvider';
}

@ProviderFor(modelSelectionStore)
final modelSelectionStoreProvider = ModelSelectionStoreFamily._();

final class ModelSelectionStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<ModelSelectionStore>,
          ModelSelectionStore,
          FutureOr<ModelSelectionStore>
        >
    with
        $FutureModifier<ModelSelectionStore>,
        $FutureProvider<ModelSelectionStore> {
  ModelSelectionStoreProvider._({
    required ModelSelectionStoreFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'modelSelectionStoreProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$modelSelectionStoreHash();

  @override
  String toString() {
    return r'modelSelectionStoreProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ModelSelectionStore> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ModelSelectionStore> create(Ref ref) {
    final argument = this.argument as String;
    return modelSelectionStore(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ModelSelectionStoreProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$modelSelectionStoreHash() =>
    r'fcb229459f50e80b5692efd6faf40b880e3fed75';

final class ModelSelectionStoreFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ModelSelectionStore>, String> {
  ModelSelectionStoreFamily._()
    : super(
        retry: null,
        name: r'modelSelectionStoreProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ModelSelectionStoreProvider call(String workspaceId) =>
      ModelSelectionStoreProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'modelSelectionStoreProvider';
}

@ProviderFor(modelCatalogStore)
final modelCatalogStoreProvider = ModelCatalogStoreFamily._();

final class ModelCatalogStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<ModelCatalogStore>,
          ModelCatalogStore,
          FutureOr<ModelCatalogStore>
        >
    with
        $FutureModifier<ModelCatalogStore>,
        $FutureProvider<ModelCatalogStore> {
  ModelCatalogStoreProvider._({
    required ModelCatalogStoreFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'modelCatalogStoreProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$modelCatalogStoreHash();

  @override
  String toString() {
    return r'modelCatalogStoreProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ModelCatalogStore> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ModelCatalogStore> create(Ref ref) {
    final argument = this.argument as String;
    return modelCatalogStore(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ModelCatalogStoreProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$modelCatalogStoreHash() => r'be58382c8e3106dd1e782ec36238a7d585822214';

final class ModelCatalogStoreFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ModelCatalogStore>, String> {
  ModelCatalogStoreFamily._()
    : super(
        retry: null,
        name: r'modelCatalogStoreProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ModelCatalogStoreProvider call(String workspaceId) =>
      ModelCatalogStoreProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'modelCatalogStoreProvider';
}
