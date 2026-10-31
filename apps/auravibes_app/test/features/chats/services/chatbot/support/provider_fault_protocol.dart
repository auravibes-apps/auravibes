import 'dart:convert';

/// Protocol-specific syntax, shared by all scenarios for the selected adapter.
enum ProviderFaultProtocol {
  chat,
  codex,
  anthropic;

  List<int> start() => this == anthropic
      ? [
          ..._event({
            'type': 'message_start',
            'message': {
              'id': 'msg-contract',
              'type': 'message',
              'role': 'assistant',
              'model': 'contract-model',
              'content': <Object?>[],
              'stop_reason': null,
              'stop_sequence': null,
              'usage': {'input_tokens': 1, 'output_tokens': 0},
            },
          }),
          ..._event({
            'type': 'content_block_start',
            'index': 0,
            'content_block': {'type': 'text', 'text': ''},
          }),
        ]
      : const [];

  List<int> text(String text) => _event(switch (this) {
    chat => {
      'id': 'completion-contract',
      'object': 'chat.completion.chunk',
      'created': 1,
      'model': 'contract-model',
      'choices': [
        {
          'index': 0,
          'delta': {'role': 'assistant', 'content': text},
        },
      ],
    },
    codex => {'type': 'response.output_text.delta', 'delta': text},
    anthropic => {
      'type': 'content_block_delta',
      'index': 0,
      'delta': {'type': 'text_delta', 'text': text},
    },
  });

  List<int> done({bool tool = false}) => switch (this) {
    chat => [
      ..._event({
        'choices': [
          {
            'index': 0,
            'delta': <String, Object?>{},
            'finish_reason': tool ? 'tool_calls' : 'stop',
          },
        ],
      }),
      ...utf8.encode('data: [DONE]\n\n'),
    ],
    codex => _event({'type': 'response.completed'}),
    anthropic => [
      ..._event({'type': 'content_block_stop', 'index': tool ? 1 : 0}),
      ..._event({
        'type': 'message_delta',
        'delta': {
          'stop_reason': tool ? 'tool_use' : 'end_turn',
          'stop_sequence': null,
        },
        'usage': {'output_tokens': 1},
      }),
      ..._event({'type': 'message_stop'}),
    ],
  };

  List<int> tool() => switch (this) {
    chat => [
      ..._event({
        'choices': [
          {
            'index': 0,
            'delta': {
              'tool_calls': [
                {
                  'index': 0,
                  'id': 'call-contract-1',
                  'type': 'function',
                  'function': {
                    'name': 'count_effect',
                    'arguments': '{"value":',
                  },
                },
              ],
            },
          },
        ],
      }),
      ..._event({
        'choices': [
          {
            'index': 0,
            'delta': {
              'tool_calls': [
                {
                  'index': 0,
                  'function': {'arguments': '"one"}'},
                },
              ],
            },
          },
        ],
      }),
    ],
    codex => _event({
      'type': 'response.output_item.done',
      'item': {
        'type': 'function_call',
        'call_id': 'call-contract-1',
        'name': 'count_effect',
        'arguments': '{"value":"one"}',
      },
    }),
    anthropic => [
      ..._event({'type': 'content_block_stop', 'index': 0}),
      ..._event({
        'type': 'content_block_start',
        'index': 1,
        'content_block': {
          'type': 'tool_use',
          'id': 'call-contract-1',
          'name': 'count_effect',
          'input': <String, Object?>{},
        },
      }),
      ..._event({
        'type': 'content_block_delta',
        'index': 1,
        'delta': {'type': 'input_json_delta', 'partial_json': '{"value":'},
      }),
      ..._event({
        'type': 'content_block_delta',
        'index': 1,
        'delta': {'type': 'input_json_delta', 'partial_json': '"one"}'},
      }),
    ],
  };

  List<int> success(String text) => [...start(), ...this.text(text), ...done()];

  List<int> _event(Map<String, Object?> event) => utf8.encode(
    '${this == anthropic ? 'event: ${event['type']}\n' : ''}'
    'data: ${jsonEncode(event)}\n\n',
  );
}
