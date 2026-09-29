import 'package:auravibes_app/features/settings/notifiers/accent_hue.dart';
import 'package:auravibes_app/features/settings/notifiers/app_theme.dart';
import 'package:auravibes_app/flavor.dart';
import 'package:auravibes_app/main.dart' as app;
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Aura theme transition reaches dark target without restarting', (
    tester,
  ) async {
    AppFlavorConfig.instance.setAppFlavor(.dev);
    AuraTheme? observedTheme;
    TextSelectionThemeData? observedSelectionTheme;
    PageTransitionsTheme? observedPageTransitionsTheme;
    final themeNotifier = _TestThemeNotifier();
    final container = ProviderContainer(
      overrides: [
        themeProvider.overrideWith(() => themeNotifier),
        accentHueProvider.overrideWith(_TestAccentHueNotifier.new),
        routerProvider.overrideWith(
          (ref) => GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => AuraSdkMaterialSurface(
                  child: Builder(
                    builder: (context) {
                      observedTheme = context.auraTheme;
                      observedSelectionTheme = Theme.of(context)
                          .textSelectionTheme;
                      observedPageTransitionsTheme = Theme.of(context)
                          .pageTransitionsTheme;

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: EasyLocalization(
            child: const app.MyApp(),
            supportedLocales: const [Locale('en')],
            path: 'assets/i18n',
            fallbackLocale: const Locale('en'),
            startLocale: const Locale('en'),
            useOnlyLangCode: true,
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(observedTheme?.colors.onSurface, AuraTheme.light.colors.onSurface);
    final lightPrimary = observedTheme?.colors.primary;
    expect(observedSelectionTheme?.cursorColor, lightPrimary);
    expect(observedSelectionTheme?.selectionHandleColor, lightPrimary);
    expect(
      observedSelectionTheme?.selectionColor,
      lightPrimary?.withValues(alpha: 0.24),
    );
    final pageBuilders = observedPageTransitionsTheme?.builders;
    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.fuchsia,
    ]) {
      expect(pageBuilders?[platform]?.transitionDuration, Duration.zero);
      expect(pageBuilders?[platform]?.reverseTransitionDuration, Duration.zero);
    }
    if (kIsWeb) {
      expect(
        pageBuilders?[TargetPlatform.android]?.transitionDuration,
        Duration.zero,
      );
      expect(
        pageBuilders?[TargetPlatform.iOS]?.transitionDuration,
        Duration.zero,
      );
    } else {
      final defaultBuilders = const PageTransitionsTheme().builders;
      expect(
        pageBuilders?[TargetPlatform.android]?.runtimeType,
        defaultBuilders[TargetPlatform.android]?.runtimeType,
      );
      expect(
        pageBuilders?[TargetPlatform.iOS]?.runtimeType,
        defaultBuilders[TargetPlatform.iOS]?.runtimeType,
      );
    }

    themeNotifier.setValue(.dark);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      observedTheme?.colors.onSurface,
      AuraComputedColorScheme(
        primaryHue: AccentHue.defaultValue,
        brightness: .dark,
      ).onSurface,
    );
    final darkPrimary = observedTheme?.colors.primary;
    expect(observedSelectionTheme?.cursorColor, darkPrimary);
    expect(observedSelectionTheme?.selectionHandleColor, darkPrimary);
    expect(
      observedSelectionTheme?.selectionColor,
      darkPrimary?.withValues(alpha: 0.24),
    );
    expect(find.byType(AuraSdkMaterialSurface), findsWidgets);
  });

  testWidgets('app scroll behavior adds one scrollbar per scrollable', (
    tester,
  ) async {
    AppFlavorConfig.instance.setAppFlavor(.dev);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => AuraSdkMaterialSurface(
            child: Column(
              children: [
                SizedBox(
                  height: 100,
                  child: ListView(children: const [SizedBox(height: 300)]),
                ),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: .horizontal,
                    children: const [SizedBox(width: 1200)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        themeProvider.overrideWith(_TestThemeNotifier.new),
        accentHueProvider.overrideWith(_TestAccentHueNotifier.new),
        routerProvider.overrideWith((ref) => router),
      ],
    );
    addTearDown(container.dispose);

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: EasyLocalization(
            child: const app.MyApp(),
            supportedLocales: const [Locale('en')],
            path: 'assets/i18n',
            fallbackLocale: const Locale('en'),
            startLocale: const Locale('en'),
            useOnlyLangCode: true,
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(Scrollbar), findsNWidgets(2));
  });
}

class _TestThemeNotifier extends ThemeNotifier {
  @override
  Future<AppTheme> build() async => AppTheme.light;

  void setValue(AppTheme theme) => state = .data(theme);
}

class _TestAccentHueNotifier extends AccentHueNotifier {
  @override
  Future<double> build() async => AccentHue.defaultValue;
}
