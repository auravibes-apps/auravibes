// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_model_selections_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(listWorkspaceModelSelections)
final listWorkspaceModelSelectionsProvider =
    ListWorkspaceModelSelectionsFamily._();

final class ListWorkspaceModelSelectionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkspaceModelSelectionWithConnectionEntity>>,
          List<WorkspaceModelSelectionWithConnectionEntity>,
          Stream<List<WorkspaceModelSelectionWithConnectionEntity>>
        >
    with
        $FutureModifier<List<WorkspaceModelSelectionWithConnectionEntity>>,
        $StreamProvider<List<WorkspaceModelSelectionWithConnectionEntity>> {
  ListWorkspaceModelSelectionsProvider._({
    required ListWorkspaceModelSelectionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'listWorkspaceModelSelectionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$listWorkspaceModelSelectionsHash();

  @override
  String toString() {
    return r'listWorkspaceModelSelectionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<WorkspaceModelSelectionWithConnectionEntity>>
  $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<List<WorkspaceModelSelectionWithConnectionEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return listWorkspaceModelSelections(ref, workspaceId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ListWorkspaceModelSelectionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$listWorkspaceModelSelectionsHash() =>
    r'7bc70d9ecd55c4ee864ef0bbd625172720cb4359';

final class ListWorkspaceModelSelectionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<WorkspaceModelSelectionWithConnectionEntity>>,
          String
        > {
  ListWorkspaceModelSelectionsFamily._()
    : super(
        retry: null,
        name: r'listWorkspaceModelSelectionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ListWorkspaceModelSelectionsProvider call({required String workspaceId}) =>
      ListWorkspaceModelSelectionsProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'listWorkspaceModelSelectionsProvider';
}

/// Groups models by connection id for two-step model selection.
/// Returns a map where keys are credential-backed connection ids.

@ProviderFor(listModelsGroupedByProvider)
final listModelsGroupedByProviderProvider =
    ListModelsGroupedByProviderFamily._();

/// Groups models by connection id for two-step model selection.
/// Returns a map where keys are credential-backed connection ids.

final class ListModelsGroupedByProviderProvider
    extends
        $FunctionalProvider<
          AsyncValue<
            Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
          >,
          Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>,
          Stream<Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>>
        >
    with
        $FutureModifier<
          Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
        >,
        $StreamProvider<
          Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
        > {
  /// Groups models by connection id for two-step model selection.
  /// Returns a map where keys are credential-backed connection ids.
  ListModelsGroupedByProviderProvider._({
    required ListModelsGroupedByProviderFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'listModelsGroupedByProviderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$listModelsGroupedByProviderHash();

  @override
  String toString() {
    return r'listModelsGroupedByProviderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<
    Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
  >
  $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>> create(
    Ref ref,
  ) {
    final argument = this.argument as String;
    return listModelsGroupedByProvider(ref, workspaceId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ListModelsGroupedByProviderProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$listModelsGroupedByProviderHash() =>
    r'cb244814a31ca1aeb323f3f965073fb66447d0d0';

/// Groups models by connection id for two-step model selection.
/// Returns a map where keys are credential-backed connection ids.

final class ListModelsGroupedByProviderFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<
            Map<String, List<WorkspaceModelSelectionWithConnectionEntity>>
          >,
          String
        > {
  ListModelsGroupedByProviderFamily._()
    : super(
        retry: null,
        name: r'listModelsGroupedByProviderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Groups models by connection id for two-step model selection.
  /// Returns a map where keys are credential-backed connection ids.

  ListModelsGroupedByProviderProvider call({required String workspaceId}) =>
      ListModelsGroupedByProviderProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'listModelsGroupedByProviderProvider';
}
