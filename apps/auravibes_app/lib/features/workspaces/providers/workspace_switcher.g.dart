// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_switcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider that manages workspace switching with debounce, loading guard,
/// error handling, and structured logging of switch timing.
///
/// Uses a plain Notifier instead of AsyncNotifier because the switch
/// action is a transient mutation, not initialized state. Per the Mutation
/// State Contract, manual AsyncValue toggling is avoided; the state object
/// itself tracks idle/loading/error status.

@ProviderFor(WorkspaceSwitcher)
final workspaceSwitcherProvider = WorkspaceSwitcherProvider._();

/// Provider that manages workspace switching with debounce, loading guard,
/// error handling, and structured logging of switch timing.
///
/// Uses a plain Notifier instead of AsyncNotifier because the switch
/// action is a transient mutation, not initialized state. Per the Mutation
/// State Contract, manual AsyncValue toggling is avoided; the state object
/// itself tracks idle/loading/error status.
final class WorkspaceSwitcherProvider
    extends $NotifierProvider<WorkspaceSwitcher, WorkspaceSwitchState> {
  /// Provider that manages workspace switching with debounce, loading guard,
  /// error handling, and structured logging of switch timing.
  ///
  /// Uses a plain Notifier instead of AsyncNotifier because the switch
  /// action is a transient mutation, not initialized state. Per the Mutation
  /// State Contract, manual AsyncValue toggling is avoided; the state object
  /// itself tracks idle/loading/error status.
  WorkspaceSwitcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceSwitcherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceSwitcherHash();

  @$internal
  @override
  WorkspaceSwitcher create() => WorkspaceSwitcher();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceSwitchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceSwitchState>(value),
    );
  }
}

String _$workspaceSwitcherHash() => r'cfa78b8e912c8a9b1ccc78b09feb265d9fe8d343';

/// Provider that manages workspace switching with debounce, loading guard,
/// error handling, and structured logging of switch timing.
///
/// Uses a plain Notifier instead of AsyncNotifier because the switch
/// action is a transient mutation, not initialized state. Per the Mutation
/// State Contract, manual AsyncValue toggling is avoided; the state object
/// itself tracks idle/loading/error status.

abstract class _$WorkspaceSwitcher extends $Notifier<WorkspaceSwitchState> {
  WorkspaceSwitchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<WorkspaceSwitchState, WorkspaceSwitchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WorkspaceSwitchState, WorkspaceSwitchState>,
              WorkspaceSwitchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
