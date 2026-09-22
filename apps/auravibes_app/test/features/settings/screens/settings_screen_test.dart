import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/features/settings/notifiers/accent_hue.dart';
import 'package:auravibes_app/features/settings/notifiers/app_theme.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/screens/settings_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

class _MockThemeNotifier extends ThemeNotifier {
  @override
  Future<AppTheme> build() async => AppTheme.system;
}

void main() {
  test('constructor sets workspaceId', () {
    const screen = SettingsScreen(workspaceId: 'test-ws');
    expect(screen.workspaceId, 'test-ws');
  });

  test('constructor accepts different workspaceIds', () {
    const screen = SettingsScreen(workspaceId: 'other-id');
    expect(screen.workspaceId, 'other-id');
  });

  group('render', () {
    testWidgets('renders SettingsScreen', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Theme(
              data: .new(extensions: [AuraTheme.light]),
              child: const SettingsScreen(workspaceId: 'test-ws'),
            ),
            overrides: [themeProvider.overrideWith(_MockThemeNotifier.new)],
          ),
        );
      });
      final _ = await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(AuraScreen), findsOneWidget);
      expect(find.byType(AuraAppBarWithDrawer), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('app_drawer_menu')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('settings_theme')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('settings_accent_color')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('settings_theme_reset')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('settings_accent_color_reset')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('settings_compaction_reset')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('settings_compaction_save')),
        findsOneWidget,
      );
    });

    testWidgets('reset actions restore theme and accent defaults', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'app_theme': AppTheme.dark.index,
        'app_accent_hue': 42.0,
      });

      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Theme(
              data: .new(extensions: [AuraTheme.light]),
              child: const SettingsScreen(workspaceId: 'test-ws'),
            ),
            overrides: [
              compactionSettingsProvider('test-ws').overrideWith(
                (ref) => Stream.value(CompactionSettings.defaults),
              ),
            ],
          ),
        );
      });
      final _ = await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('settings_theme_reset')),
      );
      final accentReset = find.byKey(
        const ValueKey<String>('settings_accent_color_reset'),
      );
      await tester.ensureVisible(accentReset);
      await tester.tap(accentReset);
      final _ = await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(.zero);
      });

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('app_theme'), AppTheme.system.index);
      expect(prefs.getDouble('app_accent_hue'), AccentHue.defaultValue);
    });

    testWidgets('tapping theme tile shows radio group dialog', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Theme(
              data: .new(extensions: [AuraTheme.light]),
              child: const SettingsScreen(workspaceId: 'test-ws'),
            ),
            overrides: [themeProvider.overrideWith(_MockThemeNotifier.new)],
          ),
        );
      });
      final _ = await tester.pumpAndSettle();

      final themeTiles = find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.byType(AuraTile),
      );
      await tester.tap(themeTiles.first);
      final _ = await tester.pumpAndSettle();

      expect(find.byType(AuraChoicePicker<AppTheme>), findsOneWidget);
    });

    testWidgets('changing theme keeps settings screen visible', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          compactionSettingsProvider('test-ws')
              .overrideWith((ref) => Stream.value(CompactionSettings.defaults)),
        ],
      );
      addTearDown(container.dispose);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          EasyLocalization(
            child: UncontrolledProviderScope(
              container: container,
              child: const _ThemeModeTestApp(),
            ),
            supportedLocales: const [Locale('en')],
            path: 'assets/i18n',
            fallbackLocale: const Locale('en'),
            startLocale: const Locale('en'),
            useOnlyLangCode: true,
            useFallbackTranslations: true,
          ),
        );
      });
      final _ = await tester.pumpAndSettle();

      final themeTiles = find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.byType(AuraTile),
      );
      await tester.tap(themeTiles.first);
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      final _ = await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(AuraChoicePicker<AppTheme>), findsNothing);
    });
  });
}

class const _ThemeModeTestApp() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(themeProvider).asData?.value.themeMode ?? ThemeMode.system;

    return MaterialApp(
      home: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const SettingsScreen(workspaceId: 'test-ws'),
        ),
      ),
      theme: .new(extensions: [AuraTheme.light]),
      darkTheme: .new(extensions: [AuraTheme.dark]),
      themeMode: themeMode,
      locale: context.locale,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
    );
  }
}
