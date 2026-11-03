import 'dart:convert';

import 'package:auravibes_app/features/chats/agent_adapters/agent_transcript_context_codec.dart';
import 'package:auravibes_app/features/chats/agent_adapters/agent_transcript_context_decode_exception.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentTranscriptContextCodec', () {
    test('reads v1 context with unknown provenance', () {
      const stored = '''
        {"version":1,"toolsAdded":[],"toolsRemoved":[],"contextMessages":[
          {"role":"system","content":"LEGACY_SENTINEL","kind":"skill_context"}
        ]}
      ''';

      final update = AgentTranscriptContextCodec.decodeUpdate(stored);

      expect(update.toolsAdded, isEmpty);
      expect(update.toolsRemoved, isEmpty);
      expect(
        update.contextMessages?.single.provenance,
        AgentContextProvenance.unknown,
      );
      expect(update.contextMessages?.single.content, 'LEGACY_SENTINEL');
    });

    test(
      'round trips v2 provenance without copying content into provenance',
      () {
        final update = AgentTranscriptContextUpdate(
          contextMessages: const [
            AgentContextMessage(
              role: .system,
              content: 'SYSTEM_CONTEXT_SENTINEL',
              provenance: AgentContextProvenance.applicationPrompt,
            ),
            AgentContextMessage(
              role: .skill,
              content: 'IMPORTED_SKILL_SENTINEL',
              kind: 'skill_context',
              provenance: AgentContextProvenance.importedSkill,
            ),
          ],
        );
        final encoded = jsonDecode(
          AgentTranscriptContextCodec.encodeUpdate(update),
        ) as Map<String, dynamic>;
        final messages = encoded['contextMessages'] as List<dynamic>;
        final system = messages[0] as Map<String, dynamic>;
        final imported = messages[1] as Map<String, dynamic>;

        expect(encoded, containsPair('version', 2));
        expect(system['provenance'], {
          'origin': 'applicationPrompt',
          'trust': 'appControlled',
        });
        expect(imported['provenance'], {
          'origin': 'importedSkill',
          'trust': 'externalUntrusted',
        });
        expect(
          system['provenance'],
          isNot(contains('SYSTEM_CONTEXT_SENTINEL')),
        );
        expect(
          imported['provenance'],
          isNot(contains('IMPORTED_SKILL_SENTINEL')),
        );

        final decoded = AgentTranscriptContextCodec.decodeUpdate(
          jsonEncode(encoded),
        );
        expect(decoded.contextMessages?.map((message) => message.provenance), [
          AgentContextProvenance.applicationPrompt,
          AgentContextProvenance.importedSkill,
        ]);
      },
    );

    test('malformed v2 provenance decodes unknown', () {
      const stored = '''
        {"version":2,"toolsAdded":[],"toolsRemoved":[],"contextMessages":[
          {"role":"system","content":"UNTRUSTED_SENTINEL","provenance":{
            "origin":"applicationPrompt","trust":"externalUntrusted"
          }}
        ]}
      ''';

      final update = AgentTranscriptContextCodec.decodeUpdate(stored);

      expect(
        update.contextMessages?.single.provenance,
        AgentContextProvenance.unknown,
      );
      expect(update.contextMessages?.single.content, 'UNTRUSTED_SENTINEL');
    });

    test('reports unsupported versions without exposing their payload', () {
      final stored = jsonEncode({
        'version': 3,
        'prompt': 'PRIVATE PROMPT',
        'credential': 'private-token',
      });

      expect(
        () => AgentTranscriptContextCodec.decodeUpdate(stored),
        throwsA(
          isA<UnsupportedTranscriptVersionException>()
              .having((error) => error.version, 'version', 3)
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
