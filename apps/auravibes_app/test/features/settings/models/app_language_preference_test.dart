import 'package:auravibes_app/features/settings/models/app_language_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads supported language preferences', () {
    expect(
      AppLanguagePreference.fromStoredValue('english'),
      AppLanguagePreference.english,
    );
    expect(
      AppLanguagePreference.fromStoredValue('spanish'),
      AppLanguagePreference.spanish,
    );
    expect(
      AppLanguagePreference.fromStoredValue('system'),
      AppLanguagePreference.system,
    );
  });

  test('falls back to device language for an unknown saved value', () {
    expect(
      AppLanguagePreference.fromStoredValue('unsupported'),
      AppLanguagePreference.system,
    );
    expect(
      AppLanguagePreference.fromStoredValue(null),
      AppLanguagePreference.system,
    );
  });
}
