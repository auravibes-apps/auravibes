// Dart imports:
import 'dart:io';

// Project imports:
import 'package:auravibes_engine/auravibes_engine.dart';

void main() {
  const fragment = 'abcdefghijklmnop';
  for (final prefix in ['```dart\n', '{"createSurface":{"value":"']) {
    for (final kib in [32, 64, 128, 256]) {
      final samples = <int>[];
      for (var sample = 0; sample < 5; sample++) {
        final decoder = A2uiStreamDecoder();
        final watch = Stopwatch()..start();
        var textLength = 0;
        var invalidCount = 0;
        for (final event in decoder.add(prefix)) {
          if (event is A2uiTextEvent) textLength += event.text.length;
        }
        for (var bytes = 0; bytes < kib * 1024; bytes += fragment.length) {
          for (final event in decoder.add(fragment)) {
            if (event is A2uiTextEvent) textLength += event.text.length;
            if (event is A2uiInvalidEvent) invalidCount++;
          }
        }
        for (final event in decoder.close()) {
          if (event is A2uiTextEvent) textLength += event.text.length;
          if (event is A2uiInvalidEvent) invalidCount++;
        }
        watch.stop();
        if (prefix.startsWith('```')) {
          if (textLength != prefix.length + kib * 1024 || invalidCount != 0) {
            throw StateError('Ordinary text differs.');
          }
        } else if (invalidCount != 1 || textLength != 0) {
          throw StateError('Candidate classification differs.');
        }
        samples.add(watch.elapsedMicroseconds);
      }
      samples.sort();
      stdout.writeln(
        '${prefix.startsWith('```') ? 'fence' : 'candidate'} '
        '$kib KiB: ${samples[2]} us median (16-byte fragments)',
      );
    }
  }
}
