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
    r'0f0c55ffe7710a4542e8f32b45f5791fb0307eb7';

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
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ServiceConnectionOperationsProvider call(String workspaceId) =>
      ServiceConnectionOperationsProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'serviceConnectionOperationsProvider';
}
