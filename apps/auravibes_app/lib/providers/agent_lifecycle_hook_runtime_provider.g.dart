// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_lifecycle_hook_runtime_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(agentLifecycleHookRuntime)
final agentLifecycleHookRuntimeProvider = AgentLifecycleHookRuntimeProvider._();

final class AgentLifecycleHookRuntimeProvider
    extends
        $FunctionalProvider<
          AgentLifecycleHookRuntime,
          AgentLifecycleHookRuntime,
          AgentLifecycleHookRuntime
        >
    with $Provider<AgentLifecycleHookRuntime> {
  AgentLifecycleHookRuntimeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentLifecycleHookRuntimeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agentLifecycleHookRuntimeHash();

  @$internal
  @override
  $ProviderElement<AgentLifecycleHookRuntime> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AgentLifecycleHookRuntime create(Ref ref) {
    return agentLifecycleHookRuntime(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AgentLifecycleHookRuntime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AgentLifecycleHookRuntime>(value),
    );
  }
}

String _$agentLifecycleHookRuntimeHash() =>
    r'ec6bddeb377dfb82e93bdff1514cf5a3eed3c695';
