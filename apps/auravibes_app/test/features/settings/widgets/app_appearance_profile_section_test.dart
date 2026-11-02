import 'dart:convert';

import 'package:auravibes_app/domain/entities/compaction_settings.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/settings/notifiers/app_theme.dart';
import 'package:auravibes_app/features/settings/providers/compaction_settings_provider.dart';
import 'package:auravibes_app/features/settings/screens/settings_screen.dart';
import 'package:auravibes_app/features/settings/services/app_appearance_profile_file_service.dart';
import 'package:auravibes_app/features/settings/usecases/app_appearance_profile_usecase.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  group('appearance profile settings actions', () {
    testWidgets('confirmed import applies the previewed values', (
      tester,
    ) async {
      final fileService = _ControlledProfileFileService(
        pickedJson: _profileJson(themeMode: 'dark', accentHue: 222.5),
      );
      await _pumpSettings(tester, fileService);

      await _tapProfileImport(tester);

      expect(find.text('Preview appearance profile'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.textContaining('222.5'), findsOneWidget);
      expect(
        find.text(
          'This will update only the theme and accent color on this device.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Apply appearance'));
      final _ = await tester.pumpAndSettle();
      await _flushAsyncPreferences(tester);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getInt('app_theme'), AppTheme.dark.index);
      expect(preferences.getDouble('app_accent_hue'), 222.5);
      expect(find.text('Appearance restored.'), findsOneWidget);
    });

    testWidgets('canceling the preview leaves both preferences unchanged', (
      tester,
    ) async {
      final fileService = _ControlledProfileFileService(
        pickedJson: _profileJson(themeMode: 'dark', accentHue: 222.5),
      );
      await _pumpSettings(tester, fileService, theme: .light, hue: 24);

      await _tapProfileImport(tester);
      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();
      await _flushAsyncPreferences(tester);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getInt('app_theme'), AppTheme.light.index);
      expect(preferences.getDouble('app_accent_hue'), 24.0);
      expect(find.text('Appearance restored.'), findsNothing);
    });

    testWidgets('canceling file selection leaves both preferences unchanged', (
      tester,
    ) async {
      final fileService = _ControlledProfileFileService();
      await _pumpSettings(tester, fileService, theme: .dark, hue: 80);

      await _tapProfileImport(tester);
      final _ = await tester.pumpAndSettle();
      await _flushAsyncPreferences(tester);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getInt('app_theme'), AppTheme.dark.index);
      expect(preferences.getDouble('app_accent_hue'), 80.0);
      expect(find.text('Preview appearance profile'), findsNothing);
      expect(find.text('Appearance restored.'), findsNothing);
    });

    testWidgets(
      'malformed profile shows a localized error and changes nothing',
      (tester) async {
        final fileService = _ControlledProfileFileService(pickedJson: '{bad');
        await _pumpSettings(tester, fileService, theme: .light, hue: 35);

        await _tapProfileImport(tester);
        final _ = await tester.pumpAndSettle();
        await _flushAsyncPreferences(tester);

        final preferences = await SharedPreferences.getInstance();
        expect(preferences.getInt('app_theme'), AppTheme.light.index);
        expect(preferences.getDouble('app_accent_hue'), 35.0);
        expect(
          find.text(
            LocaleKeys.settings_screen_appearance_profile_invalid_file.tr(),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('unknown version shows its localized error without changes', (
      tester,
    ) async {
      final fileService = _ControlledProfileFileService(
        pickedJson: _profileJson(
          themeMode: 'dark',
          accentHue: 222.5,
          version: 8,
        ),
      );
      await _pumpSettings(tester, fileService, hue: 120);

      await _tapProfileImport(tester);
      final _ = await tester.pumpAndSettle();
      await _flushAsyncPreferences(tester);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getInt('app_theme'), AppTheme.system.index);
      expect(preferences.getDouble('app_accent_hue'), 120.0);
      expect(
        find.text(
          LocaleKeys.settings_screen_appearance_profile_unsupported_version
              .tr(),
        ),
        findsOneWidget,
      );
    });

    testWidgets('export uses current appearance values only', (tester) async {
      final fileService = _ControlledProfileFileService();
      await _pumpSettings(tester, fileService, theme: .dark, hue: 186);

      await _tapProfileExport(tester);
      final _ = await tester.pumpAndSettle();

      final savedJson = fileService.savedJson;
      expect(savedJson, isNotNull);
      final exported = jsonDecode(savedJson ?? '{}') as Map<String, dynamic>;
      expect(exported.keys.toSet(), {
        'format',
        'version',
        'themeMode',
        'accentHue',
      });
      expect(exported['themeMode'], 'dark');
      expect(exported['accentHue'], 186);
      expect(find.text('Appearance profile saved.'), findsOneWidget);
    });

    testWidgets('canceling export does not show a success message', (
      tester,
    ) async {
      final fileService = _ControlledProfileFileService(saveResult: false);
      await _pumpSettings(tester, fileService);

      await _tapProfileExport(tester);
      final _ = await tester.pumpAndSettle();

      expect(find.text('Appearance profile saved.'), findsNothing);
    });
  });
}

Future<void> _pumpSettings(
  WidgetTester tester,
  _ControlledProfileFileService fileService, {
  AppTheme theme = .system,
  double hue = 300,
}) async {
  SharedPreferences.setMockInitialValues({
    'app_theme': theme.index,
    'app_accent_hue': hue,
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
          appAppearanceProfileUsecaseProvider.overrideWith(
            (ref) => AppAppearanceProfileUsecase(fileService: fileService),
          ),
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

Future<void> _tapProfileImport(WidgetTester tester) async {
  final button = find.bySemanticsIdentifier(
    'settings_appearance_profile_import',
  );
  await tester.ensureVisible(button);
  await tester.tap(button);
  final _ = await tester.pumpAndSettle();
}

Future<void> _tapProfileExport(WidgetTester tester) async {
  final button = find.bySemanticsIdentifier(
    'settings_appearance_profile_export',
  );
  await tester.ensureVisible(button);
  await tester.tap(button);
}

Future<void> _flushAsyncPreferences(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(.zero);
  });
}

String _profileJson({
  required String themeMode,
  required double accentHue,
  int version = 1,
}) =>
    '''
  {"format":"auravibes.app-appearance","version":$version,"themeMode":"$themeMode","accentHue":$accentHue}
''';

class _ControlledProfileFileService({
  final String? pickedJson,
  final bool saveResult = true,
}) extends AppAppearanceProfileFileService {
  String? savedJson;

  @override
  Future<String?> pickProfileJson() async => pickedJson;

  @override
  Future<bool> saveProfileJson(String json) async {
    savedJson = json;

    return saveResult;
  }
}
