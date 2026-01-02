// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_chat_models_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(listCredentialsCredentials)
final listCredentialsCredentialsProvider =
    ListCredentialsCredentialsProvider._();

final class ListCredentialsCredentialsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CredentialsModelWithProviderEntity>>,
          List<CredentialsModelWithProviderEntity>,
          FutureOr<List<CredentialsModelWithProviderEntity>>
        >
    with
        $FutureModifier<List<CredentialsModelWithProviderEntity>>,
        $FutureProvider<List<CredentialsModelWithProviderEntity>> {
  ListCredentialsCredentialsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listCredentialsCredentialsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listCredentialsCredentialsHash();

  @$internal
  @override
  $FutureProviderElement<List<CredentialsModelWithProviderEntity>>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CredentialsModelWithProviderEntity>> create(Ref ref) {
    return listCredentialsCredentials(ref);
  }
}

String _$listCredentialsCredentialsHash() =>
    r'225f85566f451f494f08d15035a6f70c2c445aa5';
