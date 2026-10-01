// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_exit_registry_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(draftExitRegistry)
final draftExitRegistryProvider = DraftExitRegistryProvider._();

final class DraftExitRegistryProvider
    extends
        $FunctionalProvider<
          DraftExitRegistry,
          DraftExitRegistry,
          DraftExitRegistry
        >
    with $Provider<DraftExitRegistry> {
  DraftExitRegistryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'draftExitRegistryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$draftExitRegistryHash();

  @$internal
  @override
  $ProviderElement<DraftExitRegistry> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DraftExitRegistry create(Ref ref) {
    return draftExitRegistry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DraftExitRegistry value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DraftExitRegistry>(value),
    );
  }
}

String _$draftExitRegistryHash() => r'dea3e5859e3a40ff782f8bb7896ad5c35376855f';
