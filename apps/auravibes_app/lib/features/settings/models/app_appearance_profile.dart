import 'dart:convert';

class const AppAppearanceProfile({
  required final String themeMode,
  required final double accentHue,
});

/// A validation error for an app appearance profile file.
class const AppAppearanceProfileException(final String localizationKey)
    implements Exception;

abstract final class AppAppearanceProfileCodec {
  static const format = 'auravibes.app-appearance';
  static const version = 1;
  static const int maxProfileBytes = 16 * 1024;

  static const _fields = {'format', 'version', 'themeMode', 'accentHue'};
  static const _themeModes = {'system', 'light', 'dark'};

  static String encode(AppAppearanceProfile profile) {
    _validateThemeMode(profile.themeMode);
    _validateHue(profile.accentHue);
    final json = jsonEncode({
      'format': format,
      'version': version,
      'themeMode': profile.themeMode,
      'accentHue': profile.accentHue,
    });
    if (utf8.encode(json).length > maxProfileBytes) _invalidProfile();

    return json;
  }

  static AppAppearanceProfile decode(String json) {
    if (utf8.encode(json).length > maxProfileBytes) _invalidProfile();

    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic> || !_hasExactFields(decoded)) {
        _invalidProfile();
      }
      if (decoded['format'] != format) _invalidProfile();

      final rawVersion = decoded['version'];
      if (rawVersion is! int) _invalidProfile();
      if (rawVersion != version) _unsupportedVersion();

      final themeMode = decoded['themeMode'];
      if (themeMode is! String || !_themeModes.contains(themeMode)) {
        _invalidProfile();
      }
      final rawHue = decoded['accentHue'];
      if (rawHue is! num) _invalidProfile();
      final accentHue = rawHue.toDouble();
      _validateHue(accentHue);

      return AppAppearanceProfile(themeMode: themeMode, accentHue: accentHue);
    } on AppAppearanceProfileException {
      rethrow;
    } on Object catch (_, stackTrace) {
      Error.throwWithStackTrace(_invalidProfileError(), stackTrace);
    }
  }

  static bool _hasExactFields(Map<String, dynamic> value) =>
      value.length == _fields.length && _fields.containsAll(value.keys);

  static void _validateThemeMode(String value) {
    if (!_themeModes.contains(value)) _invalidProfile();
  }

  static void _validateHue(double hue) {
    if (!hue.isFinite || hue < 0 || hue > 360) _invalidProfile();
  }

  static Never _invalidProfile() => throw _invalidProfileError();

  static AppAppearanceProfileException _invalidProfileError() =>
      const AppAppearanceProfileException(
        'settings_screen.appearance_profile.invalid_file',
      );

  static Never _unsupportedVersion() =>
      throw const AppAppearanceProfileException(
        'settings_screen.appearance_profile.unsupported_version',
      );
}
