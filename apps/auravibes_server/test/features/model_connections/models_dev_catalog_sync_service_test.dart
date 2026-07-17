import 'package:auravibes_server/src/features/model_connections/services/models_dev_catalog_sync_service.dart';
import 'package:test/test.dart';

void main() {
  test('loads all providers and models through the injected fetcher', () async {
    Uri? requestedUri;
    final catalog = await ModelsDevCatalogSyncService(
      fetch: (uri) async {
        requestedUri = uri;
        return {
          'openai': {
            'id': 'openai',
            'name': 'OpenAI',
            'npm': '@ai-sdk/openai',
            'api': 'https://api.openai.com/v1',
            'doc': 'https://platform.openai.com/docs',
            'models': {
              'gpt-test': {'id': 'gpt-test', 'name': 'GPT Test'},
              'gpt-mini': {'id': 'gpt-mini'},
            },
          },
          'anthropic': {
            'id': 'anthropic',
            'name': 'Anthropic',
            'models': {
              'claude-test': {'id': 'claude-test', 'name': 'Claude Test'},
            },
          },
        };
      },
    ).load();

    expect(requestedUri, ModelsDevCatalogSyncService.uri);
    expect(catalog.providers, hasLength(2));
    expect(catalog.providers.first.type, '@ai-sdk/openai');
    expect(catalog.models, hasLength(3));
    expect(catalog.models[1].name, 'gpt-mini');
  });

  test('parses model metadata and defaults absent optional fields', () {
    final catalog = ModelsDevCatalog.parse({
      'openai': {
        'id': 'openai',
        'models': {
          'gpt-test': {
            'id': 'gpt-test',
            'limit': {'context': 128000, 'output': 16384},
            'modalities': {
              'input': ['text', 'image'],
              'output': ['text'],
            },
            'family': 'gpt',
            'cost': {'input': 2, 'cache_read': 0.5, 'output': 8},
            'open_weights': false,
            'reasoning': true,
            'experimental': {
              'modes': {
                'fast': {
                  'provider': {
                    'body': {'service_tier': 'priority'},
                  },
                },
              },
            },
            'tool_call': true,
          },
          'minimal': {'id': 'minimal'},
        },
      },
    });

    final model = catalog.models.first;
    expect(model.limitContext, 128000);
    expect(model.limitOutput, 16384);
    expect(model.modalitiesInput, ['text', 'image']);
    expect(model.costCacheRead, 0.5);
    expect(model.supportsPriorityMode, isTrue);
    expect(model.supportsToolCalls, isTrue);
    final minimal = catalog.models.last;
    expect(minimal.limitContext, 0);
    expect(minimal.modalitiesInput, isEmpty);
    expect(minimal.costOutput, 0);
    expect(minimal.openWeights, isFalse);
  });

  test('rejects malformed catalogs before any replacement can occur', () {
    expect(
      () => ModelsDevCatalog.parse({
        'openai': {
          'id': 'openai',
          'models': {
            'gpt-test': {'id': 'different-id'},
          },
        },
      }),
      throwsFormatException,
    );
    expect(() => ModelsDevCatalog.parse({}), throwsFormatException);
    expect(
      () => ModelsDevCatalog.parse({
        'openai': {
          'id': 'openai',
          'models': {
            'gpt-test': {
              'id': 'gpt-test',
              'limit': {'context': 1.5},
            },
          },
        },
      }),
      throwsFormatException,
    );
    expect(
      () => ModelsDevCatalog.parse({
        'openai': {
          'id': 'openai',
          'models': {
            'gpt-test': {
              'id': 'gpt-test',
              'cost': {'input': '2'},
            },
          },
        },
      }),
      throwsFormatException,
    );
  });
}
