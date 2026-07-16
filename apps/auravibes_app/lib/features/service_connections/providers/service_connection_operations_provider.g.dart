// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_connection_operations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(serviceConnectionOperations)
final serviceConnectionOperationsProvider =
    ServiceConnectionOperationsFamily._();

final class ServiceConnectionOperationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ServiceConnectionOperations>,
          ServiceConnectionOperations,
          FutureOr<ServiceConnectionOperations>
        >
    with
        $FutureModifier<ServiceConnectionOperations>,
        $FutureProvider<ServiceConnectionOperations> {
  ServiceConnectionOperationsProvider._({
    required ServiceConnectionOperationsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'serviceConnectionOperationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = cloudWorkspaceStateGatewayProvider;
  static final $allTransitiveDependencies1 =
      CloudWorkspaceStateGatewayProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$serviceConnectionOperationsHash();

  @override
  String toString() {
    return r'serviceConnectionOperationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ServiceConnectionOperations> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ServiceConnectionOperations> create(Ref ref) {
    final argument = this.argument as String;
    return serviceConnectionOperations(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ServiceConnectionOperationsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$serviceConnectionOperationsHash() =>
    r'e9f7dfc7b6587cb5f7c26966206d3a5de290eadf';

final class ServiceConnectionOperationsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ServiceConnectionOperations>,
          String
        > {
  ServiceConnectionOperationsFamily._()
    : super(
        retry: null,
        name: r'serviceConnectionOperationsProvider',
        dependencies: <ProviderOrFamily>[cloudWorkspaceStateGatewayProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ServiceConnectionOperationsProvider.$allTransitiveDependencies0,
          ServiceConnectionOperationsProvider.$allTransitiveDependencies1,
        ],
        isAutoDispose: true,
      );

  ServiceConnectionOperationsProvider call(String workspaceId) =>
      ServiceConnectionOperationsProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'serviceConnectionOperationsProvider';
}
