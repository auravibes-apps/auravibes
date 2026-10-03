// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_navigation_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Retains safe list categories across listener gaps for each workspace.

@ProviderFor(WorkspaceNavigationNotifier)
final workspaceNavigationProvider = WorkspaceNavigationNotifierFamily._();

/// Retains safe list categories across listener gaps for each workspace.
final class WorkspaceNavigationNotifierProvider
    extends
        $NotifierProvider<
          WorkspaceNavigationNotifier,
          WorkspaceNavigationState
        > {
  /// Retains safe list categories across listener gaps for each workspace.
  WorkspaceNavigationNotifierProvider._({
    required WorkspaceNavigationNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workspaceNavigationProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workspaceNavigationNotifierHash();

  @override
  String toString() {
    return r'workspaceNavigationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WorkspaceNavigationNotifier create() => WorkspaceNavigationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceNavigationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceNavigationState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceNavigationNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workspaceNavigationNotifierHash() =>
    r'88dec7f35ffbeb59f1479f394e73e601e4956327';

/// Retains safe list categories across listener gaps for each workspace.

final class WorkspaceNavigationNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          WorkspaceNavigationNotifier,
          WorkspaceNavigationState,
          WorkspaceNavigationState,
          WorkspaceNavigationState,
          String
        > {
  WorkspaceNavigationNotifierFamily._()
    : super(
        retry: null,
        name: r'workspaceNavigationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Retains safe list categories across listener gaps for each workspace.

  WorkspaceNavigationNotifierProvider call(String workspaceId) =>
      WorkspaceNavigationNotifierProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'workspaceNavigationProvider';
}

/// Retains safe list categories across listener gaps for each workspace.

abstract class _$WorkspaceNavigationNotifier
    extends $Notifier<WorkspaceNavigationState> {
  late final _$args = ref.$arg as String;
  String get workspaceId => _$args;

  WorkspaceNavigationState build(String workspaceId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<WorkspaceNavigationState, WorkspaceNavigationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WorkspaceNavigationState, WorkspaceNavigationState>,
              WorkspaceNavigationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
