// Required: Existing theme notifier keeps SharedPreferences persistence flow.
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'accent_hue.g.dart';

/// Default accent hue: OKLCH hue of the brand teal `#0F766E` (≈ 186.4°).
abstract final class AccentHue {
  static const defaultValue = 186.0;
}

/// Persists the user's accent hue (OKLCH hue degrees, 0–360).
///
/// Drives AuraComputedColorScheme so the whole palette recomputes from one
/// value. Kept separate from ThemeNotifier so theme-mode state is untouched.
@Riverpod(keepAlive: true)
class AccentHueNotifier extends _$AccentHueNotifier {
  static const _key = 'app_accent_hue';

  @override
  Future<double> build() async {
    const maxHue = 360.0;
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final hue = prefs.getDouble(_key);
    if (hue == null || !hue.isFinite) return AccentHue.defaultValue;

    return hue.clamp(0.0, maxHue);
  }

  Future<void> setHue(double hue) async {
    const maxHue = 360.0;
    final clamped = hue.isFinite
        ? hue.clamp(0.0, maxHue)
        : AccentHue.defaultValue;
    final _ = await future;
    state = AsyncData(clamped);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final _ = await prefs.setDouble(_key, clamped);
  }
}
// Top-level API/provider declarations are required by their consumers.
