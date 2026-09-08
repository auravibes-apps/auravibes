// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_service_connection_usecases_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cloudServiceConnectionUsecases)
final cloudServiceConnectionUsecasesProvider =
    CloudServiceConnectionUsecasesFamily._();

final class CloudServiceConnectionUsecasesProvider
    extends
        $FunctionalProvider<
          AsyncValue<CloudServiceConnectionUsecases?>,
          CloudServiceConnectionUsecases?,
          FutureOr<CloudServiceConnectionUsecases?>
        >
    with
        $FutureModifier<CloudServiceConnectionUsecases?>,
        $FutureProvider<CloudServiceConnectionUsecases?> {
  CloudServiceConnectionUsecasesProvider._({
    required CloudServiceConnectionUsecasesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cloudServiceConnectionUsecasesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cloudServiceConnectionUsecasesHash();

  @override
  String toString() {
    return r'cloudServiceConnectionUsecasesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CloudServiceConnectionUsecases?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CloudServiceConnectionUsecases?> create(Ref ref) {
    final argument = this.argument as String;
    return cloudServiceConnectionUsecases(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CloudServiceConnectionUsecasesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cloudServiceConnectionUsecasesHash() =>
    r'bb83dd326b5e5f520a6ff8ed233e460d8cca1974';

final class CloudServiceConnectionUsecasesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CloudServiceConnectionUsecases?>,
          String
        > {
  CloudServiceConnectionUsecasesFamily._()
    : super(
        retry: null,
        name: r'cloudServiceConnectionUsecasesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CloudServiceConnectionUsecasesProvider call(String workspaceId) =>
      CloudServiceConnectionUsecasesProvider._(
        argument: workspaceId,
        from: this,
      );

  @override
  String toString() => r'cloudServiceConnectionUsecasesProvider';
}
