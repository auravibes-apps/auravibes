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
}
