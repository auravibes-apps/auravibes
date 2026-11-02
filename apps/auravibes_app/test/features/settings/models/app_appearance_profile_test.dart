import 'dart:convert';

import 'package:auravibes_app/features/settings/models/app_appearance_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppAppearanceProfileCodec', () {
    test('exports only supported fields and decodes the same appearance', () {
      const profile = AppAppearanceProfile(themeMode: 'dark', accentHue: 186);

      final encoded = AppAppearanceProfileCodec.encode(profile);
      final decodedJson = jsonDecode(encoded) as Map<String, dynamic>;
      final decoded = AppAppearanceProfileCodec.decode(encoded);

      expect(decodedJson.keys.toSet(), {
        'format',
        'version',
        'themeMode',
        'accentHue',
      });
      expect(decodedJson, {
        'format': 'auravibes.app-appearance',
        'version': 1,
        'themeMode': 'dark',
        'accentHue': 186,
      });
      expect(decoded.themeMode, 'dark');
      expect(decoded.accentHue, 186.0);
    });

    test('rejects malformed JSON', () {
      _expectProfileError('{not json');
    });

    test('rejects a missing format identifier', () {
      _expectProfileError('''
        {"version":1,"themeMode":"dark","accentHue":186}
      ''');
    });

    test('rejects an incorrect format identifier', () {
      _expectProfileError('''
        {"format":"other","version":1,"themeMode":"dark","accentHue":186}
      ''');
    });

    test('rejects a missing version', () {
      _expectProfileError('''
        {"format":"auravibes.app-appearance","themeMode":"dark","accentHue":186}
      ''');
    });

    test('rejects a wrongly typed version', () {
      _expectProfileError('''
        {"format":"auravibes.app-appearance","version":"1","themeMode":"dark","accentHue":186}
      ''');
    });

    test('reports an unknown integer version separately', () {
      const json = '''
        {"format":"auravibes.app-appearance","version":2,"themeMode":"dark","accentHue":186}
      ''';
      _expectProfileError(
        json,
        key: 'settings_screen.appearance_profile.unsupported_version',
      );
    });

    test('rejects an unsupported theme mode', () {
      _expectProfileError('''
        {"format":"auravibes.app-appearance","version":1,"themeMode":"automatic","accentHue":186}
      ''');
    });

    test('rejects a missing accent hue', () {
      _expectProfileError('''
        {"format":"auravibes.app-appearance","version":1,"themeMode":"dark"}
      ''');
    });

    test('rejects a wrongly typed accent hue', () {
      _expectProfileError('''
        {"format":"auravibes.app-appearance","version":1,"themeMode":"dark","accentHue":"186"}
      ''');
    });

    test('rejects accent hue below zero', () {
      _expectProfileError(_profileJson(accentHue: -0.1));
    });

    test('rejects accent hue above 360', () {
      _expectProfileError(_profileJson(accentHue: 360.1));
    });

    test('rejects a non-finite hue when exporting', () {
      expect(
        () => AppAppearanceProfileCodec.encode(
          const AppAppearanceProfile(themeMode: 'system', accentHue: .nan),
        ),
        throwsA(
          _profileErrorWithKey(
            'settings_screen.appearance_profile.invalid_file',
          ),
        ),
      );
    });

    test('rejects unexpected fields such as credentials', () {
      _expectProfileError('''
        {"format":"auravibes.app-appearance","version":1,"themeMode":"dark","accentHue":186,"credentials":{"apiKey":"secret"}}
      ''');
    });
  });
}

void _expectProfileError(
  String json, {
  String key = 'settings_screen.appearance_profile.invalid_file',
}) {
  expect(
    () => AppAppearanceProfileCodec.decode(json),
    throwsA(_profileErrorWithKey(key)),
  );
}

Matcher _profileErrorWithKey(String key) => isA<AppAppearanceProfileException>()
    .having((error) => error.localizationKey, 'localizationKey', key);

String _profileJson({required double accentHue}) =>
    '''{"format":"auravibes.app-appearance","version":1,"themeMode":"dark","accentHue":$accentHue}''';
