// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the MCP servers repository instance.

@ProviderFor(mcpServersRepository)
final mcpServersRepositoryProvider = McpServersRepositoryFamily._();

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
  McpServersRepositoryProvider._({
    required McpServersRepositoryFamily super.from,
    required WorkspaceSession super.argument,
  }) : super(
         retry: null,
         name: r'mcpServersRepositoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mcpServersRepositoryHash();

  @override
  String toString() {
    return r'mcpServersRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<McpServersRepositoryContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  McpServersRepositoryContract create(Ref ref) {
    final argument = this.argument as WorkspaceSession;
    return mcpServersRepository(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(McpServersRepositoryContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<McpServersRepositoryContract>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is McpServersRepositoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mcpServersRepositoryHash() =>
    r'0b1356031e56c1ac0dd7a50018a88fd3192b7305';

/// Provides the MCP servers repository instance.

final class McpServersRepositoryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          McpServersRepositoryContract,
          WorkspaceSession
        > {
  McpServersRepositoryFamily._()
    : super(
        retry: null,
        name: r'mcpServersRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the MCP servers repository instance.

  McpServersRepositoryProvider call(WorkspaceSession session) =>
      McpServersRepositoryProvider._(argument: session, from: this);

  @override
  String toString() => r'mcpServersRepositoryProvider';
}
