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
final toolDisplayNameProvider = ToolDisplayNameFamily._();

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
  ToolDisplayNameProvider._({
    required ToolDisplayNameFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'toolDisplayNameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = mcpServerNameProvider;
  static final $allTransitiveDependencies1 =
      McpServerNameProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      McpServerNameProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      McpServerNameProvider.$allTransitiveDependencies2;

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

String _$toolDisplayNameHash() => r'dbd6aebd57b28f291a176efbc129b57da8d9ab81';

/// Provides a human-friendly display name for a tool composite ID.
///
/// For MCP tools, fetches the original server name from the database.
/// For built-in tools, formats the tool identifier.
/// Uses Riverpod's family caching to avoid repeated lookups.

final class ToolDisplayNameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  ToolDisplayNameFamily._()
    : super(
        retry: null,
        name: r'toolDisplayNameProvider',
        dependencies: <ProviderOrFamily>[
          mcpServerNameProvider,
          mcpServersRepositoryProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          ToolDisplayNameProvider.$allTransitiveDependencies0,
          ToolDisplayNameProvider.$allTransitiveDependencies1,
          ToolDisplayNameProvider.$allTransitiveDependencies2,
          ToolDisplayNameProvider.$allTransitiveDependencies3,
        },
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
@Dependencies([mcpServersRepository])
final mcpServerNameProvider = McpServerNameFamily._();

/// Provides the name of an MCP server by its ID.
///
/// Returns null if the server is not found.
/// Cached per server ID via Riverpod's family mechanism.

@Dependencies([mcpServersRepository])
final class McpServerNameProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Provides the name of an MCP server by its ID.
  ///
  /// Returns null if the server is not found.
  /// Cached per server ID via Riverpod's family mechanism.
  McpServerNameProvider._({
    required McpServerNameFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mcpServerNameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = mcpServersRepositoryProvider;
  static final $allTransitiveDependencies1 =
      McpServersRepositoryProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      McpServersRepositoryProvider.$allTransitiveDependencies1;

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

String _$mcpServerNameHash() => r'a39c7f8de9252417ea1fb2303879e420a69eed5c';

/// Provides the name of an MCP server by its ID.
///
/// Returns null if the server is not found.
/// Cached per server ID via Riverpod's family mechanism.

@Dependencies([mcpServersRepository])
final class McpServerNameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  McpServerNameFamily._()
    : super(
        retry: null,
        name: r'mcpServerNameProvider',
        dependencies: <ProviderOrFamily>[mcpServersRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          McpServerNameProvider.$allTransitiveDependencies0,
          McpServerNameProvider.$allTransitiveDependencies1,
          McpServerNameProvider.$allTransitiveDependencies2,
        ],
        isAutoDispose: true,
      );

  /// Provides the name of an MCP server by its ID.
  ///
  /// Returns null if the server is not found.
  /// Cached per server ID via Riverpod's family mechanism.

  @Dependencies([mcpServersRepository])
  McpServerNameProvider call(String mcpServerId) =>
      McpServerNameProvider._(argument: mcpServerId, from: this);

  @override
  String toString() => r'mcpServerNameProvider';
}
