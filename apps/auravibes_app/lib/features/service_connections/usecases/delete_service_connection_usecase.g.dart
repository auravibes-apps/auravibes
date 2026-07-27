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
    r'5f646d042974bd2b373babace423f1b590ea2978';

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
        dependencies: null,
        $allTransitiveDependencies: null,
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
