// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intro_session_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps an active setup task on Intro after its first workspace is saved.

@ProviderFor(IntroSessionNotifier)
final introSessionProvider = IntroSessionNotifierProvider._();

/// Keeps an active setup task on Intro after its first workspace is saved.
final class IntroSessionNotifierProvider
    extends $NotifierProvider<IntroSessionNotifier, bool> {
  /// Keeps an active setup task on Intro after its first workspace is saved.
  IntroSessionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'introSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$introSessionNotifierHash();

  @$internal
  @override
  IntroSessionNotifier create() => IntroSessionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$introSessionNotifierHash() =>
    r'ca8d7bb63b23c5617f8d4e7c1c4254b97b758e46';

/// Keeps an active setup task on Intro after its first workspace is saved.

abstract class _$IntroSessionNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
