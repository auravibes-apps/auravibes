import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('separates fragmented A2UI from surrounding text', () {
    final decoder = A2uiStreamDecoder();
    final events = [
      ...decoder.add('Before '),
      ...decoder.add(
        '{"protocolVersion":"v1","interactionMode":"passive",'
        '"message":{"version":"v0.9","createSurface":',
      ),
      ...decoder.add(
        '{"surfaceId":"main","catalogId":"urn:auravibes:a2ui:chat:v1"}}}',
      ),
      ...decoder.close(),
    ];

    expect(events.whereType<A2uiTextEvent>().map((event) => event.text), [
      'Before ',
    ]);
    expect(events.whereType<A2uiEnvelopeEvent>(), hasLength(1));
  });

  test('reports incomplete A2UI without leaking it as text', () {
    final decoder = A2uiStreamDecoder();
    const payload = '{"createSurface":{"surfaceId":"main"';
    final events = [...decoder.add(payload), ...decoder.close()];

    expect(events.whereType<A2uiInvalidEvent>(), hasLength(1));
    expect(events.whereType<A2uiTextEvent>(), isEmpty);
    expect(
      jsonDecode(
        events.whereType<A2uiInvalidEvent>().single.diagnosticPayloadJson!,
      ),
      {'rawPayload': payload},
    );
  });

  test('normalizes legacy data-model requests from streamed A2UI', () {
    final decoder = A2uiStreamDecoder();
    final events = [
      ...decoder.add(
        '{"protocolVersion":"v1","interactionMode":"passive",'
        '"message":{"version":"v0.9","createSurface":{'
        '"surfaceId":"main","catalogId":"urn:auravibes:a2ui:chat:v1",'
        '"sendDataModel":true}}}',
      ),
      ...decoder.close(),
    ];

    final envelope = events.whereType<A2uiEnvelopeEvent>().single.envelope;
    expect(jsonDecode(envelope.payloadJson), {
      'protocolVersion': 'v1',
      'interactionMode': 'passive',
      'message': {
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'main',
          'catalogId': 'urn:auravibes:a2ui:chat:v1',
          'sendDataModel': false,
        },
      },
    });
  });

  test('keeps ordinary JSON as text', () {
    final decoder = A2uiStreamDecoder();
    final events = [...decoder.add('{"answer":42}'), ...decoder.close()];

    expect(events.whereType<A2uiTextEvent>().single.text, '{"answer":42}');
  });

  test('keeps an unfinished ordinary code fence as text', () {
    final decoder = A2uiStreamDecoder();
    final events = [
      ...decoder.add('```dart\nvoid main() {'),
      ...decoder.close(),
    ];

    expect(events.whereType<A2uiInvalidEvent>(), isEmpty);
    expect(
      events.whereType<A2uiTextEvent>().single.text,
      '```dart\nvoid main() {',
    );
  });

  test('separates text before a fenced A2UI envelope', () {
    final decoder = A2uiStreamDecoder();
    final events = [
      ...decoder.add(
        'Here is the UI:\n```json\n'
        '{"protocolVersion":"v1","interactionMode":"passive",'
        '"message":{"version":"v0.9","createSurface":{'
        '"surfaceId":"main","catalogId":"urn:auravibes:a2ui:chat:v1"}}}'
        '\n```',
      ),
      ...decoder.close(),
    ];

    expect(events.whereType<A2uiTextEvent>().single.text, 'Here is the UI:\n');
    expect(events.whereType<A2uiEnvelopeEvent>(), hasLength(1));
  });
}
