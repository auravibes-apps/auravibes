import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('profiles and parses provider model IDs', () {
    expect(providerProfile('openai').defaultUrl, 'https://api.openai.com/v1');
    expect(
      parseProviderModelIds({
        'data': [
          {'id': 'gpt'},
        ],
      }, maxModels: 1),
      ['gpt'],
    );
    expect(() => providerProfile('nope'), throwsFormatException);
  });

  test('selects provider runtime without credentials or transport', () {
    expect(
      selectProviderRuntime(
        providerId: 'openai',
        hasCustomUrl: true,
        supportsReasoning: true,
        usesOAuth: false,
        isCodexOAuth: false,
        modelId: 'model',
      ).runtime,
      ProviderRuntime.openAiReasoning,
    );
  });
}
