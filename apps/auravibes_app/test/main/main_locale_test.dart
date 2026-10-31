import 'package:auravibes_app/features/settings/models/app_language_preference.dart';
import 'package:auravibes_app/main/main_locale.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('starts in the saved app language', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppLanguagePreference.preferenceKey: 'spanish',
      AppLanguagePreference.easyLocalizationPreferenceKey: 'en',
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
    expect(
      preferences.getString(
        AppLanguagePreference.easyLocalizationPreferenceKey,
      ),
      isNull,
    );
  });

  test('clears a saved language override for device mode', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppLanguagePreference.preferenceKey: 'system',
      AppLanguagePreference.easyLocalizationPreferenceKey: 'es',
    });

    await MainLocale.ensureInitialized();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(
        AppLanguagePreference.easyLocalizationPreferenceKey,
      ),
      isNull,
    );
  });

  test('unknown saved preferences fall back to device mode', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppLanguagePreference.preferenceKey: 'unsupported',
      AppLanguagePreference.easyLocalizationPreferenceKey: 'es',
    });

    await MainLocale.ensureInitialized();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(
        AppLanguagePreference.easyLocalizationPreferenceKey,
      ),
      isNull,
    );
  });
}
