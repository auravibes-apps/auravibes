// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(agentsRepository)
final agentsRepositoryProvider = AgentsRepositoryProvider._();

final class AgentsRepositoryProvider
    extends
        $FunctionalProvider<
          AgentsRepository,
          AgentsRepository,
          AgentsRepository
        >
    with $Provider<AgentsRepository> {
  AgentsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agentsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AgentsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AgentsRepository create(Ref ref) {
    return agentsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AgentsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AgentsRepository>(value),
    );
  }
}

String _$agentsRepositoryHash() => r'665f61f3b474d21b235ab28ac514cca0bc7a7329';

@ProviderFor(agentToolsRepository)
final agentToolsRepositoryProvider = AgentToolsRepositoryFamily._();

final class AgentToolsRepositoryProvider
    extends
        $FunctionalProvider<
          AgentToolsRepositoryContract,
          AgentToolsRepositoryContract,
          AgentToolsRepositoryContract
        >
    with $Provider<AgentToolsRepositoryContract> {
  AgentToolsRepositoryProvider._({
    required AgentToolsRepositoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'agentToolsRepositoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$agentToolsRepositoryHash();

  @override
  String toString() {
    return r'agentToolsRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AgentToolsRepositoryContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AgentToolsRepositoryContract create(Ref ref) {
    final argument = this.argument as String;
    return agentToolsRepository(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AgentToolsRepositoryContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AgentToolsRepositoryContract>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AgentToolsRepositoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$agentToolsRepositoryHash() =>
    r'c5686288a3cfa938d0784410dae95f2fc1d95717';

final class AgentToolsRepositoryFamily extends $Family
    with $FunctionalFamilyOverride<AgentToolsRepositoryContract, String> {
  AgentToolsRepositoryFamily._()
    : super(
        retry: null,
        name: r'agentToolsRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AgentToolsRepositoryProvider call(String workspaceId) =>
      AgentToolsRepositoryProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'agentToolsRepositoryProvider';
}
