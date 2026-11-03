// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_setup_preflight_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WorkspaceSetupPreflightRefresh)
final workspaceSetupPreflightRefreshProvider =
    WorkspaceSetupPreflightRefreshFamily._();

final class WorkspaceSetupPreflightRefreshProvider
    extends $NotifierProvider<WorkspaceSetupPreflightRefresh, bool> {
  WorkspaceSetupPreflightRefreshProvider._({
    required WorkspaceSetupPreflightRefreshFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceSetupPreflightRefreshProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceSetupPreflightRefreshHash();

  @override
  String toString() {
    return r'workspaceSetupPreflightRefreshProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WorkspaceSetupPreflightRefresh create() => WorkspaceSetupPreflightRefresh();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceSetupPreflightRefreshProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceSetupPreflightRefreshHash() =>
    r'd0f52c39e095df6d66856113de88cad80d273e70';

final class WorkspaceSetupPreflightRefreshFamily extends $Family
    with
        $ClassFamilyOverride<
          WorkspaceSetupPreflightRefresh,
          bool,
          bool,
          bool,
          String
        > {
  WorkspaceSetupPreflightRefreshFamily._()
    : super(
        retry: null,
        name: r'workspaceSetupPreflightRefreshProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceSetupPreflightRefreshProvider call(String workspaceId) =>
      WorkspaceSetupPreflightRefreshProvider._(
        argument: workspaceId,
        from: this,
      );

  @override
  String toString() => r'workspaceSetupPreflightRefreshProvider';
}

abstract class _$WorkspaceSetupPreflightRefresh extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get workspaceId => _$args;

  bool build(String workspaceId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(workspaceSetupPreflight)
final workspaceSetupPreflightProvider = WorkspaceSetupPreflightFamily._();

final class WorkspaceSetupPreflightProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkspaceSetupPreflight>,
          WorkspaceSetupPreflight,
          FutureOr<WorkspaceSetupPreflight>
        >
    with
        $FutureModifier<WorkspaceSetupPreflight>,
        $FutureProvider<WorkspaceSetupPreflight> {
  WorkspaceSetupPreflightProvider._({
    required WorkspaceSetupPreflightFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceSetupPreflightProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceSetupPreflightHash();

  @override
  String toString() {
    return r'workspaceSetupPreflightProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<WorkspaceSetupPreflight> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WorkspaceSetupPreflight> create(Ref ref) {
    final argument = this.argument as String;
    return workspaceSetupPreflight(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceSetupPreflightProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceSetupPreflightHash() =>
    r'7705b4fb03595333f3a90eb40a256a5342297706';

final class WorkspaceSetupPreflightFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorkspaceSetupPreflight>, String> {
  WorkspaceSetupPreflightFamily._()
    : super(
        retry: null,
        name: r'workspaceSetupPreflightProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkspaceSetupPreflightProvider call(String workspaceId) =>
      WorkspaceSetupPreflightProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceSetupPreflightProvider';
}
