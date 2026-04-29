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
          McpServersRepository,
          McpServersRepository,
          McpServersRepository
        >
    with $Provider<McpServersRepository> {
  /// Provides the MCP servers repository instance.
  McpServersRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpServersRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mcpServersRepositoryHash();

  @$internal
  @override
  $ProviderElement<McpServersRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  McpServersRepository create(Ref ref) {
    return mcpServersRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(McpServersRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<McpServersRepository>(value),
    );
  }
}

String _$mcpServersRepositoryHash() =>
    r'bee4c8c1c586891c5843ba456c8315984bca173a';
