// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_lifecycle_hook_runner_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workspaceLifecycleHookRunner)
final workspaceLifecycleHookRunnerProvider =
    WorkspaceLifecycleHookRunnerProvider._();

final class WorkspaceLifecycleHookRunnerProvider
    extends
        $FunctionalProvider<
          WorkspaceLifecycleHookRunner,
          WorkspaceLifecycleHookRunner,
          WorkspaceLifecycleHookRunner
        >
    with $Provider<WorkspaceLifecycleHookRunner> {
  WorkspaceLifecycleHookRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceLifecycleHookRunnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceLifecycleHookRunnerHash();

  @$internal
  @override
  $ProviderElement<WorkspaceLifecycleHookRunner> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkspaceLifecycleHookRunner create(Ref ref) {
    return workspaceLifecycleHookRunner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkspaceLifecycleHookRunner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkspaceLifecycleHookRunner>(value),
    );
  }
}

String _$workspaceLifecycleHookRunnerHash() =>
    r'bb9587018aa5160e6d85a97f84f987a91fba519f';
