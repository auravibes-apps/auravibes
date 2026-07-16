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
final agentToolsRepositoryProvider = AgentToolsRepositoryProvider._();

final class AgentToolsRepositoryProvider
    extends
        $FunctionalProvider<
          AgentToolsRepositoryContract,
          AgentToolsRepositoryContract,
          AgentToolsRepositoryContract
        >
    with $Provider<AgentToolsRepositoryContract> {
  AgentToolsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentToolsRepositoryProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          workspaceSessionProvider,
          cloudWorkspaceStateGatewayProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          AgentToolsRepositoryProvider.$allTransitiveDependencies0,
          AgentToolsRepositoryProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = workspaceSessionProvider;
  static final $allTransitiveDependencies1 = cloudWorkspaceStateGatewayProvider;

  @override
  String debugGetCreateSourceHash() => _$agentToolsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AgentToolsRepositoryContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AgentToolsRepositoryContract create(Ref ref) {
    return agentToolsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AgentToolsRepositoryContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AgentToolsRepositoryContract>(value),
    );
  }
}

String _$agentToolsRepositoryHash() =>
    r'a3489fbf222882e50b0890e0e91f266f2ababaf1';
