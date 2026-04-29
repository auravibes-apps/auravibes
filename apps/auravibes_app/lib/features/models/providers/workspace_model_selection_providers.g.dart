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
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceModelSelectionByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 =
      workspaceModelSelectionRepositoryProvider;

  @override
  String debugGetCreateSourceHash() => _$workspaceModelSelectionByIdHash();

  @override
  String toString() {
    return r'workspaceModelSelectionByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceModelSelectionWithConnectionEntity?>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceModelSelectionWithConnectionEntity?> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceModelSelectionById(ref, argument);
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
    r'9725387f6a39a753e5d0846aba87942300570dca';

final class WorkspaceModelSelectionByIdFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WorkspaceModelSelectionWithConnectionEntity?>,
          String
        > {
  WorkspaceModelSelectionByIdFamily._()
    : super(
        retry: null,
        name: r'workspaceModelSelectionByIdProvider',
        dependencies: <ProviderOrFamily>[
          workspaceModelSelectionRepositoryProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          WorkspaceModelSelectionByIdProvider.$allTransitiveDependencies0,
        ],
        isAutoDispose: true,
      );

  WorkspaceModelSelectionByIdProvider call(String workspaceModelSelectionId) =>
      WorkspaceModelSelectionByIdProvider._(
        argument: workspaceModelSelectionId,
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
    required String super.argument,
  }) : super(
         retry: null,
         name: r'modelContextLimitProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 =
      workspaceModelSelectionByIdProvider;
  static final $allTransitiveDependencies1 =
      WorkspaceModelSelectionByIdProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      getModelByProviderAndModelIdProvider;

  @override
  String debugGetCreateSourceHash() => _$modelContextLimitHash();

  @override
  String toString() {
    return r'modelContextLimitProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int?> create(Ref ref) {
    final argument = this.argument as String;
    return modelContextLimit(ref, argument);
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

String _$modelContextLimitHash() => r'638a326785cec00196dffb5af182a3b035c5c460';

final class ModelContextLimitFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int?>, String> {
  ModelContextLimitFamily._()
    : super(
        retry: null,
        name: r'modelContextLimitProvider',
        dependencies: <ProviderOrFamily>[
          workspaceModelSelectionByIdProvider,
          getModelByProviderAndModelIdProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ModelContextLimitProvider.$allTransitiveDependencies0,
          ModelContextLimitProvider.$allTransitiveDependencies1,
          ModelContextLimitProvider.$allTransitiveDependencies2,
        ],
        isAutoDispose: true,
      );

  ModelContextLimitProvider call(String workspaceModelSelectionId) =>
      ModelContextLimitProvider._(
        argument: workspaceModelSelectionId,
        from: this,
      );

  @override
  String toString() => r'modelContextLimitProvider';
}
