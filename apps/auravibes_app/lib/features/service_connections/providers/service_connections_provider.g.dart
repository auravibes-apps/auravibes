// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_connections_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(serviceConnections)
final serviceConnectionsProvider = ServiceConnectionsFamily._();

final class ServiceConnectionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ServiceConnectionListItem>>,
          List<ServiceConnectionListItem>,
          Stream<List<ServiceConnectionListItem>>
        >
    with
        $FutureModifier<List<ServiceConnectionListItem>>,
        $StreamProvider<List<ServiceConnectionListItem>> {
  ServiceConnectionsProvider._({
    required ServiceConnectionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'serviceConnectionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = cloudWorkspaceStateGatewayProvider;
  static final $allTransitiveDependencies1 =
      CloudWorkspaceStateGatewayProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$serviceConnectionsHash();

  @override
  String toString() {
    return r'serviceConnectionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ServiceConnectionListItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ServiceConnectionListItem>> create(Ref ref) {
    final argument = this.argument as String;
    return serviceConnections(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ServiceConnectionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$serviceConnectionsHash() =>
    r'5ddff40982e9bee1332f7e25590666d648c9ef8e';

final class ServiceConnectionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<ServiceConnectionListItem>>,
          String
        > {
  ServiceConnectionsFamily._()
    : super(
        retry: null,
        name: r'serviceConnectionsProvider',
        dependencies: <ProviderOrFamily>[cloudWorkspaceStateGatewayProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ServiceConnectionsProvider.$allTransitiveDependencies0,
          ServiceConnectionsProvider.$allTransitiveDependencies1,
        ],
        isAutoDispose: true,
      );

  ServiceConnectionsProvider call(String workspaceId) =>
      ServiceConnectionsProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'serviceConnectionsProvider';
}
