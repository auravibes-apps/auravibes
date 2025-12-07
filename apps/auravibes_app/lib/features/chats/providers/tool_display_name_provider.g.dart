// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_display_name_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a human-friendly display name for a tool composite ID.
///
/// For MCP tools, fetches the original server name from the database.
/// For built-in tools, formats the tool identifier.
/// Uses Riverpod's family caching to avoid repeated lookups.

@ProviderFor(toolDisplayName)
const toolDisplayNameProvider = ToolDisplayNameFamily._();

/// Provides a human-friendly display name for a tool composite ID.
///
/// For MCP tools, fetches the original server name from the database.
/// For built-in tools, formats the tool identifier.
/// Uses Riverpod's family caching to avoid repeated lookups.

final class ToolDisplayNameProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Provides a human-friendly display name for a tool composite ID.
  ///
  /// For MCP tools, fetches the original server name from the database.
  /// For built-in tools, formats the tool identifier.
  /// Uses Riverpod's family caching to avoid repeated lookups.
  const ToolDisplayNameProvider._({
    required ToolDisplayNameFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'toolDisplayNameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$toolDisplayNameHash();

  @override
  String toString() {
    return r'toolDisplayNameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return toolDisplayName(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ToolDisplayNameProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$toolDisplayNameHash() => r'565aa772eed3419d17a63e266556d35494c6ed07';

/// Provides a human-friendly display name for a tool composite ID.
///
/// For MCP tools, fetches the original server name from the database.
/// For built-in tools, formats the tool identifier.
/// Uses Riverpod's family caching to avoid repeated lookups.

final class ToolDisplayNameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  const ToolDisplayNameFamily._()
    : super(
        retry: null,
        name: r'toolDisplayNameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides a human-friendly display name for a tool composite ID.
  ///
  /// For MCP tools, fetches the original server name from the database.
  /// For built-in tools, formats the tool identifier.
  /// Uses Riverpod's family caching to avoid repeated lookups.

  ToolDisplayNameProvider call(String compositeToolId) =>
      ToolDisplayNameProvider._(argument: compositeToolId, from: this);

  @override
  String toString() => r'toolDisplayNameProvider';
}

/// Provides the name of an MCP server by its ID.
///
/// Returns null if the server is not found.
/// Cached per server ID via Riverpod's family mechanism.

@ProviderFor(mcpServerName)
const mcpServerNameProvider = McpServerNameFamily._();

/// Provides the name of an MCP server by its ID.
///
/// Returns null if the server is not found.
/// Cached per server ID via Riverpod's family mechanism.

final class McpServerNameProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Provides the name of an MCP server by its ID.
  ///
  /// Returns null if the server is not found.
  /// Cached per server ID via Riverpod's family mechanism.
  const McpServerNameProvider._({
    required McpServerNameFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mcpServerNameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mcpServerNameHash();

  @override
  String toString() {
    return r'mcpServerNameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return mcpServerName(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is McpServerNameProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mcpServerNameHash() => r'a4f0fbf1e58c5c298f62f11c76f1a829d545853a';

/// Provides the name of an MCP server by its ID.
///
/// Returns null if the server is not found.
/// Cached per server ID via Riverpod's family mechanism.

final class McpServerNameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  const McpServerNameFamily._()
    : super(
        retry: null,
        name: r'mcpServerNameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the name of an MCP server by its ID.
  ///
  /// Returns null if the server is not found.
  /// Cached per server ID via Riverpod's family mechanism.

  McpServerNameProvider call(String mcpServerId) =>
      McpServerNameProvider._(argument: mcpServerId, from: this);

  @override
  String toString() => r'mcpServerNameProvider';
}
