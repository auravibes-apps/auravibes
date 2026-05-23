// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceRepository)
final workspaceRepositoryProvider = WorkspaceRepositoryProvider._();

final class WorkspaceRepositoryProvider
    extends
        $FunctionalProvider<
          WorkspaceRepository,
          WorkspaceRepository,
          WorkspaceRepository
        >
    with $Provider<WorkspaceRepository> {
  WorkspaceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceRepositoryHash();

  @$internal
  @override
  $ProviderElement<WorkspaceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceRepository create(Ref ref) {
    return workspaceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceRepository>(value),
    );
  }
}

String _$workspaceRepositoryHash() =>
    r'5a62259280096e729c8c14f246c4a0458a653971';

@ProviderFor(allWorkspaces)
final allWorkspacesProvider = AllWorkspacesProvider._();

final class AllWorkspacesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WorkspaceEntity>>,
          List<WorkspaceEntity>,
          Stream<List<WorkspaceEntity>>
        >
    with
        $FutureModifier<List<WorkspaceEntity>>,
        $StreamProvider<List<WorkspaceEntity>> {
  AllWorkspacesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allWorkspacesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allWorkspacesHash();

  @$internal
  @override
  $StreamProviderElement<List<WorkspaceEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WorkspaceEntity>> create(Ref ref) {
    return allWorkspaces(ref);
  }
}

String _$allWorkspacesHash() => r'0d342f5e8712cd6f795014602e6071f03bfce68f';
