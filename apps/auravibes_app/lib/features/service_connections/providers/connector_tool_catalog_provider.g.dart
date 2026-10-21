// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connector_tool_catalog_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(connectorToolCatalog)
final connectorToolCatalogProvider = ConnectorToolCatalogProvider._();

final class ConnectorToolCatalogProvider
    extends
        $FunctionalProvider<
          List<ConnectorToolCatalogItem>,
          List<ConnectorToolCatalogItem>,
          List<ConnectorToolCatalogItem>
        >
    with $Provider<List<ConnectorToolCatalogItem>> {
  ConnectorToolCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectorToolCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectorToolCatalogHash();

  @$internal
  @override
  $ProviderElement<List<ConnectorToolCatalogItem>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ConnectorToolCatalogItem> create(Ref ref) {
    return connectorToolCatalog(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ConnectorToolCatalogItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ConnectorToolCatalogItem>>(
        value,
      ),
    );
  }
}

String _$connectorToolCatalogHash() =>
    r'2acd972171b8349486dce09c96fb91536966fd8d';
