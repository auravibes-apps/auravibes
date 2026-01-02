// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_manager_provider.dart';

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
/// `mcp::<mcpId>::<slugName>::<toolName>`
/// - mcpId: Database ID for uniqueness
/// - slugName: URL-safe server name for LLM readability
/// - toolName: Original tool identifier from the MCP server

@ProviderFor(McpManagerNotifier)
final mcpManagerProvider = McpManagerNotifierProvider._();

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
/// `mcp::<mcpId>::<slugName>::<toolName>`
/// - mcpId: Database ID for uniqueness
/// - slugName: URL-safe server name for LLM readability
/// - toolName: Original tool identifier from the MCP server
final class McpManagerNotifierProvider
    extends $NotifierProvider<McpManagerNotifier, List<McpConnectionState>> {
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
  /// `mcp::<mcpId>::<slugName>::<toolName>`
  /// - mcpId: Database ID for uniqueness
  /// - slugName: URL-safe server name for LLM readability
  /// - toolName: Original tool identifier from the MCP server
  McpManagerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mcpManagerNotifierHash();

  @$internal
  @override
  McpManagerNotifier create() => McpManagerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<McpConnectionState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<McpConnectionState>>(value),
    );
  }
}

String _$mcpManagerNotifierHash() =>
    r'bb51cbf190af7b016b3a2d401f18aeadd9d69b12';

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
/// `mcp::<mcpId>::<slugName>::<toolName>`
/// - mcpId: Database ID for uniqueness
/// - slugName: URL-safe server name for LLM readability
/// - toolName: Original tool identifier from the MCP server

abstract class _$McpManagerNotifier
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
        isAutoDispose: true,
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

String _$mcpManagerServiceHash() => r'84a42758d3ad321cd0fdbd06703e0e0d7343bbbb';
