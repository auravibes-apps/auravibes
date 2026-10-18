import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('bounds repeated unpaired high surrogates', () {
    for (final prefix in ['```dart\n', '{"createSurface":{"value":"']) {
      final decoder = A2uiStreamDecoder();
      final events = <A2uiStreamEvent>[...decoder.add(prefix)];
      final fragment = '\ud800' * 4096;
      for (var bytes = 0; bytes <= maxA2uiChatPayloadBytes; bytes += 4096) {
        events.addAll(decoder.add(fragment));
      }
      if (prefix.startsWith('```')) {
        expect(events.whereType<A2uiTextEvent>(), isNotEmpty);
        events.addAll(decoder.close());
        expect(
          events.whereType<A2uiTextEvent>().map((event) => event.text).join(),
          '$prefix${fragment * (maxA2uiChatPayloadBytes ~/ 4096 + 1)}',
        );
      } else {
        expect(
          events.whereType<A2uiInvalidEvent>().single.issue,
          A2uiIssueCode.oversizedPayload,
        );
      }
    }
  });

  test('recognizes a fence after unfinished ordinary brace text', () {
    const before = 'Literal {:\n';
    const payload =
        '$before```json\n'
        '{"version":"v0.9","deleteSurface":{"surfaceId":"main"}}'
        '\n```After';
    for (var split = 0; split <= payload.length; split++) {
      final decoder = A2uiStreamDecoder();
      final events = [
        ...decoder.add(payload.substring(0, split)),
        ...decoder.add(payload.substring(split)),
        ...decoder.close(),
      ];
      expect(events.whereType<A2uiInvalidEvent>(), isEmpty);
      expect(events.whereType<A2uiEnvelopeEvent>(), hasLength(1));
      expect(
        events.whereType<A2uiTextEvent>().map((event) => event.text).join(),
        '${before}After',
        reason: 'split $split',
      );
    }
  });
  test('streams a large ordinary fence before its closing delimiter', () {
    final decoder = A2uiStreamDecoder();
    final output = StringBuffer();
    const prefix = '```dart\n';
    const fragment = 'void main() {}\n';
    const count = maxA2uiChatPayloadBytes ~/ fragment.length + 100;
    final events = <A2uiStreamEvent>[...decoder.add(prefix)];
    for (var index = 0; index < count; index++) {
      events.addAll(decoder.add(fragment));
    }
    for (final event in events.whereType<A2uiTextEvent>()) {
      output.write(event.text);
    }
    expect(output.length, greaterThan(maxA2uiChatPayloadBytes));
    const suffix = '"createSurface": literal after commitment\n```After';
    events
      ..addAll(decoder.add(suffix))
      ..addAll(decoder.close());
    expect(events.whereType<A2uiInvalidEvent>(), isEmpty);
    expect(
      events.whereType<A2uiTextEvent>().map((event) => event.text).join(),
      '$prefix${fragment * count}$suffix',
    );
  });

  test('recognizes fenced A2UI at every two-chunk split', () {
    const payload =
        'Before```json\n'
        '{"version":"v0.9","deleteSurface":{"surfaceId":"main"}}'
        '\n```After';
    for (var split = 1; split < payload.length; split++) {
      final decoder = A2uiStreamDecoder();
      final events = [
        ...decoder.add(payload.substring(0, split)),
        ...decoder.add(payload.substring(split)),
        ...decoder.close(),
      ];
      expect(events.whereType<A2uiInvalidEvent>(), isEmpty);
      expect(events.whereType<A2uiEnvelopeEvent>(), hasLength(1));
      expect(
        events.whereType<A2uiTextEvent>().map((event) => event.text).join(),
        'BeforeAfter',
        reason: 'split $split',
      );
    }
  });

  test('keeps ordinary fence delimiters and Unicode across chunks', () {
    const payload = 'Before```dart\n{"answer":"😀"}\n```After``';
    final decoder = A2uiStreamDecoder();
    final events = <A2uiStreamEvent>[];
    for (var index = 0; index < payload.length; index++) {
      events.addAll(decoder.add(payload[index]));
    }
    events.addAll(decoder.close());
    expect(events.whereType<A2uiInvalidEvent>(), isEmpty);
    expect(
      events.whereType<A2uiTextEvent>().map((event) => event.text).join(),
      payload,
    );
  });

  for (final prefix in ['```json\n', '']) {
    test('limits an incomplete candidate with prefix "$prefix"', () {
      final decoder = A2uiStreamDecoder();
      final events = <A2uiStreamEvent>[
        ...decoder.add('$prefix{"createSurface":{"surfaceId":"main","x":"'),
      ];
      const fragment = 'éééééééé';
      for (var bytes = 0; bytes < maxA2uiChatPayloadBytes; bytes += 16) {
        events.addAll(decoder.add(fragment));
      }
      expect(events.whereType<A2uiInvalidEvent>().map((event) => event.issue), [
        A2uiIssueCode.oversizedPayload,
      ]);
      expect(events.whereType<A2uiInvalidEvent>().single.wireSurfaceId, 'main');
      final after = [...decoder.add('After'), ...decoder.close()];
      expect(
        after.whereType<A2uiTextEvent>().map((event) => event.text).join(),
        'After',
      );
    });
  }

  test('counts split surrogate pairs at the exact byte limit', () {
    const prefix = '{"createSurface":{"value":"';
    for (final extraByte in [0, 1]) {
      final decoder = A2uiStreamDecoder();
      final padding =
          'x' * (maxA2uiChatPayloadBytes - prefix.length - 4 + extraByte);
      expect(decoder.add('$prefix$padding'), isEmpty);
      expect(decoder.add('\ud83d'), isEmpty);
      final events = [...decoder.add('\ude00'), ...decoder.close()];
      expect(events.whereType<A2uiTextEvent>(), isEmpty);
      expect(
        events.whereType<A2uiInvalidEvent>().single.issue,
        extraByte == 0
            ? A2uiIssueCode.malformedPayload
            : A2uiIssueCode.oversizedPayload,
      );
    }
  });

  test('preserves malformed fenced diagnostics within the limit', () {
    const payload = '```json\n{"createSurface":{"surfaceId":"main"';
    final decoder = A2uiStreamDecoder();
    final events = <A2uiStreamEvent>[];
    for (var index = 0; index < payload.length; index++) {
      events.addAll(decoder.add(payload[index]));
    }
    events.addAll(decoder.close());
    final invalid = events.whereType<A2uiInvalidEvent>().single;
    expect(invalid.issue, A2uiIssueCode.malformedPayload);
    expect(invalid.wireSurfaceId, 'main');
    expect(jsonDecode(invalid.diagnosticPayloadJson!), {'rawPayload': payload});
    expect(events.whereType<A2uiTextEvent>(), isEmpty);
  });
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
