import 'package:auravibes_engine/src/genkit_providers/media_input.dart';
import 'package:genkit/plugin.dart';
import 'package:test/test.dart';

void main() {
  test('dataUrlPayload rejects invalid base64', () {
    expect(dataUrlPayload('data:audio/mpeg;base64,not-base64'), isNull);
  });

  test('audioFormat maps wav aliases', () {
    expect(audioFormat('audio/wav', 'Provider'), 'wav');
    expect(audioFormat('audio/x-wav', 'Provider'), 'wav');
  });

  test('audioFormat rejects unsupported content types', () {
    expect(
      () => audioFormat('audio/ogg', 'Provider'),
      throwsA(isA<GenkitException>()),
    );
  });
}
