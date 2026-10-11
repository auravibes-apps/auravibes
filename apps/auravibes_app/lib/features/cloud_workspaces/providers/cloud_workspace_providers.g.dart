// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_workspace_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cloudWorkspaceUseCases)
final cloudWorkspaceUseCasesProvider = CloudWorkspaceUseCasesFamily._();

final class CloudWorkspaceUseCasesProvider
    extends
        $FunctionalProvider<
          AsyncValue<CloudWorkspaceUseCases?>,
          CloudWorkspaceUseCases?,
          FutureOr<CloudWorkspaceUseCases?>
        >
    with
        $FutureModifier<CloudWorkspaceUseCases?>,
        $FutureProvider<CloudWorkspaceUseCases?> {
  CloudWorkspaceUseCasesProvider._({
    required CloudWorkspaceUseCasesFamily super.from,
    required CloudAccountKey super.argument,
  }) : super(
         retry: null,
         name: r'cloudWorkspaceUseCasesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cloudWorkspaceUseCasesHash();

  @override
  String toString() {
    return r'cloudWorkspaceUseCasesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CloudWorkspaceUseCases?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CloudWorkspaceUseCases?> create(Ref ref) {
    final argument = this.argument as CloudAccountKey;
    return cloudWorkspaceUseCases(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CloudWorkspaceUseCasesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cloudWorkspaceUseCasesHash() =>
    r'9e40f5d84c019a07e5dbf59ca700df7f77531ff6';

final class CloudWorkspaceUseCasesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CloudWorkspaceUseCases?>,
          CloudAccountKey
        > {
  CloudWorkspaceUseCasesFamily._()
    : super(
        retry: null,
        name: r'cloudWorkspaceUseCasesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CloudWorkspaceUseCasesProvider call(CloudAccountKey key) =>
      CloudWorkspaceUseCasesProvider._(argument: key, from: this);

  @override
  String toString() => r'cloudWorkspaceUseCasesProvider';
}

@ProviderFor(cloudWorkspaceState)
final cloudWorkspaceStateProvider = CloudWorkspaceStateFamily._();

final class CloudWorkspaceStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<CloudWorkspaceViewState?>,
          CloudWorkspaceViewState?,
          FutureOr<CloudWorkspaceViewState?>
        >
    with
        $FutureModifier<CloudWorkspaceViewState?>,
        $FutureProvider<CloudWorkspaceViewState?> {
  CloudWorkspaceStateProvider._({
    required CloudWorkspaceStateFamily super.from,
    required CloudAccountKey super.argument,
  }) : super(
         retry: null,
         name: r'cloudWorkspaceStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cloudWorkspaceStateHash();

  @override
  String toString() {
    return r'cloudWorkspaceStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CloudWorkspaceViewState?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CloudWorkspaceViewState?> create(Ref ref) {
    final argument = this.argument as CloudAccountKey;
    return cloudWorkspaceState(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CloudWorkspaceStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cloudWorkspaceStateHash() =>
    r'eda7e33e93fbf016a94d23708a8092363d4d88bf';

final class CloudWorkspaceStateFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CloudWorkspaceViewState?>,
          CloudAccountKey
        > {
  CloudWorkspaceStateFamily._()
    : super(
        retry: null,
        name: r'cloudWorkspaceStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CloudWorkspaceStateProvider call(CloudAccountKey key) =>
      CloudWorkspaceStateProvider._(argument: key, from: this);

  @override
  String toString() => r'cloudWorkspaceStateProvider';
}

@ProviderFor(cloudWorkspaceDetail)
final cloudWorkspaceDetailProvider = CloudWorkspaceDetailFamily._();

final class CloudWorkspaceDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<CloudWorkspaceDetailState?>,
          CloudWorkspaceDetailState?,
          FutureOr<CloudWorkspaceDetailState?>
        >
    with
        $FutureModifier<CloudWorkspaceDetailState?>,
        $FutureProvider<CloudWorkspaceDetailState?> {
  CloudWorkspaceDetailProvider._({
    required CloudWorkspaceDetailFamily super.from,
    required CloudWorkspaceDetailKey super.argument,
  }) : super(
         retry: null,
         name: r'cloudWorkspaceDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cloudWorkspaceDetailHash();

  @override
  String toString() {
    return r'cloudWorkspaceDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CloudWorkspaceDetailState?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CloudWorkspaceDetailState?> create(Ref ref) {
    final argument = this.argument as CloudWorkspaceDetailKey;
    return cloudWorkspaceDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CloudWorkspaceDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cloudWorkspaceDetailHash() =>
    r'abb26320bd143e636c9f74c62c24e5bdef966b4b';

final class CloudWorkspaceDetailFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CloudWorkspaceDetailState?>,
          CloudWorkspaceDetailKey
        > {
  CloudWorkspaceDetailFamily._()
    : super(
        retry: null,
        name: r'cloudWorkspaceDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CloudWorkspaceDetailProvider call(CloudWorkspaceDetailKey key) =>
      CloudWorkspaceDetailProvider._(argument: key, from: this);

  @override
  String toString() => r'cloudWorkspaceDetailProvider';
}

/// Old links may omit origin; resolving an ambiguous identity fails closed.

@ProviderFor(cloudWorkspaceRouteAccount)
final cloudWorkspaceRouteAccountProvider = CloudWorkspaceRouteAccountFamily._();

/// Old links may omit origin; resolving an ambiguous identity fails closed.

final class CloudWorkspaceRouteAccountProvider
    extends
        $FunctionalProvider<
          AsyncValue<CloudAccountKey>,
          CloudAccountKey,
          FutureOr<CloudAccountKey>
        >
    with $FutureModifier<CloudAccountKey>, $FutureProvider<CloudAccountKey> {
  /// Old links may omit origin; resolving an ambiguous identity fails closed.
  CloudWorkspaceRouteAccountProvider._({
    required CloudWorkspaceRouteAccountFamily super.from,
    required CloudWorkspaceRouteKey super.argument,
  }) : super(
         retry: null,
         name: r'cloudWorkspaceRouteAccountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cloudWorkspaceRouteAccountHash();

  @override
  String toString() {
    return r'cloudWorkspaceRouteAccountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CloudAccountKey> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CloudAccountKey> create(Ref ref) {
    final argument = this.argument as CloudWorkspaceRouteKey;
    return cloudWorkspaceRouteAccount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CloudWorkspaceRouteAccountProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cloudWorkspaceRouteAccountHash() =>
    r'6711c51bab44c4ee8439a535c99ba381db02b52a';

/// Old links may omit origin; resolving an ambiguous identity fails closed.

final class CloudWorkspaceRouteAccountFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CloudAccountKey>,
          CloudWorkspaceRouteKey
        > {
  CloudWorkspaceRouteAccountFamily._()
    : super(
        retry: null,
        name: r'cloudWorkspaceRouteAccountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Old links may omit origin; resolving an ambiguous identity fails closed.

  CloudWorkspaceRouteAccountProvider call(CloudWorkspaceRouteKey key) =>
      CloudWorkspaceRouteAccountProvider._(argument: key, from: this);

  @override
  String toString() => r'cloudWorkspaceRouteAccountProvider';
}
