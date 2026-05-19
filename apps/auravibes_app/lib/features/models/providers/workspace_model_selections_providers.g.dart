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
    r'740a84131efe0dc2bdac9b61bb74cfb93138b680';

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

/// Groups models by provider name for two-step model selection.
/// Returns a map where keys are provider names and values are lists of models.

@ProviderFor(listModelsGroupedByProvider)
final listModelsGroupedByProviderProvider =
    ListModelsGroupedByProviderFamily._();

/// Groups models by provider name for two-step model selection.
/// Returns a map where keys are provider names and values are lists of models.

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
  /// Groups models by provider name for two-step model selection.
  /// Returns a map where keys are provider names and values are lists of models.
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
    r'da344a279e1c6d9116b82f612fa60bcc6cdb2a0d';

/// Groups models by provider name for two-step model selection.
/// Returns a map where keys are provider names and values are lists of models.

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

  /// Groups models by provider name for two-step model selection.
  /// Returns a map where keys are provider names and values are lists of models.

  ListModelsGroupedByProviderProvider call({required String workspaceId}) =>
      ListModelsGroupedByProviderProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'listModelsGroupedByProviderProvider';
}
