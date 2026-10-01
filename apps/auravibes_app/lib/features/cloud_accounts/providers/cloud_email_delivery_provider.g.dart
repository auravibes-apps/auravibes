// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_email_delivery_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Explicit server capability. Production transport has not been configured.

@ProviderFor(cloudEmailDelivery)
final cloudEmailDeliveryProvider = CloudEmailDeliveryProvider._();

/// Explicit server capability. Production transport has not been configured.

final class CloudEmailDeliveryProvider
    extends
        $FunctionalProvider<
          CloudEmailDelivery,
          CloudEmailDelivery,
          CloudEmailDelivery
        >
    with $Provider<CloudEmailDelivery> {
  /// Explicit server capability. Production transport has not been configured.
  CloudEmailDeliveryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudEmailDeliveryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudEmailDeliveryHash();

  @$internal
  @override
  $ProviderElement<CloudEmailDelivery> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CloudEmailDelivery create(Ref ref) {
    return cloudEmailDelivery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CloudEmailDelivery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CloudEmailDelivery>(value),
    );
  }
}

String _$cloudEmailDeliveryHash() =>
    r'96691b1dc7aa33a73d4b772862039fe545dcf4eb';
