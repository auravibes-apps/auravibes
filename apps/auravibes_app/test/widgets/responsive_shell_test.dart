@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_with_responsive_drawer.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_conversation_repository.dart';
import '../helpers/test_provider_scope.dart';

typedef _ResponsiveShellTestSettings = ({
  Brightness brightness,
  ui.TextDirection textDirection,
  double textScaleFactor,
});

void main() {
  testWidgets('responsive shell adapts across breakpoints and accessibility', (
    tester,
  ) async {
    const initialSettings = (
      brightness: Brightness.light,
      textDirection: ui.TextDirection.ltr,
      textScaleFactor: 1.0,
    );
    final settings = ValueNotifier<_ResponsiveShellTestSettings>(
      initialSettings,
    );
    final repository = FakeConversationRepository();
    final navigationTaps = <int>[];
    final (:app, :router) = _buildResponsiveShellApp(
      settings: settings,
      repository: repository,
      onNavigationTap: navigationTaps.add,
    );
    addTearDown(settings.dispose);
    addTearDown(router.dispose);
    addTearDown(repository.close);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      await tester.pumpWidget(app);
    });
    await tester.pump();
    await tester.pump();

    final content = find.text('Shell content');
    expect(content, findsOneWidget);
    final controller = ResponsiveSlidingDrawerProvider.of(
      tester.element(content),
    );

    for (final scenario in const [
      (width: 390.0, isDesktop: false),
      (width: 768.0, isDesktop: true),
      (width: 1280.0, isDesktop: true),
    ]) {
      tester.view.physicalSize = .new(scenario.width, 900);
      expect(await tester.pumpAndSettle(), greaterThan(0));

      expect(controller.isDesktop, scenario.isDesktop);
      expect(content, findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    const goldenScenarios = [
      (
        name: 'mobile_599_closed_light',
        width: 599.0,
        initiallyOpen: false,
        brightness: Brightness.light,
      ),
      (
        name: 'mobile_599_open_light',
        width: 599.0,
        initiallyOpen: true,
        brightness: Brightness.light,
      ),
      (
        name: 'mobile_599_closed_dark',
        width: 599.0,
        initiallyOpen: false,
        brightness: Brightness.dark,
      ),
      (
        name: 'mobile_599_open_dark',
        width: 599.0,
        initiallyOpen: true,
        brightness: Brightness.dark,
      ),
      (
        name: 'desktop_600_closed_light',
        width: 600.0,
        initiallyOpen: false,
        brightness: Brightness.light,
      ),
      (
        name: 'desktop_600_open_light',
        width: 600.0,
        initiallyOpen: true,
        brightness: Brightness.light,
      ),
      (
        name: 'desktop_600_closed_dark',
        width: 600.0,
        initiallyOpen: false,
        brightness: Brightness.dark,
      ),
      (
        name: 'desktop_600_open_dark',
        width: 600.0,
        initiallyOpen: true,
        brightness: Brightness.dark,
      ),
    ];

    for (final scenario in goldenScenarios) {
      tester.view.physicalSize = .new(scenario.width, 900);
      settings.value = (
        brightness: scenario.brightness,
        textDirection: ui.TextDirection.ltr,
        textScaleFactor: 1,
      );
      if (scenario.initiallyOpen) {
        controller.open();
      } else {
        controller.close();
      }
      expect(await tester.pumpAndSettle(), greaterThan(0));

      expect(controller.isDesktop, scenario.width >= 600);
      expect(content, findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('responsive-shell-golden')),
        matchesGoldenFile('goldens/responsive_shell/${scenario.name}.png'),
      );
    }

    tester.view.physicalSize = const Size(1280, 900);
    settings.value = (
      brightness: Brightness.light,
      textDirection: ui.TextDirection.rtl,
      textScaleFactor: 2,
    );
    await tester.runAsync(() async {
      await tester
          .element(find.byType(MaterialApp))
          .setLocale(const Locale('es'));
    });
    expect(await tester.pumpAndSettle(), greaterThan(0));

    final semantics = tester.ensureSemantics();
    try {
      await tester.pump();
      final sidebar = find.byType(AppWithResponsiveDrawer);
      final label = LocaleKeys.menu_new_chat.tr(
        context: tester.element(sidebar),
      );
      expect(label, 'Nuevo Chat');

      final navigationAction = find.bySemanticsLabel(label);
      expect(navigationAction, findsOneWidget);
      final labelText = find.text(label);
      final icon = find.byIcon(Icons.chat_outlined);
      expect(labelText, findsOneWidget);
      expect(icon, findsOneWidget);
      expect(
        tester.getTopLeft(icon).dx,
        greaterThan(tester.getTopLeft(labelText).dx),
      );
      expect(tester.getSize(navigationAction).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(navigationAction).height, greaterThanOrEqualTo(48));

      final focusRing = find.descendant(
        of: navigationAction,
        matching: find.byType(CustomPaint),
      );
      expect(focusRing, findsOneWidget);
      var focusVisible = false;
      for (var attempt = 0; attempt < 12 && !focusVisible; attempt++) {
        expect(await tester.sendKeyEvent(.tab), isTrue);
        await tester.pump();
        focusVisible =
            tester.widget<CustomPaint>(focusRing).foregroundPainter != null;
      }
      expect(focusVisible, isTrue);

      expect(await tester.sendKeyEvent(.enter), isTrue);
      expect(await tester.pumpAndSettle(), greaterThan(0));
      expect(navigationTaps, [0]);
      expect(content, findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}

({Widget app, GoRouter router}) _buildResponsiveShellApp({
  required ValueListenable<_ResponsiveShellTestSettings> settings,
  required FakeConversationRepository repository,
  required void Function(int) onNavigationTap,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/responsive-shell',
        builder: (context, state) {
          final label = LocaleKeys.menu_new_chat.tr(context: context);

          return ValueListenableBuilder<_ResponsiveShellTestSettings>(
            valueListenable: settings,
            builder: (context, currentSettings, child) => RepaintBoundary(
              key: const ValueKey('responsive-shell-golden'),
              child: Theme(
                data: _responsiveShellTestTheme(currentSettings.brightness),
                child: AuraThemeScope(
                  theme: currentSettings.brightness == Brightness.dark
                      ? AuraTheme.dark
                      : AuraTheme.light,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: .linear(currentSettings.textScaleFactor),
                    ),
                    child: Directionality(
                      textDirection: currentSettings.textDirection,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
            child: AppWithResponsiveDrawer(
              child: const Text('Shell content'),
              navigationItems: [
                AuraNavigationData(
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(label),
                  semanticLabel: label,
                ),
              ],
              onNavigationTap: onNavigationTap,
              selectedIndex: 0,
              workspaceId: 'ws-test',
            ),
          );
        },
      ),
    ],
    initialLocation: '/responsive-shell',
    overridePlatformDefaultLocation: true,
  );
  final app = EasyLocalization(
    child: Builder(
      builder: (context) => TestProviderScope(
        overrides: [
          conversationRepositoryProvider.overrideWithValue(repository),
          allWorkspacesProvider.overrideWith(
            (ref) => Stream.value([
              WorkspaceEntity(
                id: 'ws-test',
                name: 'Test workspace',
                type: .local,
                createdAt: .new(2020),
                updatedAt: .new(2020),
              ),
            ]),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: _responsiveShellTestTheme(.light),
          darkTheme: _responsiveShellTestTheme(.dark),
          themeMode: .light,
          locale: context.locale,
          localizationsDelegates: [
            ...GlobalMaterialLocalizations.delegates,
            ...context.localizationDelegates,
          ],
          supportedLocales: context.supportedLocales,
          debugShowCheckedModeBanner: false,
        ),
      ),
    ),
    supportedLocales: const [Locale('en'), Locale('es')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useOnlyLangCode: true,
    useFallbackTranslations: true,
    saveLocale: false,
  );

  return (app: app, router: router);
}

ThemeData _responsiveShellTestTheme(Brightness brightness) {
  final auraTheme = brightness == Brightness.dark
      ? AuraTheme.dark
      : AuraTheme.light;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: auraTheme.typography.bodyFontFamily,
  );
}
