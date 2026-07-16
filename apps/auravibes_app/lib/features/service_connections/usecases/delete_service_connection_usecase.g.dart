// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_service_connection_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deleteServiceConnectionUsecase)
final deleteServiceConnectionUsecaseProvider =
    DeleteServiceConnectionUsecaseFamily._();

final class DeleteServiceConnectionUsecaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<DeleteServiceConnectionUsecase>,
          DeleteServiceConnectionUsecase,
          FutureOr<DeleteServiceConnectionUsecase>
        >
    with
        $FutureModifier<DeleteServiceConnectionUsecase>,
        $FutureProvider<DeleteServiceConnectionUsecase> {
  DeleteServiceConnectionUsecaseProvider._({
    required DeleteServiceConnectionUsecaseFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'deleteServiceConnectionUsecaseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = cloudWorkspaceStateGatewayProvider;
  static final $allTransitiveDependencies1 =
      CloudWorkspaceStateGatewayProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$deleteServiceConnectionUsecaseHash();

  @override
  String toString() {
    return r'deleteServiceConnectionUsecaseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DeleteServiceConnectionUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DeleteServiceConnectionUsecase> create(Ref ref) {
    final argument = this.argument as String;
    return deleteServiceConnectionUsecase(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteServiceConnectionUsecaseProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deleteServiceConnectionUsecaseHash() =>
    r'192d8e8742e20b221920f808024befedb2e0f3fe';

final class DeleteServiceConnectionUsecaseFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<DeleteServiceConnectionUsecase>,
          String
        > {
  DeleteServiceConnectionUsecaseFamily._()
    : super(
        retry: null,
        name: r'deleteServiceConnectionUsecaseProvider',
        dependencies: <ProviderOrFamily>[cloudWorkspaceStateGatewayProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          DeleteServiceConnectionUsecaseProvider.$allTransitiveDependencies0,
          DeleteServiceConnectionUsecaseProvider.$allTransitiveDependencies1,
        ],
        isAutoDispose: true,
      );

  DeleteServiceConnectionUsecaseProvider call(String workspaceId) =>
      DeleteServiceConnectionUsecaseProvider._(
        argument: workspaceId,
        from: this,
      );

  @override
  String toString() => r'deleteServiceConnectionUsecaseProvider';
}
