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

  test('builds provider authorization headers', () {
    expect(providerAuthorizationHeaders('anthropic', 'key'), {
      'x-api-key': 'key',
      'anthropic-version': '2023-06-01',
    });
    expect(providerAuthorizationHeaders('openai-codex', 'token'), {
      'authorization': 'Bearer token',
      'originator': 'auravibes',
      'user-agent': 'AuraVibes',
    });
    expect(providerAuthorizationHeaders('openai', 'token'), {
      'authorization': 'Bearer token',
    });
  });

  test('builds provider model catalog URIs', () {
    expect(
      providerModelCatalogUri(
        'anthropic',
        Uri.parse('https://api.anthropic.com/v1/'),
        maxModels: 5,
      ),
      Uri.parse('https://api.anthropic.com/v1/models?limit=5'),
    );
    expect(
      providerModelCatalogUri(
        'openai',
        Uri.parse('https://api.openai.com/v1'),
        maxModels: 5,
      ),
      Uri.parse('https://api.openai.com/v1/models'),
    );
  });
}
