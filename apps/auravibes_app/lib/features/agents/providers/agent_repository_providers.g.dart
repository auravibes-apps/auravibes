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
          AgentToolsRepository,
          AgentToolsRepository,
          AgentToolsRepository
        >
    with $Provider<AgentToolsRepository> {
  AgentToolsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentToolsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agentToolsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AgentToolsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AgentToolsRepository create(Ref ref) {
    return agentToolsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AgentToolsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AgentToolsRepository>(value),
    );
  }
}

String _$agentToolsRepositoryHash() =>
    r'3c3b99279532e7ab5ea2c573fbb68ef512a26c54';
