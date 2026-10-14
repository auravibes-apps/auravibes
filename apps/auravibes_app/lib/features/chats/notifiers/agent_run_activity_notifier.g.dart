// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_run_activity_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AgentRunActivityNotifier)
final agentRunActivityProvider = AgentRunActivityNotifierProvider._();

final class AgentRunActivityNotifierProvider
    extends $NotifierProvider<AgentRunActivityNotifier, Set<String>> {
  AgentRunActivityNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentRunActivityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agentRunActivityNotifierHash();

  @$internal
  @override
  AgentRunActivityNotifier create() => AgentRunActivityNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$agentRunActivityNotifierHash() =>
    r'8d80f8a488323c054d27573cc89d92a15eae7ee5';

abstract class _$AgentRunActivityNotifier extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
