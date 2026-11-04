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
    r'274fa87b9eed20cb0b07e0389b31faa8ab1c0daa';

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

@ProviderFor(workspaceById)
final workspaceByIdProvider = WorkspaceByIdFamily._();

final class WorkspaceByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceEntity?>,
          WorkspaceEntity?,
          FutureOr<WorkspaceEntity?>
        >
    with $FutureModifier<WorkspaceEntity?>, $FutureProvider<WorkspaceEntity?> {
  WorkspaceByIdProvider._({
    required WorkspaceByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceByIdHash();

  @override
  String toString() {
    return r'workspaceByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceEntity?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceEntity?> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceByIdHash() => r'afd26c92d0a3db31dfe5e6f9dbafadb92a1c26a4';

final class WorkspaceByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorkspaceEntity?>, String> {
  WorkspaceByIdFamily._()
    : super(
        retry: null,
        name: r'workspaceByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceByIdProvider call(String workspaceId) =>
      WorkspaceByIdProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceByIdProvider';
}
