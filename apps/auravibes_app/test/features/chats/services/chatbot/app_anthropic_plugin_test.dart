import 'dart:convert';

import 'package:auravibes_app/features/chats/services/chatbot/anthropic_request_encoder.dart';
import 'package:auravibes_app/features/chats/services/chatbot/app_anthropic_plugin.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AgentContextMessage, AgentTranscriptContextEntry, ToolSpec;
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'serialized body preserves text and surfaces reported cache usage',
    () async {
      final requests = <http.Request>[];
      final ai = Genkit(
        plugins: [
          AppAnthropicPlugin(
            apiKey: 'fixture-key',
            encoder: const AnthropicRequestEncoder(
              supportsPromptCacheMarkers: true,
              supportsMidConversationSystemMessages: true,
            ),
            httpClient: MockClient((request) async {
              requests.add(request);

              return http.Response(
                jsonEncode({
                  'id': 'msg_test',
                  'type': 'message',
                  'role': 'assistant',
                  'model': 'claude-opus-5',
                  'content': [
                    {'type': 'text', 'text': 'OK'},
                  ],
                  'stop_reason': 'end_turn',
                  'stop_sequence': null,
                  'usage': {
                    'input_tokens': 5,
                    'output_tokens': 1,
                    'cache_read_input_tokens': 2000,
                    'cache_creation_input_tokens': 20,
                  },
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }),
          ),
        ],
        isDevEnv: false,
      );
      final result = await ai.generate<Object?, Object?>(
        model: modelRef<Object?>('anthropic/claude-opus-5'),
        messages: [
          Message(
            role: .system,
            content: [TextPart(text: 'Stable\n prompt')],
          ),
          Message(
            role: .user,
            content: [TextPart(text: 'Hi')],
          ),
        ],
      );
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['system'], 'Stable\n prompt');
      expect(body['cache_control'], {'type': 'ephemeral'});
      expect(requests.single.headers, isNot(contains('anthropic-beta')));
      expect(result.message?.metadata?['cacheReadInputTokens'], 2000);
      expect(result.message?.metadata?['cacheCreationInputTokens'], 20);
    },
  );
  test('wire prefix and beta header survive adding a new tool', () async {
    final captured = <http.Request>[];
    final initialTool = ToolSpec(
      name: 'lookup',
      description: 'Lookup',
      inputJsonSchema: const {'type': 'object'},
    );
    final addedTool = ToolSpec(
      name: 'search',
      description: 'Search',
      inputJsonSchema: const {'type': 'object'},
    );
    final initial = AgentTranscriptContextEntry(
      afterMessageId: 'u1',
      update: .new(
        contextMessages: const [
          AgentContextMessage(role: .system, content: 'Stable'),
        ],
        toolsAdded: [initialTool],
      ),
    );
    final change = AgentTranscriptContextEntry(
      afterMessageId: 'u2',
      update: .new(toolsAdded: [addedTool], toolsRemoved: ['lookup']),
    );
    for (final changed in [false, true]) {
      final ai = Genkit(
        plugins: [
          AppAnthropicPlugin(
            apiKey: 'fixture-key',
            encoder: .new(
              supportsPromptCacheMarkers: true,
              supportsMidConversationSystemMessages: true,
              supportsToolDeltas: true,
              entries: [initial, if (changed) change],
            ),
            httpClient: MockClient((request) async {
              captured.add(request);

              return http.Response(
                jsonEncode({
                  'id': 'msg_test',
                  'type': 'message',
                  'role': 'assistant',
                  'model': 'claude-opus-5',
                  'content': [
                    {'type': 'text', 'text': 'OK'},
                  ],
                  'stop_reason': 'end_turn',
                  'usage': {
                    'input_tokens': 5,
                    'output_tokens': 1,
                    if (changed) 'cache_read_input_tokens': 2000,
                  },
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }),
          ),
        ],
        isDevEnv: false,
      );
      final result = await ai.generate<Object?, Object?>(
        model: modelRef<Object?>('anthropic/claude-opus-5'),
        messages: [
          Message(
            role: .user,
            content: [TextPart(text: 'First')],
            metadata: {'transcriptMessageId': 'u1'},
          ),
          if (changed) ...[
            Message(
              role: .model,
              content: [TextPart(text: 'OK')],
            ),
            Message(
              role: .user,
              content: [TextPart(text: 'Next')],
              metadata: {'transcriptMessageId': 'u2'},
            ),
          ],
        ],
      );
      expect(
        result.message?.metadata?['cacheReadInputTokens'],
        changed ? 2000 : null,
      );
    }
    final before =
        jsonDecode(captured.firstOrNull?.body ?? '{}') as Map<String, dynamic>;
    final after = jsonDecode(captured.last.body) as Map<String, dynamic>;
    expect(
      utf8.encode(jsonEncode(after['tools'])),
      utf8.encode(jsonEncode(before['tools'])),
    );
    expect(
      utf8.encode(jsonEncode(after['system'])),
      utf8.encode(jsonEncode(before['system'])),
    );
    expect(
      utf8.encode(jsonEncode((after['messages'] as List).first)),
      utf8.encode(jsonEncode((before['messages'] as List).first)),
    );
    expect(captured.firstOrNull?.headers, isNot(contains('anthropic-beta')));
    expect(captured.last.headers['anthropic-beta'], 'inline-tools-2026-09-15');
    expect(((after['messages'] as List).last as Map)['role'], 'system');
  });
  test('stream final response retains cache usage', () async {
    final events = [
      {
        'type': 'message_start',
        'message': {
          'id': 'msg_test',
          'type': 'message',
          'role': 'assistant',
          'model': 'claude-opus-5',
          'content': <Object?>[],
          'stop_reason': null,
          'stop_sequence': null,
          'usage': {
            'input_tokens': 5,
            'output_tokens': 0,
            'cache_read_input_tokens': 2000,
            'cache_creation_input_tokens': 30,
          },
        },
      },
      {
        'type': 'content_block_start',
        'index': 0,
        'content_block': {'type': 'text', 'text': ''},
      },
      {
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'text_delta', 'text': 'OK'},
      },
      {'type': 'content_block_stop', 'index': 0},
      {
        'type': 'message_delta',
        'delta': {'stop_reason': 'end_turn', 'stop_sequence': null},
        'usage': {'output_tokens': 1},
      },
      {'type': 'message_stop'},
    ];
    final ai = Genkit(
      plugins: [
        AppAnthropicPlugin(
          apiKey: 'fixture-key',
          encoder: const .new(),
          httpClient: MockClient(
            (request) async => http.Response(
              events
                  .map(
                    (event) =>
                        'event: ${event['type']}\n'
                        'data: ${jsonEncode(event)}\n\n',
                  )
                  .join(),
              200,
              headers: {'content-type': 'text/event-stream'},
            ),
          ),
        ),
      ],
      isDevEnv: false,
    );
    final stream = ai.generateStream<Object?, Object?>(
      model: modelRef<Object?>('anthropic/claude-opus-5'),
      messages: [
        Message(
          role: .user,
          content: [TextPart(text: 'Hi')],
        ),
      ],
    );
    final chunks = await stream.toList();
    final result = await stream.onResult;
    expect(chunks.map((chunk) => chunk.text).join(), 'OK');
    expect(result.message?.metadata?['cacheReadInputTokens'], 2000);
    expect(result.message?.metadata?['cacheCreationInputTokens'], 30);
  });
}
