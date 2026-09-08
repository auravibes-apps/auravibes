// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_tools_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceToolsRepository)
final workspaceToolsRepositoryProvider = WorkspaceToolsRepositoryFamily._();

final class WorkspaceToolsRepositoryProvider
    extends
        $FunctionalProvider<
          WorkspaceToolsRepositoryContract,
          WorkspaceToolsRepositoryContract,
          WorkspaceToolsRepositoryContract
        >
    with $Provider<WorkspaceToolsRepositoryContract> {
  WorkspaceToolsRepositoryProvider._({
    required WorkspaceToolsRepositoryFamily super.from,
    required WorkspaceSession super.argument,
  }) : super(
         retry: null,
         name: r'workspaceToolsRepositoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceToolsRepositoryHash();

  @override
  String toString() {
    return r'workspaceToolsRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<WorkspaceToolsRepositoryContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceToolsRepositoryContract create(Ref ref) {
    final argument = this.argument as WorkspaceSession;
    return workspaceToolsRepository(ref, argument);
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

  @override
  bool operator ==(Object other) {
    return other is WorkspaceToolsRepositoryProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceToolsRepositoryHash() =>
    r'96a2c8d6482f43b6c32296f96d532390390f8ea0';

final class WorkspaceToolsRepositoryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          WorkspaceToolsRepositoryContract,
          WorkspaceSession
        > {
  WorkspaceToolsRepositoryFamily._()
    : super(
        retry: null,
        name: r'workspaceToolsRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceToolsRepositoryProvider call(WorkspaceSession session) =>
      WorkspaceToolsRepositoryProvider._(argument: session, from: this);

  @override
  String toString() => r'workspaceToolsRepositoryProvider';
}

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
        dependencies: null,
        $allTransitiveDependencies: null,
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
    r'933fbd618fcee33e7b6a43c10352eadd91bacbdf';

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
    r'b5e15665f83dd2a257b5da607072f1868ad99a7d';

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
/// That can be added to the workspace.

@ProviderFor(availableToolsToAdd)
final availableToolsToAddProvider = AvailableToolsToAddFamily._();

/// Provider that returns the list of available built-in tools.
/// That can be added to the workspace.

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
  /// That can be added to the workspace.
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
    r'87a48b704d9cb6bf3e014813570d0da2a1048687';

/// Provider that returns the list of available built-in tools.
/// That can be added to the workspace.

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

  /// Provider that returns the list of available built-in tools.
  /// That can be added to the workspace.

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

String _$workspaceToolRowHash() => r'b1842c887747b5328f27a5c41cb66e6ab24445d6';

final class WorkspaceToolRowFamily extends $Family
    with $FunctionalFamilyOverride<WorkspaceToolEntity?, String> {
  WorkspaceToolRowFamily._()
    : super(
        retry: null,
        name: r'workspaceToolRowProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceToolRowProvider call(String workspaceId) =>
      WorkspaceToolRowProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceToolRowProvider';
}
