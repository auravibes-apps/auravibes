import 'package:auravibes_ui/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('measure changing hue and repeated control color resolution', () {
    for (final brightness in AuraBrightness.values) {
      for (var hue = 0; hue < 30; hue++) {
        final _ = AuraComputedColorScheme(
          primaryHue: hue.toDouble(),
          brightness: brightness,
        );
      }
      final samples = <int>[];
      for (var hue = 0; hue < 180; hue++) {
        final watch = Stopwatch()..start();
        final colors = AuraComputedColorScheme(
          primaryHue: hue.toDouble(),
          brightness: brightness,
        );
        for (var control = 0; control < 20; control++) {
          final tint = AuraTint.values[control % 3];
          final _ = (fill: colors.fillFor(tint), onFill: colors.onFill(tint));
        }
        watch.stop();
        samples.add(watch.elapsedMicroseconds);
      }
      samples.sort();
      debugPrint(
        '${brightness.name}: median=${samples[samples.length ~/ 2]} us, '
        'p95=${samples[(samples.length * 0.95).floor()]} us',
      );
      expect(samples, hasLength(180));
    }
  });
}
