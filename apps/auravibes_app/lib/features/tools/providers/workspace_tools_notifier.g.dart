// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_tools_notifier.dart';

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
          WorkspaceToolsRepositoryContract,
          WorkspaceToolsRepositoryContract,
          WorkspaceToolsRepositoryContract
        >
    with $Provider<WorkspaceToolsRepositoryContract> {
  WorkspaceToolsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceToolsRepositoryProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          workspaceSessionProvider,
          cloudWorkspaceStateGatewayProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          WorkspaceToolsRepositoryProvider.$allTransitiveDependencies0,
          WorkspaceToolsRepositoryProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = workspaceSessionProvider;
  static final $allTransitiveDependencies1 = cloudWorkspaceStateGatewayProvider;

  @override
  String debugGetCreateSourceHash() => _$workspaceToolsRepositoryHash();

  @$internal
  @override
  $ProviderElement<WorkspaceToolsRepositoryContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceToolsRepositoryContract create(Ref ref) {
    return workspaceToolsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceToolsRepositoryContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceToolsRepositoryContract>(
        value,
      ),
    );
  }
}

String _$workspaceToolsRepositoryHash() =>
    r'dbb34024bc95631647adfb57d1c39f30136fc022';

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
    r'3b576a17fc24c68fad98ebf210ecdc27c96598f9';

@ProviderFor(WorkspaceToolsNotifier)
final workspaceToolsProvider = WorkspaceToolsNotifierFamily._();

final class WorkspaceToolsNotifierProvider
    extends
        $AsyncNotifierProvider<
          WorkspaceToolsNotifier,
          List<WorkspaceToolEntity>
        > {
  WorkspaceToolsNotifierProvider._({
    required WorkspaceToolsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceToolsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = workspaceToolsRepositoryProvider;
  static final $allTransitiveDependencies1 =
      WorkspaceToolsRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      WorkspaceToolsRepositoryProvider.$allTransitiveDependencies1;

  @override
  String debugGetCreateSourceHash() => _$workspaceToolsNotifierHash();

  @override
  String toString() {
    return r'workspaceToolsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WorkspaceToolsNotifier create() => WorkspaceToolsNotifier();

  @override
  bool operator ==(Object other) {
    return other is WorkspaceToolsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceToolsNotifierHash() =>
    r'1e1823541d1af426935099f13816bcc7821b3dea';

final class WorkspaceToolsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          WorkspaceToolsNotifier,
          AsyncValue<List<WorkspaceToolEntity>>,
          List<WorkspaceToolEntity>,
          FutureOr<List<WorkspaceToolEntity>>,
          String
        > {
  WorkspaceToolsNotifierFamily._()
    : super(
        retry: null,
        name: r'workspaceToolsProvider',
        dependencies: <ProviderOrFamily>[workspaceToolsRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          WorkspaceToolsNotifierProvider.$allTransitiveDependencies0,
          WorkspaceToolsNotifierProvider.$allTransitiveDependencies1,
          WorkspaceToolsNotifierProvider.$allTransitiveDependencies2,
        ],
        isAutoDispose: true,
      );

  WorkspaceToolsNotifierProvider call(String workspaceId) =>
      WorkspaceToolsNotifierProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceToolsProvider';
}

abstract class _$WorkspaceToolsNotifier
    extends $AsyncNotifier<List<WorkspaceToolEntity>> {
  late final _$args = ref.$arg as String;
  String get workspaceId => _$args;

  FutureOr<List<WorkspaceToolEntity>> build(String workspaceId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Provider that returns the list of available built-in tools.
/// that can be added to the workspace

@ProviderFor(availableToolsToAdd)
final availableToolsToAddProvider = AvailableToolsToAddFamily._();

/// Provider that returns the list of available built-in tools.
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
  /// Provider that returns the list of available built-in tools.
  /// that can be added to the workspace
  AvailableToolsToAddProvider._({
    required AvailableToolsToAddFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'availableToolsToAddProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = workspaceSessionProvider;
  static final $allTransitiveDependencies1 = workspaceToolsProvider;
  static final $allTransitiveDependencies2 =
      WorkspaceToolsNotifierProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies3 =
      WorkspaceToolsNotifierProvider.$allTransitiveDependencies2;

  @override
  String debugGetCreateSourceHash() => _$availableToolsToAddHash();

  @override
  String toString() {
    return r'availableToolsToAddProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<UserToolType>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserToolType>> create(Ref ref) {
    final argument = this.argument as String;
    return availableToolsToAdd(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AvailableToolsToAddProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$availableToolsToAddHash() =>
    r'89240caa30120407f7c291a68e2f927378055367';

/// Provider that returns the list of available built-in tools.
/// that can be added to the workspace

final class AvailableToolsToAddFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<UserToolType>>, String> {
  AvailableToolsToAddFamily._()
    : super(
        retry: null,
        name: r'availableToolsToAddProvider',
        dependencies: <ProviderOrFamily>[
          workspaceSessionProvider,
          workspaceToolsProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          AvailableToolsToAddProvider.$allTransitiveDependencies0,
          AvailableToolsToAddProvider.$allTransitiveDependencies1,
          AvailableToolsToAddProvider.$allTransitiveDependencies2,
          AvailableToolsToAddProvider.$allTransitiveDependencies3,
        },
        isAutoDispose: true,
      );

  /// Provider that returns the list of available built-in tools.
  /// that can be added to the workspace

  AvailableToolsToAddProvider call(String workspaceId) =>
      AvailableToolsToAddProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'availableToolsToAddProvider';
}

@ProviderFor(workspaceToolRow)
final workspaceToolRowProvider = WorkspaceToolRowFamily._();

final class WorkspaceToolRowProvider
    extends
        $FunctionalProvider<
          WorkspaceToolEntity?,
          WorkspaceToolEntity?,
          WorkspaceToolEntity?
        >
    with $Provider<WorkspaceToolEntity?> {
  WorkspaceToolRowProvider._({
    required WorkspaceToolRowFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceToolRowProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = workspaceToolIndexProvider;
  static final $allTransitiveDependencies1 = workspaceToolsProvider;
  static final $allTransitiveDependencies2 =
      WorkspaceToolsNotifierProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies3 =
      WorkspaceToolsNotifierProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies4 =
      WorkspaceToolsNotifierProvider.$allTransitiveDependencies2;

  @override
  String debugGetCreateSourceHash() => _$workspaceToolRowHash();

  @override
  String toString() {
    return r'workspaceToolRowProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<WorkspaceToolEntity?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceToolEntity? create(Ref ref) {
    final argument = this.argument as String;
    return workspaceToolRow(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceToolEntity? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceToolEntity?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceToolRowProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceToolRowHash() => r'ecf8cfcf10429288dae39712a5a6eb9f7b6506c7';

final class WorkspaceToolRowFamily extends $Family
    with $FunctionalFamilyOverride<WorkspaceToolEntity?, String> {
  WorkspaceToolRowFamily._()
    : super(
        retry: null,
        name: r'workspaceToolRowProvider',
        dependencies: <ProviderOrFamily>[
          workspaceToolIndexProvider,
          workspaceToolsProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          WorkspaceToolRowProvider.$allTransitiveDependencies0,
          WorkspaceToolRowProvider.$allTransitiveDependencies1,
          WorkspaceToolRowProvider.$allTransitiveDependencies2,
          WorkspaceToolRowProvider.$allTransitiveDependencies3,
          WorkspaceToolRowProvider.$allTransitiveDependencies4,
        },
        isAutoDispose: true,
      );

  WorkspaceToolRowProvider call(String workspaceId) =>
      WorkspaceToolRowProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceToolRowProvider';
}
