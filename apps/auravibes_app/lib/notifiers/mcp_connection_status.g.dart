// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_connection_status.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages MCP server connections and their tools.
///
/// This notifier handles:
/// - Adding new MCP servers (saves to database and connects)
/// - Loading MCPs from database on startup
/// - Maintaining active connections to MCP servers
/// - Tracking tools from each MCP server with prefixed names
/// - Deleting MCP servers
/// - Executing MCP tools
///
/// Tools are stored with a composite ID format:
/// `mcp_<mcpId>_<slugName>_<toolIdentifier>`
/// - mcpId: Database ID for uniqueness
/// - slugName: URL-safe server name for LLM readability
/// - toolIdentifier: Original tool identifier from the MCP server
///
/// See [McpToolIdComponents] for parsing composite IDs.

@ProviderFor(McpConnectionNotifier)
final mcpConnectionProvider = McpConnectionNotifierProvider._();

/// Manages MCP server connections and their tools.
///
/// This notifier handles:
/// - Adding new MCP servers (saves to database and connects)
/// - Loading MCPs from database on startup
/// - Maintaining active connections to MCP servers
/// - Tracking tools from each MCP server with prefixed names
/// - Deleting MCP servers
/// - Executing MCP tools
///
/// Tools are stored with a composite ID format:
/// `mcp_<mcpId>_<slugName>_<toolIdentifier>`
/// - mcpId: Database ID for uniqueness
/// - slugName: URL-safe server name for LLM readability
/// - toolIdentifier: Original tool identifier from the MCP server
///
/// See [McpToolIdComponents] for parsing composite IDs.
final class McpConnectionNotifierProvider
    extends $NotifierProvider<McpConnectionNotifier, List<McpConnectionState>> {
  /// Manages MCP server connections and their tools.
  ///
  /// This notifier handles:
  /// - Adding new MCP servers (saves to database and connects)
  /// - Loading MCPs from database on startup
  /// - Maintaining active connections to MCP servers
  /// - Tracking tools from each MCP server with prefixed names
  /// - Deleting MCP servers
  /// - Executing MCP tools
  ///
  /// Tools are stored with a composite ID format:
  /// `mcp_<mcpId>_<slugName>_<toolIdentifier>`
  /// - mcpId: Database ID for uniqueness
  /// - slugName: URL-safe server name for LLM readability
  /// - toolIdentifier: Original tool identifier from the MCP server
  ///
  /// See [McpToolIdComponents] for parsing composite IDs.
  McpConnectionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpConnectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mcpConnectionNotifierHash();

  @$internal
  @override
  McpConnectionNotifier create() => McpConnectionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<McpConnectionState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<McpConnectionState>>(value),
    );
  }
}

String _$mcpConnectionNotifierHash() =>
    r'8e12a8cbffd564b0babab0011915c0c6fba8fd9b';

/// Manages MCP server connections and their tools.
///
/// This notifier handles:
/// - Adding new MCP servers (saves to database and connects)
/// - Loading MCPs from database on startup
/// - Maintaining active connections to MCP servers
/// - Tracking tools from each MCP server with prefixed names
/// - Deleting MCP servers
/// - Executing MCP tools
///
/// Tools are stored with a composite ID format:
/// `mcp_<mcpId>_<slugName>_<toolIdentifier>`
/// - mcpId: Database ID for uniqueness
/// - slugName: URL-safe server name for LLM readability
/// - toolIdentifier: Original tool identifier from the MCP server
///
/// See [McpToolIdComponents] for parsing composite IDs.

abstract class _$McpConnectionNotifier
    extends $Notifier<List<McpConnectionState>> {
  List<McpConnectionState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<List<McpConnectionState>, List<McpConnectionState>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<McpConnectionState>, List<McpConnectionState>>,
              List<McpConnectionState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(mcpManagerService)
final mcpManagerServiceProvider = McpManagerServiceProvider._();

final class McpManagerServiceProvider
    extends
        $FunctionalProvider<
          McpManagerService,
          McpManagerService,
          McpManagerService
        >
    with $Provider<McpManagerService> {
  McpManagerServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpManagerServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mcpManagerServiceHash();

  @$internal
  @override
  $ProviderElement<McpManagerService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  McpManagerService create(Ref ref) {
    return mcpManagerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(McpManagerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<McpManagerService>(value),
    );
  }
}

String _$mcpManagerServiceHash() => r'd1f412f8c54aa7a16cf655a10544e230235dac3e';
