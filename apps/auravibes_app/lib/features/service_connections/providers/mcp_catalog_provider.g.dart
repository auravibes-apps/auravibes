// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_catalog_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mcpCatalog)
final mcpCatalogProvider = McpCatalogFamily._();

final class McpCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<McpCatalogListing>>,
          List<McpCatalogListing>,
          FutureOr<List<McpCatalogListing>>
        >
    with
        $FutureModifier<List<McpCatalogListing>>,
        $FutureProvider<List<McpCatalogListing>> {
  McpCatalogProvider._({
    required McpCatalogFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mcpCatalogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mcpCatalogHash();

  @override
  String toString() {
    return r'mcpCatalogProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<McpCatalogListing>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<McpCatalogListing>> create(Ref ref) {
    final argument = this.argument as String;
    return mcpCatalog(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is McpCatalogProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mcpCatalogHash() => r'f58fb6fdc6dc2f09e4b676a7a0cb5bfae9f6a47d';

final class McpCatalogFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<McpCatalogListing>>, String> {
  McpCatalogFamily._()
    : super(
        retry: null,
        name: r'mcpCatalogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  McpCatalogProvider call(String workspaceId) =>
      McpCatalogProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'mcpCatalogProvider';
}
