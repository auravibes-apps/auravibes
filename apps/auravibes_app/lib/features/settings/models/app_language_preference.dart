import 'package:material_ui/material_ui.dart';

enum AppLanguagePreference {
  system,
  english,
  spanish;

  static const preferenceKey = 'app_language_preference';
  static const easyLocalizationPreferenceKey = 'locale';

  static AppLanguagePreference fromStoredValue(Object? value) =>
      switch (value) {
        'english' => .english,
        'spanish' => .spanish,
        _ => .system,
      };

  Locale? get locale => switch (this) {
    .system => null,
    .english => const Locale('en'),
    .spanish => const Locale('es'),
  };

  String get labelKey => switch (this) {
    .system => 'settings_screen.language.device',
    .english => 'settings_screen.language.english',
    .spanish => 'settings_screen.language.spanish',
  };
}
