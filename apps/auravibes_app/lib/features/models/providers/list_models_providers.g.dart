// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_models_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(listCredentials)
final listCredentialsProvider = ListCredentialsProvider._();

final class ListCredentialsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CredentialsEntity>>,
          List<CredentialsEntity>,
          FutureOr<List<CredentialsEntity>>
        >
    with
        $FutureModifier<List<CredentialsEntity>>,
        $FutureProvider<List<CredentialsEntity>> {
  ListCredentialsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listCredentialsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listCredentialsHash();

  @$internal
  @override
  $FutureProviderElement<List<CredentialsEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CredentialsEntity>> create(Ref ref) {
    return listCredentials(ref);
  }
}

String _$listCredentialsHash() => r'b91cb2733d01a054c507871f987fc9219896c013';
