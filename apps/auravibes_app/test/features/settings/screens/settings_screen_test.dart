import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/settings/models/app_language_preference.dart';
import 'package:auravibes_app/features/settings/notifiers/accent_hue.dart';
import 'package:auravibes_app/features/settings/notifiers/app_theme.dart';
import 'package:auravibes_app/features/settings/providers/app_language_preference_notifier.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/screens/settings_screen.dart';
import 'package:auravibes_app/features/settings/widgets/app_version_indicator.dart';
import 'package:auravibes_app/features/settings/widgets/compaction_settings_section.dart';
import 'package:auravibes_app/providers/app_providers.dart';
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

Future<void> _pumpSettingsScreen(
  WidgetTester tester, {
  bool initializeLocalization = false,
}) async {
  await tester.runAsync(() async {
    if (initializeLocalization) await EasyLocalization.ensureInitialized();
    await tester.pumpWidget(
      TestableApp(
        child: AuraThemeScope(
          theme: .light,
          child: Theme(
            data: .new(),
            child: const SettingsScreen(workspaceId: 'test-ws'),
          ),
        ),
        overrides: [
          themeProvider.overrideWith(_MockThemeNotifier.new),
          compactionSettingsProvider('test-ws')
              .overrideWith((ref) => Stream.value(CompactionSettings.defaults)),
          listWorkspaceModelSelectionsProvider(workspaceId: 'test-ws')
              .overrideWith((ref) => Stream.value(const [])),
        ],
      ),
    );
  });
  final _ = await tester.pumpAndSettle();
}

Future<void> _waitForLanguagePreference(
  WidgetTester tester,
  String expected,
) async {
  await tester.runAsync(() async {
    final preferences = await SharedPreferences.getInstance();
    final stopwatch = Stopwatch()..start();
    while (preferences.getString(AppLanguagePreference.preferenceKey) !=
            expected &&
        stopwatch.elapsed < const Duration(seconds: 2)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
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
      final semantics = tester.ensureSemantics();
      await _pumpSettingsScreen(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(CompactionSettingsSection), findsNothing);
      expect(find.byType(AuraScreen), findsOneWidget);
      expect(find.byType(AppVersionIndicator), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('settings_privacy')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('settings_terms')),
        findsOneWidget,
      );
      expect(find.byType(AuraAppBarWithDrawer), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('app_drawer_menu')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('settings_theme')),
        findsOneWidget,
      );
      expect(find.bySemanticsIdentifier('settings_theme'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('settings_theme')).evaluate().single,
        find.bySemanticsIdentifier('settings_theme').evaluate().single,
      );
      expect(
        find.byKey(const ValueKey<String>('settings_accent_color')),
        findsOneWidget,
      );
      final appearanceCard = find
          .ancestor(
            of: find.byKey(const ValueKey<String>('settings_theme')),
            matching: find.byType(AuraCard),
          )
          .first;
      expect(
        find.descendant(
          of: appearanceCard,
          matching: find.byKey(const ValueKey<String>('settings_accent_color')),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('settings_appearance_reset')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('settings_compaction_reset')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('settings_compaction_save')),
        findsNothing,
      );
      semantics.dispose();
    });

    testWidgets('selects a language, persists it, and clears the override', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      SharedPreferences.setMockInitialValues({});

      await _pumpSettingsScreen(tester, initializeLocalization: true);

      expect(find.text('Device language'), findsOneWidget);
      await tester.tap(find.bySemanticsIdentifier('settings_language'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('App language'), findsOneWidget);

      await tester.tap(find.text('English'));
      final _ = await tester.pumpAndSettle();

      var preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(AppLanguagePreference.preferenceKey),
        'english',
      );

      await tester.tap(find.bySemanticsIdentifier('settings_language'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Spanish'));
      final _ = await tester.pumpAndSettle();
      await _waitForLanguagePreference(tester, 'spanish');
      final _ = await tester.pumpAndSettle();

      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Apariencia'), findsOneWidget);
      preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(AppLanguagePreference.preferenceKey),
        'spanish',
      );

      final restoredContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWith((ref) async => preferences),
        ],
      );
      addTearDown(restoredContainer.dispose);
      expect(
        await restoredContainer.read(appLanguagePreferenceProvider.future),
        AppLanguagePreference.spanish,
      );

      await tester.tap(find.bySemanticsIdentifier('settings_language'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Idioma del dispositivo'));
      final _ = await tester.pumpAndSettle();
      await _waitForLanguagePreference(tester, 'system');
      final _ = await tester.pumpAndSettle();

      preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(AppLanguagePreference.preferenceKey),
        'system',
      );
      expect(
        preferences.getString(
          AppLanguagePreference.easyLocalizationPreferenceKey,
        ),
        isNull,
      );
      semantics.dispose();
    });

    testWidgets('reset restores theme and accent defaults', (tester) async {
      final semantics = tester.ensureSemantics();
      SharedPreferences.setMockInitialValues({
        'app_theme': AppTheme.dark.index,
        'app_accent_hue': 42.0,
      });

      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: AuraThemeScope(
              theme: .light,
              child: Theme(
                data: .new(),
                child: const SettingsScreen(workspaceId: 'test-ws'),
              ),
            ),
            overrides: [
              compactionSettingsProvider('test-ws').overrideWith(
                (ref) => Stream.value(CompactionSettings.defaults),
              ),
              listWorkspaceModelSelectionsProvider(workspaceId: 'test-ws')
                  .overrideWith((ref) => Stream.value(const [])),
            ],
          ),
        );
      });
      final _ = await tester.pumpAndSettle();

      final reset = find.bySemanticsIdentifier('settings_appearance_reset');
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      final _ = await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(.zero);
      });

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('app_theme'), AppTheme.system.index);
      expect(prefs.getDouble('app_accent_hue'), AccentHue.defaultValue);
      semantics.dispose();
    });

    testWidgets('theme tile shows the label chosen in the picker', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      SharedPreferences.setMockInitialValues({
        'app_theme': AppTheme.dark.index,
      });

      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: AuraThemeScope(
              theme: .light,
              child: Theme(
                data: .new(),
                child: const SettingsScreen(workspaceId: 'test-ws'),
              ),
            ),
            overrides: [
              compactionSettingsProvider('test-ws').overrideWith(
                (ref) => Stream.value(CompactionSettings.defaults),
              ),
              listWorkspaceModelSelectionsProvider(workspaceId: 'test-ws')
                  .overrideWith((ref) => Stream.value(const [])),
            ],
          ),
        );
      });
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsIdentifier('settings_theme'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('System'));
      final _ = await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.bySemanticsIdentifier('settings_theme'),
          matching: find.text('System'),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('accent dialog explains what the color changes', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      SharedPreferences.setMockInitialValues({});

      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: AuraThemeScope(
              theme: .light,
              child: Theme(
                data: .new(),
                child: const SettingsScreen(workspaceId: 'test-ws'),
              ),
            ),
            overrides: [
              compactionSettingsProvider('test-ws').overrideWith(
                (ref) => Stream.value(CompactionSettings.defaults),
              ),
              listWorkspaceModelSelectionsProvider(workspaceId: 'test-ws')
                  .overrideWith((ref) => Stream.value(const [])),
            ],
          ),
        );
      });
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsIdentifier('settings_accent_color'));
      final _ = await tester.pumpAndSettle();

      expect(
        find.text(
          'Drag to change the main color for buttons, links, and highlights.',
        ),
        findsOneWidget,
      );
      expect(find.text('Accent Hue'), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('changing theme keeps settings screen visible', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          compactionSettingsProvider('test-ws')
              .overrideWith((ref) => Stream.value(CompactionSettings.defaults)),
          listWorkspaceModelSelectionsProvider(workspaceId: 'test-ws')
              .overrideWith((ref) => Stream.value(const [])),
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
      expect(find.byType(AuraChoicePicker<AppTheme>), findsOneWidget);

      await tester.tap(find.text('Dark'));
      final _ = await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(AuraChoicePicker<AppTheme>), findsNothing);
      final _ = Navigator.of(tester.element(find.byType(SettingsScreen)))
          .push<void>(
            MaterialPageRoute(
              builder: (_) => const SettingsScreen(workspaceId: 'workspace-B'),
            ),
          );
      final _ = await tester.pumpAndSettle();
      expect(container.read(themeProvider).asData?.value, AppTheme.dark);
      expect(
        tester.widget<SettingsScreen>(find.byType(SettingsScreen)).workspaceId,
        'workspace-B',
      );
      expect(find.byType(CompactionSettingsSection), findsNothing);
    });
  });
}

class const _ThemeModeTestApp() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(themeProvider).asData?.value.themeMode ?? ThemeMode.system;

    return AuraThemeScope(
      theme: .dark,
      child: MaterialApp(
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => const SettingsScreen(workspaceId: 'test-ws'),
          ),
        ),
        theme: .new(),
        darkTheme: .new(),
        themeMode: themeMode,
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
      ),
    );
  }
}
