import 'package:auravibes_app/features/settings/notifiers/accent_hue.dart';
import 'package:auravibes_app/features/settings/notifiers/app_theme.dart';
import 'package:auravibes_app/flavor.dart';
import 'package:auravibes_app/main.dart' as app;
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('Aura theme transition reaches dark target without restarting', (
    tester,
  ) async {
    AppFlavorConfig.instance.setAppFlavor(.dev);
    AuraTheme? observedTheme;
    final themeNotifier = _TestThemeNotifier();
    final container = ProviderContainer(
      overrides: [
        themeProvider.overrideWith(() => themeNotifier),
        routerProvider.overrideWith(
          (ref) => GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => AuraSdkMaterialSurface(
                  child: Builder(
                    builder: (context) {
                      observedTheme = context.auraTheme;

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

    await tester.pumpWidget(
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
    );
    final _ = await tester.pumpAndSettle();

    expect(observedTheme?.colors.onSurface, AuraTheme.light.colors.onSurface);

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
    expect(find.byType(AuraSdkMaterialSurface), findsWidgets);
  });
}

class _TestThemeNotifier extends ThemeNotifier {
  @override
  Future<AppTheme> build() async => AppTheme.light;

  void setValue(AppTheme theme) => state = .data(theme);
}
