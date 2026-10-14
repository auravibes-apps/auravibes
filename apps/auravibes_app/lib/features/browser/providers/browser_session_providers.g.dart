// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browser_session_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(browserSessionRepository)
final browserSessionRepositoryProvider = BrowserSessionRepositoryProvider._();

final class BrowserSessionRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<BrowserSessionRepository>,
          BrowserSessionRepository,
          FutureOr<BrowserSessionRepository>
        >
    with
        $FutureModifier<BrowserSessionRepository>,
        $FutureProvider<BrowserSessionRepository> {
  BrowserSessionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browserSessionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browserSessionRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<BrowserSessionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BrowserSessionRepository> create(Ref ref) {
    return browserSessionRepository(ref);
  }
}

String _$browserSessionRepositoryHash() =>
    r'55cee74c0d51763e0564cc384f930245e51909ff';

@ProviderFor(browserWebViewService)
final browserWebViewServiceProvider = BrowserWebViewServiceProvider._();

final class BrowserWebViewServiceProvider
    extends
        $FunctionalProvider<
          BrowserWebViewService,
          BrowserWebViewService,
          BrowserWebViewService
        >
    with $Provider<BrowserWebViewService> {
  BrowserWebViewServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browserWebViewServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browserWebViewServiceHash();

  @$internal
  @override
  $ProviderElement<BrowserWebViewService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BrowserWebViewService create(Ref ref) {
    return browserWebViewService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BrowserWebViewService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BrowserWebViewService>(value),
    );
  }
}

String _$browserWebViewServiceHash() =>
    r'840346b903b41f53d8da81631abecc7aa59ace75';
