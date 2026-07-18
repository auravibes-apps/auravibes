// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_connections_action_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(serviceConnectionsActionUsecase)
final serviceConnectionsActionUsecaseProvider =
    ServiceConnectionsActionUsecaseFamily._();

final class ServiceConnectionsActionUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<ServiceConnectionsActionUsecase>,
          ServiceConnectionsActionUsecase,
          FutureOr<ServiceConnectionsActionUsecase>
        >
    with
        $FutureModifier<ServiceConnectionsActionUsecase>,
        $FutureProvider<ServiceConnectionsActionUsecase> {
  ServiceConnectionsActionUsecaseProvider._({
    required ServiceConnectionsActionUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'serviceConnectionsActionUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$serviceConnectionsActionUsecaseHash();

  @override
  String toString() {
    return r'serviceConnectionsActionUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ServiceConnectionsActionUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ServiceConnectionsActionUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return serviceConnectionsActionUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ServiceConnectionsActionUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$serviceConnectionsActionUsecaseHash() =>
    r'43454291342011901c3704ee20b0ed4c874579b0';

final class ServiceConnectionsActionUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ServiceConnectionsActionUsecase>,
          String
        > {
  ServiceConnectionsActionUsecaseFamily._()
    : super(
        retry: null,
        name: r'serviceConnectionsActionUsecaseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ServiceConnectionsActionUsecaseProvider call(String workspaceId) =>
      ServiceConnectionsActionUsecaseProvider._(
        argument: workspaceId,
        from: this,
      );

  @override
  String toString() => r'serviceConnectionsActionUsecaseProvider';
}
