// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_model_selection_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceModelSelectionById)
final workspaceModelSelectionByIdProvider =
    WorkspaceModelSelectionByIdFamily._();

final class WorkspaceModelSelectionByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceModelSelectionWithConnectionEntity?>,
          WorkspaceModelSelectionWithConnectionEntity?,
          FutureOr<WorkspaceModelSelectionWithConnectionEntity?>
        >
    with
        $FutureModifier<WorkspaceModelSelectionWithConnectionEntity?>,
        $FutureProvider<WorkspaceModelSelectionWithConnectionEntity?> {
  WorkspaceModelSelectionByIdProvider._({
    required WorkspaceModelSelectionByIdFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'workspaceModelSelectionByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceModelSelectionByIdHash();

  @override
  String toString() {
    return r'workspaceModelSelectionByIdProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceModelSelectionWithConnectionEntity?>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceModelSelectionWithConnectionEntity?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return workspaceModelSelectionById(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceModelSelectionByIdProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceModelSelectionByIdHash() =>
    r'20f9d4c49e77e6817adbc5a3ca9c07979d82886f';

final class WorkspaceModelSelectionByIdFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WorkspaceModelSelectionWithConnectionEntity?>,
          (String, String)
        > {
  WorkspaceModelSelectionByIdFamily._()
    : super(
        retry: null,
        name: r'workspaceModelSelectionByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceModelSelectionByIdProvider call(
    String workspaceId,
    String workspaceModelSelectionId,
  ) => WorkspaceModelSelectionByIdProvider._(
    argument: (workspaceId, workspaceModelSelectionId),
    from: this,
  );

  @override
  String toString() => r'workspaceModelSelectionByIdProvider';
}

@ProviderFor(modelContextLimit)
final modelContextLimitProvider = ModelContextLimitFamily._();

final class ModelContextLimitProvider
    extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
  ModelContextLimitProvider._({
    required ModelContextLimitFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'modelContextLimitProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$modelContextLimitHash();

  @override
  String toString() {
    return r'modelContextLimitProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return modelContextLimit(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ModelContextLimitProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$modelContextLimitHash() => r'da03227f2043dd827030c2c3e829b9a1af4bbd62';

final class ModelContextLimitFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int?>, (String, String)> {
  ModelContextLimitFamily._()
    : super(
        retry: null,
        name: r'modelContextLimitProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ModelContextLimitProvider call(
    String workspaceId,
    String workspaceModelSelectionId,
  ) => ModelContextLimitProvider._(
    argument: (workspaceId, workspaceModelSelectionId),
    from: this,
  );

  @override
  String toString() => r'modelContextLimitProvider';
}
