// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connector_catalog_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(connectorCatalog)
final connectorCatalogProvider = ConnectorCatalogFamily._();

final class ConnectorCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ConnectorCatalogItem>>,
          List<ConnectorCatalogItem>,
          Stream<List<ConnectorCatalogItem>>
        >
    with
        $FutureModifier<List<ConnectorCatalogItem>>,
        $StreamProvider<List<ConnectorCatalogItem>> {
  ConnectorCatalogProvider._({
    required ConnectorCatalogFamily super.from,
    required (String, {ConnectorCapabilityFilter filter}) super.argument,
  }) : super(
         retry: null,
         name: r'connectorCatalogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$connectorCatalogHash();

  @override
  String toString() {
    return r'connectorCatalogProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<ConnectorCatalogItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ConnectorCatalogItem>> create(Ref ref) {
    final argument =
        this.argument as (String, {ConnectorCapabilityFilter filter});
    return connectorCatalog(ref, argument.$1, filter: argument.filter);
  }

  @override
  bool operator ==(Object other) {
    return other is ConnectorCatalogProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$connectorCatalogHash() => r'830e94d8027f8245cd1deaf5ebd55f4bde01c1e3';

final class ConnectorCatalogFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<ConnectorCatalogItem>>,
          (String, {ConnectorCapabilityFilter filter})
        > {
  ConnectorCatalogFamily._()
    : super(
        retry: null,
        name: r'connectorCatalogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConnectorCatalogProvider call(
    String workspaceId, {
    ConnectorCapabilityFilter filter = ConnectorCapabilityFilter.all,
  }) => ConnectorCatalogProvider._(
    argument: (workspaceId, filter: filter),
    from: this,
  );

  @override
  String toString() => r'connectorCatalogProvider';
}
