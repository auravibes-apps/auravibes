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
const mcpManagerProvider = McpManagerNotifierProvider._();

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
  const McpManagerNotifierProvider._()
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
    r'de6e3d288fddfecc52cdb77eab53d8724f2f4bf6';

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
    final created = build();
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
    element.handleValue(ref, created);
  }
}

/// Provides a flat list of all available MCP tools.

@ProviderFor(allMcpTools)
const allMcpToolsProvider = AllMcpToolsProvider._();

/// Provides a flat list of all available MCP tools.

final class AllMcpToolsProvider
    extends
        $FunctionalProvider<
          List<McpToolInfo>,
          List<McpToolInfo>,
          List<McpToolInfo>
        >
    with $Provider<List<McpToolInfo>> {
  /// Provides a flat list of all available MCP tools.
  const AllMcpToolsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allMcpToolsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allMcpToolsHash();

  @$internal
  @override
  $ProviderElement<List<McpToolInfo>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<McpToolInfo> create(Ref ref) {
    return allMcpTools(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<McpToolInfo> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<McpToolInfo>>(value),
    );
  }
}

String _$allMcpToolsHash() => r'bd827b0afddde31e5cd9f97733b8d8cba871290e';

/// Provides MCP tools as ToolSpec for the chatbot service.

@ProviderFor(mcpToolSpecs)
const mcpToolSpecsProvider = McpToolSpecsProvider._();

/// Provides MCP tools as ToolSpec for the chatbot service.

final class McpToolSpecsProvider
    extends $FunctionalProvider<List<ToolSpec>, List<ToolSpec>, List<ToolSpec>>
    with $Provider<List<ToolSpec>> {
  /// Provides MCP tools as ToolSpec for the chatbot service.
  const McpToolSpecsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mcpToolSpecsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mcpToolSpecsHash();

  @$internal
  @override
  $ProviderElement<List<ToolSpec>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<ToolSpec> create(Ref ref) {
    return mcpToolSpecs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ToolSpec> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ToolSpec>>(value),
    );
  }
}

String _$mcpToolSpecsHash() => r'6714cc0f15e367e2093a5317a138057eaf1504f7';

/// Provides the list of MCP connection states that are currently connecting
/// from the specified server IDs.
///
/// This is useful for UI to show which specific MCPs are being waited on.

@ProviderFor(connectingMcpServers)
const connectingMcpServersProvider = ConnectingMcpServersFamily._();

/// Provides the list of MCP connection states that are currently connecting
/// from the specified server IDs.
///
/// This is useful for UI to show which specific MCPs are being waited on.

final class ConnectingMcpServersProvider
    extends
        $FunctionalProvider<
          List<McpConnectionState>,
          List<McpConnectionState>,
          List<McpConnectionState>
        >
    with $Provider<List<McpConnectionState>> {
  /// Provides the list of MCP connection states that are currently connecting
  /// from the specified server IDs.
  ///
  /// This is useful for UI to show which specific MCPs are being waited on.
  const ConnectingMcpServersProvider._({
    required ConnectingMcpServersFamily super.from,
    required List<String> super.argument,
  }) : super(
         retry: null,
         name: r'connectingMcpServersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$connectingMcpServersHash();

  @override
  String toString() {
    return r'connectingMcpServersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<McpConnectionState>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<McpConnectionState> create(Ref ref) {
    final argument = this.argument as List<String>;
    return connectingMcpServers(ref, mcpServerIds: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<McpConnectionState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<McpConnectionState>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConnectingMcpServersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$connectingMcpServersHash() =>
    r'59551d121917907b02dcc89feb7908c6a0c31bbb';

/// Provides the list of MCP connection states that are currently connecting
/// from the specified server IDs.
///
/// This is useful for UI to show which specific MCPs are being waited on.

final class ConnectingMcpServersFamily extends $Family
    with $FunctionalFamilyOverride<List<McpConnectionState>, List<String>> {
  const ConnectingMcpServersFamily._()
    : super(
        retry: null,
        name: r'connectingMcpServersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the list of MCP connection states that are currently connecting
  /// from the specified server IDs.
  ///
  /// This is useful for UI to show which specific MCPs are being waited on.

  ConnectingMcpServersProvider call({required List<String> mcpServerIds}) =>
      ConnectingMcpServersProvider._(argument: mcpServerIds, from: this);

  @override
  String toString() => r'connectingMcpServersProvider';
}

/// Provider that returns true if any of the specified MCP servers are
/// connecting.

@ProviderFor(isMcpConnectionsPending)
const isMcpConnectionsPendingProvider = IsMcpConnectionsPendingFamily._();

/// Provider that returns true if any of the specified MCP servers are
/// connecting.

final class IsMcpConnectionsPendingProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider that returns true if any of the specified MCP servers are
  /// connecting.
  const IsMcpConnectionsPendingProvider._({
    required IsMcpConnectionsPendingFamily super.from,
    required List<String> super.argument,
  }) : super(
         retry: null,
         name: r'isMcpConnectionsPendingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isMcpConnectionsPendingHash();

  @override
  String toString() {
    return r'isMcpConnectionsPendingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as List<String>;
    return isMcpConnectionsPending(ref, mcpServerIds: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsMcpConnectionsPendingProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isMcpConnectionsPendingHash() =>
    r'b2aef2d729f922c1d79aa067b60e635f93154e73';

/// Provider that returns true if any of the specified MCP servers are
/// connecting.

final class IsMcpConnectionsPendingFamily extends $Family
    with $FunctionalFamilyOverride<bool, List<String>> {
  const IsMcpConnectionsPendingFamily._()
    : super(
        retry: null,
        name: r'isMcpConnectionsPendingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider that returns true if any of the specified MCP servers are
  /// connecting.

  IsMcpConnectionsPendingProvider call({required List<String> mcpServerIds}) =>
      IsMcpConnectionsPendingProvider._(argument: mcpServerIds, from: this);

  @override
  String toString() => r'isMcpConnectionsPendingProvider';
}
