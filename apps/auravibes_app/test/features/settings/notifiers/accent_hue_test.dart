import 'package:auravibes_app/features/settings/notifiers/accent_hue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AccentHueNotifier', () {
    test('build defaults to brand teal hue', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(accentHueProvider.future), defaultAccentHue);
    });

    test('build restores saved hue', () async {
      SharedPreferences.setMockInitialValues({'app_accent_hue': 42.0});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(accentHueProvider.future), 42.0);
    });

    test('build clamps out-of-range saved hue', () async {
      SharedPreferences.setMockInitialValues({'app_accent_hue': 999.0});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(accentHueProvider.future), 360.0);
    });

    test('build falls back to default for NaN', () async {
      SharedPreferences.setMockInitialValues({'app_accent_hue': double.nan});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(accentHueProvider.future), defaultAccentHue);
    });

    test('setHue persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(accentHueProvider.notifier).setHue(120);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('app_accent_hue'), 120);
    });

    test('setHue round-trips through SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      await container.read(accentHueProvider.notifier).setHue(200);
      container.dispose();

      final other = ProviderContainer();
      addTearDown(other.dispose);

      expect(await other.read(accentHueProvider.future), 200);
    });

    test('setHue clamps above 360', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(accentHueProvider.future), defaultAccentHue);
      await container.read(accentHueProvider.notifier).setHue(500);

      expect(container.read(accentHueProvider).value, 360);
    });
  });
}
