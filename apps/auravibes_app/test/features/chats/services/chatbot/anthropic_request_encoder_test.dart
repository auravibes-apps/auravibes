import 'dart:convert';

import 'package:auravibes_app/features/chats/services/chatbot/anthropic_request_encoder.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';

void main() {
  final tool = ToolSpec(
    name: 'lookup',
    description: 'Lookup',
    inputJsonSchema: const {'type': 'object'},
  );
  final other = ToolSpec(
    name: 'search',
    description: 'Search',
    inputJsonSchema: const {'type': 'object'},
  );
  final initial = AgentTranscriptContextEntry(
    afterMessageId: 'u1',
    update: .new(
      contextMessages: const [
        AgentContextMessage(role: .system, content: 'Stable prompt'),
      ],
      toolsAdded: [tool],
    ),
  );
  Message user(String id) => Message(
    role: .user,
    content: [TextPart(text: id)],
    metadata: {'transcriptMessageId': id},
  );
  final prefix = [
    Message(
      role: .system,
      content: [TextPart(text: 'Current prompt')],
      metadata: {'transcriptContext': true},
    ),
    user('u1'),
  ];
  AnthropicRequestEncoder encoder(
    List<AgentTranscriptContextEntry> entries, {
    bool supported = true,
  }) => AnthropicRequestEncoder(
    supportsPromptCacheMarkers: supported,
    supportsMidConversationSystemMessages: supported,
    supportsToolDeltas: supported,
    entries: entries,
  );
  test('prefix unchanged across positioned tool change', () {
    final before = encoder([initial])
        .encode('claude-opus-5', .new(messages: prefix));
    final update = AgentTranscriptContextEntry(
      afterMessageId: 'u2',
      update: .new(
        contextMessages: const [
          AgentContextMessage(role: .system, content: 'Later prompt'),
        ],
        toolsAdded: [other],
        toolsRemoved: ['lookup'],
      ),
    );
    final after = encoder([initial, update]).encode(
      'claude-opus-5',
      .new(
        messages: [
          ...prefix,
          Message(
            role: .model,
            content: [TextPart(text: 'OK')],
          ),
          user('u2'),
        ],
      ),
    );
    expect(
      jsonEncode(after.request.tools?.map((tool) => tool.toJson()).toList()),
      jsonEncode(before.request.tools?.map((tool) => tool.toJson()).toList()),
    );
    expect(
      jsonEncode(after.request.system?.toJson()),
      jsonEncode(before.request.system?.toJson()),
    );
    expect(
      jsonEncode(after.request.messages.first.toJson()),
      jsonEncode(before.request.messages.first.toJson()),
    );
    expect(after.betas, ['inline-tools-2026-09-15']);
    final blocks = after.request.messages.last.toJson()['content'] as List;
    expect(blocks.map((block) => (block as Map?)?['type']), [
      'text',
      'tool_removal',
      'tool_addition',
    ]);
    expect(
      (blocks.last as Map)['tool'],
      containsPair('type', 'tool_definition'),
    );
    expect(after.request.toJson()['cache_control'], {'type': 'ephemeral'});
  });
  test('unsupported fallback omits advanced fields', () {
    final fallback = encoder([initial], supported: false);
    final encoded = fallback.encode('unknown', .new(messages: prefix));
    expect(encoded.betas, isEmpty);
    expect(encoded.request.toJson(), isNot(contains('cache_control')));
    expect(encoded.request.messages.map((message) => message.role.name), [
      'user',
    ]);
    expect(encoded.request.system?.toJson(), 'Current prompt');
  });
  test('invalid placement fails redacted', () {
    expect(
      () => encoder([]).encode(
        'claude-opus-5',
        .new(
          messages: [
            user('u1'),
            Message(
              role: .model,
              content: [TextPart(text: 'secret')],
            ),
            Message(
              role: .system,
              content: [TextPart(text: 'secret')],
            ),
          ],
        ),
      ),
      throwsA(
        isA<AnthropicRequestException>().having(
          (error) => error.toString(),
          'redacted',
          isNot(contains('secret')),
        ),
      ),
    );
  });
  test('system update is legal after tool results', () {
    final result = encoder([]).encode(
      'claude-opus-5',
      .new(
        messages: [
          user('u1'),
          Message(
            role: .model,
            content: [
              ToolRequestPart(
                toolRequest: .new(ref: 'call', name: 'lookup', input: {}),
              ),
            ],
          ),
          Message(
            role: .tool,
            content: [
              ToolResponsePart(
                toolResponse: .new(ref: 'call', name: 'lookup', output: 'ok'),
              ),
            ],
          ),
          Message(
            role: .system,
            content: [TextPart(text: 'Later prompt')],
          ),
        ],
      ),
    );
    expect(result.request.messages.last.role.name, 'system');
    expect(
      result.request.messages[2].blocks.single.toJson()['type'],
      'tool_result',
    );
  });

  test('system support is independent from tool changes', () {
    final update = AgentTranscriptContextEntry(
      afterMessageId: 'u2',
      update: .new(
        contextMessages: const [
          AgentContextMessage(role: .system, content: 'New prompt'),
        ],
      ),
    );
    final result = AnthropicRequestEncoder(
      supportsMidConversationSystemMessages: true,
      entries: [initial, update],
    ).encode('claude-opus-5', .new(messages: [...prefix, user('u2')]));
    expect(result.request.messages.last.role.name, 'system');
    expect(
      result.request.messages.last.blocks.single.toJson()['text'],
      'New prompt',
    );
    expect(result.betas, isEmpty);
    expect(result.request.toJson(), isNot(contains('cache_control')));
  });

  test('approval-only update does not create empty system message', () {
    final update = AgentTranscriptContextEntry(
      afterMessageId: 'u1',
      update: .new(approvalStates: const {'tool-id': 'denied'}),
    );
    final result = encoder([initial, update])
        .encode('claude-opus-5', .new(messages: prefix));
    expect(result.request.messages.map((message) => message.role.name), [
      'user',
    ]);
    expect(result.betas, isEmpty);
  });

  test('tool redefinition fails closed', () {
    final update = AgentTranscriptContextEntry(
      afterMessageId: 'u2',
      update: .new(
        toolsAdded: [
          ToolSpec(
            name: 'lookup',
            description: 'Changed',
            inputJsonSchema: const {'type': 'object'},
          ),
        ],
        toolsRemoved: ['lookup'],
      ),
    );
    expect(
      () =>
          encoder([initial, update])
              .encode('claude-opus-5', .new(messages: [...prefix, user('u2')])),
      throwsA(isA<AnthropicRequestException>()),
    );
  });
  test('removed initial tool is re-offered by reference', () {
    final removed = AgentTranscriptContextEntry(
      afterMessageId: 'u1',
      update: .new(toolsRemoved: ['lookup']),
    );
    final restored = AgentTranscriptContextEntry(
      afterMessageId: 'u2',
      update: .new(toolsAdded: [tool]),
    );
    final result = encoder([initial, removed, restored]).encode(
      'claude-opus-5',
      .new(
        messages: [
          ...prefix,
          Message(
            role: .model,
            content: [TextPart(text: 'OK')],
          ),
          user('u2'),
        ],
      ),
    );
    expect(result.request.messages.last.blocks.single.toJson(), {
      'type': 'tool_addition',
      'tool': {'type': 'tool_reference', 'name': 'lookup'},
    });
  });

  test('credential requirement changes fail closed', () {
    final changed = AgentTranscriptContextEntry(
      afterMessageId: 'u1',
      update: .new(
        toolsAdded: [
          ToolSpec(
            name: 'lookup',
            description: 'Lookup',
            inputJsonSchema: const {'type': 'object'},
            requiresCredential: true,
          ),
        ],
        toolsRemoved: ['lookup'],
      ),
    );
    expect(
      () =>
          encoder([initial, changed])
              .encode('claude-opus-5', .new(messages: prefix)),
      throwsA(isA<AnthropicRequestException>()),
    );
  });
}
