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
    ThemeData? observedMaterialTheme;
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
                  child: Column(
                    children: [
                      Builder(
                        builder: (context) {
                          observedTheme = context.auraTheme;
                          final materialTheme = Theme.of(context);
                          observedMaterialTheme = materialTheme;
                          observedSelectionTheme =
                              materialTheme.textSelectionTheme;
                          observedPageTransitionsTheme =
                              materialTheme.pageTransitionsTheme;

                          return const SizedBox.shrink();
                        },
                      ),
                      SizedBox(
                        height: 100,
                        child: ListView(
                          children: const [SizedBox(height: 300)],
                        ),
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
    final materialTheme =
        observedMaterialTheme ??
        fail('Expected the route to build with a Material theme.');
    final focusColor = materialTheme.colorScheme.surfaceContainerHighest;
    final defaultSplashFactory = ThemeData().splashFactory;
    expect(materialTheme.splashFactory, isNot(same(defaultSplashFactory)));
    expect(
      materialTheme.textButtonTheme.style?.splashFactory,
      isNot(same(defaultSplashFactory)),
    );
    expect(
      materialTheme.iconButtonTheme.style?.splashFactory,
      isNot(same(defaultSplashFactory)),
    );
    expect(materialTheme.splashColor, Colors.transparent);
    expect(materialTheme.highlightColor, Colors.transparent);
    expect(materialTheme.hoverColor, Colors.transparent);
    expect(materialTheme.focusColor, focusColor);
    expect(
      materialTheme.floatingActionButtonTheme.splashColor,
      Colors.transparent,
    );
    final textButtonOverlay = materialTheme.textButtonTheme.style?.overlayColor;
    expect(textButtonOverlay?.resolve({WidgetState.focused}), focusColor);
    expect(
      textButtonOverlay?.resolve({WidgetState.hovered}),
      Colors.transparent,
    );
    expect(
      textButtonOverlay?.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
    final iconButtonOverlay = materialTheme.iconButtonTheme.style?.overlayColor;
    expect(iconButtonOverlay?.resolve({WidgetState.focused}), focusColor);
    expect(
      iconButtonOverlay?.resolve({WidgetState.hovered}),
      Colors.transparent,
    );
    expect(
      iconButtonOverlay?.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
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
