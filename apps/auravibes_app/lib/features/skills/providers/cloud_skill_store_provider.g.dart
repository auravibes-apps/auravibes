// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_skill_store_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cloudSkillStore)
final cloudSkillStoreProvider = CloudSkillStoreFamily._();

final class CloudSkillStoreProvider
    extends
        $FunctionalProvider<
          CloudSkillStore?,
          CloudSkillStore?,
          CloudSkillStore?
        >
    with $Provider<CloudSkillStore?> {
  CloudSkillStoreProvider._({
    required CloudSkillStoreFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cloudSkillStoreProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cloudSkillStoreHash();

  @override
  String toString() {
    return r'cloudSkillStoreProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<CloudSkillStore?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CloudSkillStore? create(Ref ref) {
    final argument = this.argument as String;
    return cloudSkillStore(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CloudSkillStore? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CloudSkillStore?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CloudSkillStoreProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cloudSkillStoreHash() => r'0910731dd06891d532bd5a172533e495f87a7e27';

final class CloudSkillStoreFamily extends $Family
    with $FunctionalFamilyOverride<CloudSkillStore?, String> {
  CloudSkillStoreFamily._()
    : super(
        retry: null,
        name: r'cloudSkillStoreProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CloudSkillStoreProvider call(String workspaceId) =>
      CloudSkillStoreProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'cloudSkillStoreProvider';
}
