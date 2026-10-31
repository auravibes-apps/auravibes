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

  static String encode(AppAppearanceProfile profile) {
    _validateThemeMode(profile.themeMode);
    _validateAccentHue(profile.accentHue);
    final json = jsonEncode({
      'format': format,
      'version': version,
      'themeMode': profile.themeMode,
      'accentHue': profile.accentHue,
    });
    if (utf8.encode(json).length > maxProfileBytes) _throwInvalidProfile();

    return json;
  }

  static AppAppearanceProfile decode(String json) {
    final byteLength = utf8.encode(json).length;
    if (byteLength > maxProfileBytes) _throwInvalidProfile();

    try {
      return _decodeProfile(jsonDecode(json));
    } on AppAppearanceProfileException {
      rethrow;
    } on Object catch (_, stackTrace) {
      Error.throwWithStackTrace(_profileFormatError(), stackTrace);
    }
  }
}

const _profileFields = {'format', 'version', 'themeMode', 'accentHue'};
const _supportedThemeModes = {'system', 'light', 'dark'};

AppAppearanceProfile _decodeProfile(Object? value) {
  final profile = _profileObject(value);
  _validateFormat(profile['format']);
  _validateVersion(profile['version']);

  return AppAppearanceProfile(
    themeMode: _validatedThemeMode(profile['themeMode']),
    accentHue: _validatedAccentHue(profile['accentHue']),
  );
}

Map<String, dynamic> _profileObject(Object? value) {
  if (value is! Map<String, dynamic> || !_hasExactFields(value)) {
    _throwInvalidProfile();
  }

  return value;
}

bool _hasExactFields(Map<String, dynamic> value) =>
    value.length == _profileFields.length &&
    _profileFields.containsAll(value.keys);

void _validateFormat(Object? value) {
  if (value != AppAppearanceProfileCodec.format) _throwInvalidProfile();
}

void _validateVersion(Object? value) {
  if (value is! int) _throwInvalidProfile();
  if (value != AppAppearanceProfileCodec.version) _throwUnsupportedVersion();
}

String _validatedThemeMode(Object? value) {
  if (value is! String || !_supportedThemeModes.contains(value)) {
    _throwInvalidProfile();
  }

  return value;
}

double _validatedAccentHue(Object? value) {
  if (value is! num) _throwInvalidProfile();
  final hue = value.toDouble();
  _validateAccentHue(hue);

  return hue;
}

void _validateThemeMode(String value) {
  if (!_supportedThemeModes.contains(value)) _throwInvalidProfile();
}

void _validateAccentHue(double hue) {
  if (!hue.isFinite || hue < 0 || hue > 360) _throwInvalidProfile();
}

Never _throwInvalidProfile() => throw _profileFormatError();

AppAppearanceProfileException _profileFormatError() =>
    const AppAppearanceProfileException(
      'settings_screen.appearance_profile.invalid_file',
    );

Never _throwUnsupportedVersion() => throw const AppAppearanceProfileException(
  'settings_screen.appearance_profile.unsupported_version',
);
