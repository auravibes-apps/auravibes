// Required: Existing theme notifier keeps SharedPreferences persistence flow.
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'accent_hue.g.dart';

/// Default accent hue: OKLCH hue of the brand teal `#0F766E` (≈ 186.4°).
const defaultAccentHue = 186.0;

/// Persists the user's accent hue (OKLCH hue degrees, 0–360).
///
/// Drives AuraComputedColorScheme so the whole palette recomputes from one
/// value. Kept separate from ThemeNotifier so theme-mode state is untouched.
@Riverpod(keepAlive: true)
class AccentHueNotifier extends _$AccentHueNotifier {
  static const _key = 'app_accent_hue';

  @override
  Future<double> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final hue = prefs.getDouble(_key);
    if (hue == null || !hue.isFinite) return defaultAccentHue;

    return hue.clamp(0.0, 360.0);
  }

  Future<void> setHue(double hue) async {
    final clamped = hue.isFinite ? hue.clamp(0.0, 360.0) : defaultAccentHue;
    final _ = await future;
    state = AsyncData(clamped);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final _ = await prefs.setDouble(_key, clamped);
  }
}
