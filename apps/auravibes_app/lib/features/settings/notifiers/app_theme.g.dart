// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_theme.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ThemeNotifier)
final themeProvider = ThemeNotifierProvider._();

final class ThemeNotifierProvider
    extends $AsyncNotifierProvider<ThemeNotifier, AppTheme> {
  ThemeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeNotifierHash();

  @$internal
  @override
  ThemeNotifier create() => ThemeNotifier();
}

String _$themeNotifierHash() => r'20f0bd500b99424b598791bc015c501a5cf6200b';

abstract class _$ThemeNotifier extends $AsyncNotifier<AppTheme> {
  FutureOr<AppTheme> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppTheme>, AppTheme>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppTheme>, AppTheme>,
              AsyncValue<AppTheme>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
