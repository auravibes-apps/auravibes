// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accent_hue.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persists the user's accent hue (OKLCH hue degrees, 0–360).
///
/// Drives AuraComputedColorScheme so the whole palette recomputes from one
/// value. Kept separate from ThemeNotifier so theme-mode state is untouched.

@ProviderFor(AccentHueNotifier)
final accentHueProvider = AccentHueNotifierProvider._();

/// Persists the user's accent hue (OKLCH hue degrees, 0–360).
///
/// Drives AuraComputedColorScheme so the whole palette recomputes from one
/// value. Kept separate from ThemeNotifier so theme-mode state is untouched.
final class AccentHueNotifierProvider
    extends $AsyncNotifierProvider<AccentHueNotifier, double> {
  /// Persists the user's accent hue (OKLCH hue degrees, 0–360).
  ///
  /// Drives AuraComputedColorScheme so the whole palette recomputes from one
  /// value. Kept separate from ThemeNotifier so theme-mode state is untouched.
  AccentHueNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accentHueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accentHueNotifierHash();

  @$internal
  @override
  AccentHueNotifier create() => AccentHueNotifier();
}

String _$accentHueNotifierHash() => r'dd80f7728ecc72c0a1016661fde186923047f341';

/// Persists the user's accent hue (OKLCH hue degrees, 0–360).
///
/// Drives AuraComputedColorScheme so the whole palette recomputes from one
/// value. Kept separate from ThemeNotifier so theme-mode state is untouched.

abstract class _$AccentHueNotifier extends $AsyncNotifier<double> {
  FutureOr<double> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<double>, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<double>, double>,
              AsyncValue<double>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
