import 'package:auravibes_app/features/settings/models/app_language_preference.dart';
import 'package:auravibes_app/main/main_locale.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _appLanguagePreferenceKey = AppLanguagePreference.preferenceKey;
const String _easyLocalizationPreferenceKey =
    AppLanguagePreference.easyLocalizationPreferenceKey;

void main() {
  testWidgets('starts in the saved app language', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      _appLanguagePreferenceKey: 'spanish',
      _easyLocalizationPreferenceKey: 'en',
    });

    await MainLocale.ensureInitialized();
    await tester.pumpWidget(
      MainLocale(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Text(context.locale.languageCode),
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('es'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(_easyLocalizationPreferenceKey), isNull);
  });

  test('clears a saved language override for device mode', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      _appLanguagePreferenceKey: 'system',
      _easyLocalizationPreferenceKey: 'es',
    });

    await MainLocale.ensureInitialized();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(_easyLocalizationPreferenceKey), isNull);
  });

  test('unknown saved preferences fall back to device mode', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      _appLanguagePreferenceKey: 'unsupported',
      _easyLocalizationPreferenceKey: 'es',
    });

    await MainLocale.ensureInitialized();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(_easyLocalizationPreferenceKey), isNull);
  });
}
