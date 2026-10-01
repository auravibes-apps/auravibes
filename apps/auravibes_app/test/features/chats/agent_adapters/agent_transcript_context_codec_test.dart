import 'dart:convert';

import 'package:auravibes_app/features/chats/agent_adapters/agent_transcript_context_codec.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_transcript_context_decode_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentTranscriptContextCodec', () {
    test('decodes and encodes the current v1 format', () {
      const stored = '{"version":1,"toolsAdded":[],"toolsRemoved":[]}';

      final update = AgentTranscriptContextCodec.decodeUpdate(stored);
      final encoded = jsonDecode(
        AgentTranscriptContextCodec.encodeUpdate(update),
      );

      expect(update.toolsAdded, isEmpty);
      expect(update.toolsRemoved, isEmpty);
      expect(encoded, containsPair('version', 1));
    });

    test('reports unsupported versions without exposing their payload', () {
      final stored = jsonEncode({
        'version': 2,
        'prompt': 'PRIVATE PROMPT',
        'credential': 'private-token',
      });

      expect(
        () => AgentTranscriptContextCodec.decodeUpdate(stored),
        throwsA(
          isA<UnsupportedTranscriptVersionException>()
              .having((error) => error.version, 'version', 2)
              .having(
                (error) => error.toString(),
                'diagnostic',
                allOf(
                  isNot(contains('PRIVATE PROMPT')),
                  isNot(contains('private-token')),
                ),
              ),
        ),
      );
    });

    test('reports malformed payloads without exposing their contents', () {
      final stored = jsonEncode({
        'version': 1,
        'toolsAdded': <Map<String, Object?>>[
          {'description': 'PRIVATE PROMPT'},
        ],
        'toolsRemoved': <String>[],
        'credential': 'private-token',
      });

      expect(
        () => AgentTranscriptContextCodec.decodeUpdate(stored),
        throwsA(
          isA<MalformedTranscriptContextException>().having(
            (error) => error.toString(),
            'diagnostic',
            allOf(
              isNot(contains('PRIVATE PROMPT')),
              isNot(contains('private-token')),
            ),
          ),
        ),
      );
      expect(
        () => AgentTranscriptContextCodec.decodeUpdate('not valid json'),
        throwsA(isA<MalformedTranscriptContextException>()),
      );
    });

    test('requires an integer version field', () {
      for (final version in ['"1"', '1.0']) {
        expect(
          () => AgentTranscriptContextCodec.decodeUpdate(
            '{"version":$version,"toolsAdded":[],"toolsRemoved":[]}',
          ),
          throwsA(isA<MalformedTranscriptContextException>()),
        );
      }
    });
  });
}
