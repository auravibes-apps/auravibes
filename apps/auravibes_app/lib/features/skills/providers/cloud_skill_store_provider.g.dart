// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_skill_store_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cloudSkillStore)
final cloudSkillStoreProvider = CloudSkillStoreProvider._();

final class CloudSkillStoreProvider
    extends
        $FunctionalProvider<
          CloudSkillStore?,
          CloudSkillStore?,
          CloudSkillStore?
        >
    with $Provider<CloudSkillStore?> {
  CloudSkillStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudSkillStoreProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          workspaceSessionProvider,
          cloudWorkspaceStateGatewayProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          CloudSkillStoreProvider.$allTransitiveDependencies0,
          CloudSkillStoreProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = workspaceSessionProvider;
  static final $allTransitiveDependencies1 = cloudWorkspaceStateGatewayProvider;

  @override
  String debugGetCreateSourceHash() => _$cloudSkillStoreHash();

  @$internal
  @override
  $ProviderElement<CloudSkillStore?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CloudSkillStore? create(Ref ref) {
    return cloudSkillStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CloudSkillStore? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CloudSkillStore?>(value),
    );
  }
}

String _$cloudSkillStoreHash() => r'2c99c7693e43d688f5355f06bd5e50555edb9eb9';
