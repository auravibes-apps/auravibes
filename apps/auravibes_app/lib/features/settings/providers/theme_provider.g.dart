// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ThemeController)
const themeControllerProvider = ThemeControllerProvider._();

final class ThemeControllerProvider
    extends $AsyncNotifierProvider<ThemeController, AppTheme> {
  const ThemeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeControllerHash();

  @$internal
  @override
  ThemeController create() => ThemeController();
}

String _$themeControllerHash() => r'135a60399dce7f90984d6c8ab10d4111f013eff0';

abstract class _$ThemeController extends $AsyncNotifier<AppTheme> {
  FutureOr<AppTheme> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<AppTheme>, AppTheme>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppTheme>, AppTheme>,
              AsyncValue<AppTheme>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
