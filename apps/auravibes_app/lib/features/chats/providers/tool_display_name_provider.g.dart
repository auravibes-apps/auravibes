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
/// Callers may pass a presentation-only effective target while retaining the
/// original tool-call identity for approval actions.
/// Uses Riverpod's family caching to avoid repeated lookups.

@ProviderFor(toolDisplayName)
final toolDisplayNameProvider = ToolDisplayNameFamily._();

/// Provides a human-friendly display name for a tool composite ID.
///
/// For MCP tools, fetches the original server name from the database.
/// For built-in tools, formats the tool identifier.
/// Callers may pass a presentation-only effective target while retaining the
/// original tool-call identity for approval actions.
/// Uses Riverpod's family caching to avoid repeated lookups.

final class ToolDisplayNameProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Provides a human-friendly display name for a tool composite ID.
  ///
  /// For MCP tools, fetches the original server name from the database.
  /// For built-in tools, formats the tool identifier.
  /// Callers may pass a presentation-only effective target while retaining the
  /// original tool-call identity for approval actions.
  /// Uses Riverpod's family caching to avoid repeated lookups.
  ToolDisplayNameProvider._({
    required ToolDisplayNameFamily super.from,
    required (String, String) super.argument,
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
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as (String, String);
    return toolDisplayName(ref, argument.$1, argument.$2);
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

String _$toolDisplayNameHash() => r'a2d60f753622038ffd5b28a489439538de6577c5';

/// Provides a human-friendly display name for a tool composite ID.
///
/// For MCP tools, fetches the original server name from the database.
/// For built-in tools, formats the tool identifier.
/// Callers may pass a presentation-only effective target while retaining the
/// original tool-call identity for approval actions.
/// Uses Riverpod's family caching to avoid repeated lookups.

final class ToolDisplayNameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, (String, String)> {
  ToolDisplayNameFamily._()
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
  /// Callers may pass a presentation-only effective target while retaining the
  /// original tool-call identity for approval actions.
  /// Uses Riverpod's family caching to avoid repeated lookups.

  ToolDisplayNameProvider call(String workspaceId, String compositeToolId) =>
      ToolDisplayNameProvider._(
        argument: (workspaceId, compositeToolId),
        from: this,
      );

  @override
  String toString() => r'toolDisplayNameProvider';
}

/// Provides the name of an MCP server by its ID.
///
/// Returns null if the server is not found.
/// Cached per server ID via Riverpod's family mechanism.

@ProviderFor(mcpServerName)
final mcpServerNameProvider = McpServerNameFamily._();

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
  McpServerNameProvider._({
    required McpServerNameFamily super.from,
    required (String, String) super.argument,
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
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return mcpServerName(ref, argument.$1, argument.$2);
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

String _$mcpServerNameHash() => r'2999fc88bffc8a1df293073f80e80297f97f4da0';

/// Provides the name of an MCP server by its ID.
///
/// Returns null if the server is not found.
/// Cached per server ID via Riverpod's family mechanism.

final class McpServerNameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, (String, String)> {
  McpServerNameFamily._()
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

  McpServerNameProvider call(String workspaceId, String mcpServerId) =>
      McpServerNameProvider._(argument: (workspaceId, mcpServerId), from: this);

  @override
  String toString() => r'mcpServerNameProvider';
}
