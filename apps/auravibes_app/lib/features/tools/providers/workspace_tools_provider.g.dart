// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_tools_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceToolsRepository)
final workspaceToolsRepositoryProvider = WorkspaceToolsRepositoryProvider._();

final class WorkspaceToolsRepositoryProvider
    extends
        $FunctionalProvider<
          WorkspaceToolsRepository,
          WorkspaceToolsRepository,
          WorkspaceToolsRepository
        >
    with $Provider<WorkspaceToolsRepository> {
  WorkspaceToolsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceToolsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceToolsRepositoryHash();

  @$internal
  @override
  $ProviderElement<WorkspaceToolsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceToolsRepository create(Ref ref) {
    return workspaceToolsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceToolsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceToolsRepository>(value),
    );
  }
}

String _$workspaceToolsRepositoryHash() =>
    r'8408a4229d3f4d6624c8b4a6521ea2b7f76b7889';

@ProviderFor(workspaceToolIndexNotifier)
final workspaceToolIndexProvider = WorkspaceToolIndexNotifierProvider._();

final class WorkspaceToolIndexNotifierProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  WorkspaceToolIndexNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceToolIndexProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceToolIndexNotifierHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return workspaceToolIndexNotifier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$workspaceToolIndexNotifierHash() =>
    r'd73774534b1ad72a1f843ffde7301d9a87ae9b97';

@ProviderFor(WorkspaceToolsNotifier)
final workspaceToolsProvider = WorkspaceToolsNotifierProvider._();

final class WorkspaceToolsNotifierProvider
    extends
        $AsyncNotifierProvider<
          WorkspaceToolsNotifier,
          List<WorkspaceToolEntity>
        > {
  WorkspaceToolsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceToolsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceToolsNotifierHash();

  @$internal
  @override
  WorkspaceToolsNotifier create() => WorkspaceToolsNotifier();
}

String _$workspaceToolsNotifierHash() =>
    r'f539015ef35618899c3dee8045ee335a6c6ae0bb';

abstract class _$WorkspaceToolsNotifier
    extends $AsyncNotifier<List<WorkspaceToolEntity>> {
  FutureOr<List<WorkspaceToolEntity>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<WorkspaceToolEntity>>,
              List<WorkspaceToolEntity>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<WorkspaceToolEntity>>,
                List<WorkspaceToolEntity>
              >,
              AsyncValue<List<WorkspaceToolEntity>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider that returns the list of available built-in tools
/// that can be added to the workspace

@ProviderFor(availableToolsToAdd)
final availableToolsToAddProvider = AvailableToolsToAddProvider._();

/// Provider that returns the list of available built-in tools
/// that can be added to the workspace

final class AvailableToolsToAddProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserToolType>>,
          List<UserToolType>,
          FutureOr<List<UserToolType>>
        >
    with
        $FutureModifier<List<UserToolType>>,
        $FutureProvider<List<UserToolType>> {
  /// Provider that returns the list of available built-in tools
  /// that can be added to the workspace
  AvailableToolsToAddProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableToolsToAddProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableToolsToAddHash();

  @$internal
  @override
  $FutureProviderElement<List<UserToolType>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserToolType>> create(Ref ref) {
    return availableToolsToAdd(ref);
  }
}

String _$availableToolsToAddHash() =>
    r'c11342fe74c0606bb77f2b4941351c12cf81babf';

@ProviderFor(workspaceToolRow)
final workspaceToolRowProvider = WorkspaceToolRowProvider._();

final class WorkspaceToolRowProvider
    extends
        $FunctionalProvider<
          WorkspaceToolEntity?,
          WorkspaceToolEntity?,
          WorkspaceToolEntity?
        >
    with $Provider<WorkspaceToolEntity?> {
  WorkspaceToolRowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceToolRowProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[workspaceToolIndexProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          WorkspaceToolRowProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = workspaceToolIndexProvider;

  @override
  String debugGetCreateSourceHash() => _$workspaceToolRowHash();

  @$internal
  @override
  $ProviderElement<WorkspaceToolEntity?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceToolEntity? create(Ref ref) {
    return workspaceToolRow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceToolEntity? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceToolEntity?>(value),
    );
  }
}

String _$workspaceToolRowHash() => r'02af8404a679663c25fa95b15607cfb78f1b8d40';
