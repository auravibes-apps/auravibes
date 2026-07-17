// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the MCP servers repository instance.

@ProviderFor(mcpServersRepository)
final mcpServersRepositoryProvider = McpServersRepositoryProvider._();

/// Provides the MCP servers repository instance.

final class McpServersRepositoryProvider
    extends
        $FunctionalProvider<
          McpServersRepositoryContract,
          McpServersRepositoryContract,
          McpServersRepositoryContract
        >
    with $Provider<McpServersRepositoryContract> {
  /// Provides the MCP servers repository instance.
  McpServersRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpServersRepositoryProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          workspaceSessionProvider,
          cloudWorkspaceStateGatewayProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          McpServersRepositoryProvider.$allTransitiveDependencies0,
          McpServersRepositoryProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = workspaceSessionProvider;
  static final $allTransitiveDependencies1 = cloudWorkspaceStateGatewayProvider;

  @override
  String debugGetCreateSourceHash() => _$mcpServersRepositoryHash();

  @$internal
  @override
  $ProviderElement<McpServersRepositoryContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  McpServersRepositoryContract create(Ref ref) {
    return mcpServersRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(McpServersRepositoryContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<McpServersRepositoryContract>(value),
    );
  }
}

String _$mcpServersRepositoryHash() =>
    r'95b8789a0e79450cdd04b5d4c6b8993de374e519';
