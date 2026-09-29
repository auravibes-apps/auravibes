import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart'
    show MissingPluginException, PlatformException;
import 'package:haptic_feedback/haptic_feedback.dart';

/// Capability-checked haptic feedback for Aura UI interactions.
abstract final class AuraHaptics {
  static bool? _canVibrate;

  /// Plays success feedback.
  static Future<void> success() => _vibrate(.success);

  /// Plays warning feedback.
  static Future<void> warning() => _vibrate(.warning);

  /// Plays error feedback.
  static Future<void> error() => _vibrate(.error);

  /// Plays light feedback.
  static Future<void> light() => _vibrate(.light);

  /// Plays medium feedback.
  static Future<void> medium() => _vibrate(.medium);

  /// Plays heavy feedback.
  static Future<void> heavy() => _vibrate(.heavy);

  /// Plays selection feedback.
  static Future<void> selection() => _vibrate(.selection);

  /// Resets capability cache for tests.
  @visibleForTesting
  static void resetForTesting() => _canVibrate = null;

  static Future<void> _vibrate(HapticsType type) async {
    try {
      _canVibrate ??= await Haptics.canVibrate();
      if (_canVibrate == true) await Haptics.vibrate(type);
    } on MissingPluginException {
      _canVibrate = false;
    } on PlatformException {
      _canVibrate = false;
    }
  }
}
