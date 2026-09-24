import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('parses model capabilities and eligibility', () {
    final model = ModelCapabilities.fromJson(
      'openai',
      {
        'id': 'gpt-5.5',
        'name': 'GPT-5.5',
        'family': 'gpt-5.5',
        'reasoning': true,
        'tool_call': true,
        'open_weights': false,
        'cost': {'input': 30, 'cache_read': 15, 'output': 60},
        'limit': {'context': 400000, 'output': 128000},
        'modalities': {
          'input': ['TEXT', 'image'],
          'output': ['TEXT'],
        },
        'experimental': {
          'modes': {
            'fast': {
              'provider': {
                'body': {'service_tier': 'priority'},
              },
            },
          },
        },
      },
      {'openai/gpt-5.5'},
    );

    expect(model.inputModalities, ['text', 'image']);
    expect(model.outputModalities, ['text']);
    expect(model.costInput, 30.0);
    expect(model.supportsReasoning, isTrue);
    expect(model.supportsToolCalls, isTrue);
    expect(model.supportsPriorityMode, isTrue);
    expect(model.isTextGenerationModel, isTrue);
    expect(model.isCodexRuntimeModel, isTrue);
    expect(() => model.inputModalities.add('audio'), throwsUnsupportedError);
  });

  test('parses reasoning options and derives legacy toggle', () {
    final model = ModelCapabilities.fromJson('openai', {
      'id': 'gpt-5',
      'name': 'GPT-5',
      'reasoning_options': [
        {'type': 'toggle'},
        {
          'type': 'effort',
          'values': ['low', 'medium', 'high'],
        },
        {'type': 'budget_tokens', 'min': 1024, 'max': 32768},
        {'type': 'future_mode', 'value': 'preserve'},
      ],
      'limit': {'context': 1000, 'output': 100},
      'modalities': {
        'input': ['text'],
        'output': ['text'],
      },
    });

    expect(model.supportsReasoning, isTrue);
    expect(model.reasoningOptions.map((option) => option.type), [
      'toggle',
      'effort',
      'budget_tokens',
      'future_mode',
    ]);
    expect(model.reasoningOptions[1].values, ['low', 'medium', 'high']);
    expect(model.reasoningOptions[2].min, 1024);
    expect(model.reasoningOptions[2].max, 32768);

    final legacy = ModelCapabilities.fromJson('openai', {
      'id': 'legacy',
      'name': 'Legacy',
      'reasoning': true,
      'limit': {'context': 1000, 'output': 100},
      'modalities': {
        'input': ['text'],
        'output': ['text'],
      },
    });
    expect(legacy.reasoningOptions.single.isToggle, isTrue);
  });

  test(
    'ignores malformed reasoning options while preserving unknown types',
    () {
      final model = ModelCapabilities.fromJson('openai', {
        'id': 'gpt',
        'name': 'GPT',
        'reasoning_options': [
          {'type': 'effort'},
          {'type': 'budget_tokens', 'min': 4, 'max': 2},
          {'type': 'future_mode'},
        ],
        'limit': {'context': 1000, 'output': 100},
        'modalities': {
          'input': ['text'],
          'output': ['text'],
        },
      });

      expect(model.reasoningOptions.single.type, 'future_mode');
    },
  );

  test('rejects malformed required catalog fields clearly', () {
    expect(
      () => ModelCapabilities.fromJson('openai', {
        'id': 'gpt-5.5',
        'name': 'GPT-5.5',
        'modalities': {
          'input': ['text'],
          'output': ['text'],
        },
      }),
      throwsFormatException,
    );
    expect(
      () => ModelCapabilities.fromJson('openai', {
        'id': 'gpt-5.5',
        'name': 'GPT-5.5',
        'limit': {'context': '400000', 'output': 128000},
        'modalities': {
          'input': ['text'],
          'output': ['text'],
        },
      }),
      throwsFormatException,
    );
  });

  test('rejects malformed modality values clearly', () {
    expect(
      () => ModelCapabilities.fromJson('openai', {
        'id': 'gpt-5.5',
        'name': 'GPT-5.5',
        'limit': {'context': 400000, 'output': 128000},
        'modalities': {
          'input': ['text', 1],
          'output': ['text'],
        },
      }),
      throwsFormatException,
    );
  });

  test('requires priority mode for Codex runtime eligibility', () {
    final model = ModelCapabilities(
      id: 'gpt-5.5',
      name: 'GPT-5.5',
      limitContext: 400000,
      limitOutput: 128000,
      inputModalities: ['text'],
      outputModalities: ['text'],
    );

    expect(model.isCodexRuntimeModel, isFalse);
  });
}
