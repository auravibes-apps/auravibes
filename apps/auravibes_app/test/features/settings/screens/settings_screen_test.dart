import 'package:auravibes_app/features/settings/notifiers/app_theme.dart';
import 'package:auravibes_app/features/settings/screens/settings_screen.dart';
import 'package:auravibes_app/widgets/aura_app_bar_with_drawer.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('AppTheme', () {
    test('light maps to ThemeMode.light', () {
      expect(AppTheme.light.themeMode, ThemeMode.light);
    });

    test('dark maps to ThemeMode.dark', () {
      expect(AppTheme.dark.themeMode, ThemeMode.dark);
    });

    test('system maps to ThemeMode.system', () {
      expect(AppTheme.system.themeMode, ThemeMode.system);
    });

    test('has three values', () {
      expect(AppTheme.values, hasLength(3));
    });

    test('values are light, dark, system', () {
      expect(
        AppTheme.values,
        containsAll([
          AppTheme.light,
          AppTheme.dark,
          AppTheme.system,
        ]),
      );
    });

    test('indices are sequential', () {
      for (var i = 0; i < AppTheme.values.length; i++) {
        expect(AppTheme.values[i].index, i);
      }
    });
  });

  group('render', () {
    testWidgets('renders SettingsScreen', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableApp(
            child: Theme(
              data: ThemeData(extensions: [AuraTheme.light]),
              child: const SettingsScreen(workspaceId: 'test-ws'),
            ),
            overrides: [themeProvider.overrideWith(_MockThemeNotifier.new)],
          ),
        );
      });
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(AuraScreen), findsOneWidget);
      expect(find.byType(AuraAppBarWithDrawer), findsOneWidget);
    });

    testWidgets('tapping theme tile shows radio group dialog', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testableApp(
            child: Theme(
              data: ThemeData(extensions: [AuraTheme.light]),
              child: const SettingsScreen(workspaceId: 'test-ws'),
            ),
            overrides: [themeProvider.overrideWith(_MockThemeNotifier.new)],
          ),
        );
      });
      await tester.pumpAndSettle();

      final themeTiles = find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.byType(AuraTile),
      );
      await tester.tap(themeTiles.first);
      await tester.pumpAndSettle();

      expect(find.byType(AuraRadioGroup<AppTheme>), findsOneWidget);
    });
  });
}
