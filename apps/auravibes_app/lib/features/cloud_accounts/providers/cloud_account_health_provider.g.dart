// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_account_health_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checkCloudAccountUsecase)
final checkCloudAccountUsecaseProvider = CheckCloudAccountUsecaseProvider._();

final class CheckCloudAccountUsecaseProvider
    extends
        $FunctionalProvider<
          CheckCloudAccountUsecase,
          CheckCloudAccountUsecase,
          CheckCloudAccountUsecase
        >
    with $Provider<CheckCloudAccountUsecase> {
  CheckCloudAccountUsecaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkCloudAccountUsecaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkCloudAccountUsecaseHash();

  @$internal
  @override
  $ProviderElement<CheckCloudAccountUsecase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CheckCloudAccountUsecase create(Ref ref) {
    return checkCloudAccountUsecase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckCloudAccountUsecase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckCloudAccountUsecase>(value),
    );
  }
}

String _$checkCloudAccountUsecaseHash() =>
    r'f83c2c0ba75842d61b2bccc49138c6e8f9ae3a89';

@ProviderFor(cloudAccountHealth)
final cloudAccountHealthProvider = CloudAccountHealthFamily._();

final class CloudAccountHealthProvider
    extends
        $FunctionalProvider<
          AsyncValue<CloudAccountHealth>,
          CloudAccountHealth,
          FutureOr<CloudAccountHealth>
        >
    with
        $FutureModifier<CloudAccountHealth>,
        $FutureProvider<CloudAccountHealth> {
  CloudAccountHealthProvider._({
    required CloudAccountHealthFamily super.from,
    required CloudAccountKey super.argument,
  }) : super(
         retry: null,
         name: r'cloudAccountHealthProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cloudAccountHealthHash();

  @override
  String toString() {
    return r'cloudAccountHealthProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CloudAccountHealth> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CloudAccountHealth> create(Ref ref) {
    final argument = this.argument as CloudAccountKey;
    return cloudAccountHealth(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CloudAccountHealthProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cloudAccountHealthHash() =>
    r'44d5f81865cf55150f3330d374108d19b622499e';

final class CloudAccountHealthFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CloudAccountHealth>,
          CloudAccountKey
        > {
  CloudAccountHealthFamily._()
    : super(
        retry: null,
        name: r'cloudAccountHealthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  CloudAccountHealthProvider call(CloudAccountKey key) =>
      CloudAccountHealthProvider._(argument: key, from: this);

  @override
  String toString() => r'cloudAccountHealthProvider';
}
