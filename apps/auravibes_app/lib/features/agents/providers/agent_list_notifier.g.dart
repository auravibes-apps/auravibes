// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Retains the existing query, loaded pages and cursor across list visits.

@ProviderFor(AgentListNotifier)
final agentListProvider = AgentListNotifierFamily._();

/// Retains the existing query, loaded pages and cursor across list visits.
final class AgentListNotifierProvider
    extends $AsyncNotifierProvider<AgentListNotifier, AgentListState> {
  /// Retains the existing query, loaded pages and cursor across list visits.
  AgentListNotifierProvider._({
    required AgentListNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'agentListProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$agentListNotifierHash();

  @override
  String toString() {
    return r'agentListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AgentListNotifier create() => AgentListNotifier();

  @override
  bool operator ==(Object other) {
    return other is AgentListNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$agentListNotifierHash() => r'e67750d207ede7877c22cbedaa4e4a184e144bca';

/// Retains the existing query, loaded pages and cursor across list visits.

final class AgentListNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          AgentListNotifier,
          AsyncValue<AgentListState>,
          AgentListState,
          FutureOr<AgentListState>,
          String
        > {
  AgentListNotifierFamily._()
    : super(
        retry: null,
        name: r'agentListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Retains the existing query, loaded pages and cursor across list visits.

  AgentListNotifierProvider call(String workspaceId) =>
      AgentListNotifierProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'agentListProvider';
}

/// Retains the existing query, loaded pages and cursor across list visits.

abstract class _$AgentListNotifier extends $AsyncNotifier<AgentListState> {
  late final _$args = ref.$arg as String;
  String get workspaceId => _$args;

  FutureOr<AgentListState> build(String workspaceId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AgentListState>, AgentListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AgentListState>, AgentListState>,
              AsyncValue<AgentListState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
