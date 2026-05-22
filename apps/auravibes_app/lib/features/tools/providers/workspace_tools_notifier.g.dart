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
    r'f6b4329abc5f3efb03bca433566ff358c11b2443';

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
        dependencies: null,
        $allTransitiveDependencies: null,
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
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Provider that returns the list of available built-in tools
/// that can be added to the workspace

@ProviderFor(availableToolsToAdd)
final availableToolsToAddProvider = AvailableToolsToAddFamily._();

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
    r'b4421c2ea167f1368160bbd3e3fc633b1058cab5';

/// Provider that returns the list of available built-in tools
/// that can be added to the workspace

final class AvailableToolsToAddFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<UserToolType>>, String> {
  AvailableToolsToAddFamily._()
    : super(
        retry: null,
        name: r'availableToolsToAddProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider that returns the list of available built-in tools
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

String _$workspaceToolRowHash() => r'98da508abeef3098647014b19db4a128cecee81a';

final class WorkspaceToolRowFamily extends $Family
    with $FunctionalFamilyOverride<WorkspaceToolEntity?, String> {
  WorkspaceToolRowFamily._()
    : super(
        retry: null,
        name: r'workspaceToolRowProvider',
        dependencies: <ProviderOrFamily>[workspaceToolIndexProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          WorkspaceToolRowProvider.$allTransitiveDependencies0,
        ],
        isAutoDispose: true,
      );

  WorkspaceToolRowProvider call(String workspaceId) =>
      WorkspaceToolRowProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceToolRowProvider';
}
