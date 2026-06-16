import 'package:auravibes_app/domain/enums/credentials_model_type.dart';
import 'package:auravibes_app/services/model_provider_services/model_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nock/nock.dart';

void main() {
  setUpAll(nock.init);
  setUp(nock.cleanAll);

  group('ModelProvider', () {
    test('stores type, key, and optional url', () {
      const provider = ModelProvider(
        type: CredentialsModelType.openai,
        key: 'sk-test',
      );

      expect(provider.type, CredentialsModelType.openai);
      expect(provider.key, 'sk-test');
      expect(provider.url, isNull);
    });

    test('stores custom url', () {
      const provider = ModelProvider(
        type: CredentialsModelType.anthropic,
        key: 'sk-ant-test',
        url: 'https://custom.api.com/v1',
      );

      expect(provider.url, 'https://custom.api.com/v1');
    });

    test('openai type has correct value', () {
      const provider = ModelProvider(
        type: CredentialsModelType.openai,
        key: 'key',
      );

      expect(provider.type.value, 'openai');
    });

    test('anthropic type has correct value', () {
      const provider = ModelProvider(
        type: CredentialsModelType.anthropic,
        key: 'key',
      );

      expect(provider.type.value, 'anthropic');
    });

    test('openrouter type has correct value', () {
      const provider = ModelProvider(
        type: CredentialsModelType.openrouter,
        key: 'key',
      );

      expect(provider.type.value, 'openrouter');
    });

    test('is const constructable', () {
      const provider = ModelProvider(
        type: CredentialsModelType.openai,
        key: 'sk-test',
        url: 'https://custom.api.com',
      );

      expect(provider.type, CredentialsModelType.openai);
      expect(provider.key, 'sk-test');
      expect(provider.url, 'https://custom.api.com');
    });
  });

  group('CredentialsModelType', () {
    test('fromString returns openai for "openai"', () {
      expect(
        CredentialsModelType.fromString('openai'),
        CredentialsModelType.openai,
      );
    });

    test('fromString returns anthropic for "anthropic"', () {
      expect(
        CredentialsModelType.fromString('anthropic'),
        CredentialsModelType.anthropic,
      );
    });

    test('fromString returns openrouter for "openrouter"', () {
      expect(
        CredentialsModelType.fromString('openrouter'),
        CredentialsModelType.openrouter,
      );
    });

    test('fromString is case-insensitive', () {
      expect(
        CredentialsModelType.fromString('OpenAI'),
        CredentialsModelType.openai,
      );
      expect(
        CredentialsModelType.fromString('ANTHROPIC'),
        CredentialsModelType.anthropic,
      );
      expect(
        CredentialsModelType.fromString('OpenRouter'),
        CredentialsModelType.openrouter,
      );
    });

    test('fromString throws for invalid value', () {
      expect(
        () => CredentialsModelType.fromString('invalid'),
        throwsArgumentError,
      );
    });

    test('fromString throws for empty string', () {
      expect(
        () => CredentialsModelType.fromString(''),
        throwsArgumentError,
      );
    });

    test('toString returns value', () {
      expect(CredentialsModelType.openai.toString(), 'openai');
      expect(CredentialsModelType.anthropic.toString(), 'anthropic');
      expect(CredentialsModelType.openrouter.toString(), 'openrouter');
    });

    test('value property returns correct string', () {
      expect(CredentialsModelType.openai.value, 'openai');
      expect(CredentialsModelType.anthropic.value, 'anthropic');
      expect(CredentialsModelType.openrouter.value, 'openrouter');
    });
  });

  group('ModelProviderServices', () {
    test('can be instantiated', () {
      final services = ModelProviderServices();

      expect(services, isNotNull);
    });

    test(
      'getWorkspaceModelSelections with unknown type returns null',
      () async {
        final services = ModelProviderServices();

        final result = await services.getWorkspaceModelSelections(
          const ModelProvider(
            type: CredentialsModelType.google,
            key: 'test-key',
          ),
        );
        expect(result, isNull);
      },
    );

    test('getWorkspaceModelSelections with anthropic returns models', () async {
      nock('https://api.anthropic.com').get('/v1/models')
        ..query({'limit': '1000'})
        ..reply(200, {
          'data': [
            {
              'display_name': 'Claude 3',
              'id': 'claude-3',
              'type': 'model',
              'created_at': '2024-01-01T00:00:00Z',
            },
          ],
          'first_id': 'claude-3',
          'has_more': false,
          'last_id': 'claude-3',
        });

      final service = ModelProviderServices();
      final result = await service.getWorkspaceModelSelections(
        const ModelProvider(
          type: CredentialsModelType.anthropic,
          key: 'test-key',
        ),
      );
      expect(result, isNotNull);
      expect((result ?? fail('Expected result to be non-null')).length, 1);
      expect(result.firstOrNull?.modelId, 'claude-3');
    });

    test('getWorkspaceModelSelections with openai returns models', () async {
      nock('https://api.openai.com').get('/v1/models').reply(200, {
        'object': 'list',
        'data': [
          {
            'id': 'gpt-4',
            'object': 'model',
            'created': 1677649963,
            'owned_by': 'openai',
          },
        ],
      });

      final service = ModelProviderServices();
      final result = await service.getWorkspaceModelSelections(
        const ModelProvider(type: CredentialsModelType.openai, key: 'test-key'),
      );
      expect(result, isNotNull);
      expect((result ?? fail('Expected result to be non-null')).length, 1);
      expect(result.firstOrNull?.modelId, 'gpt-4');
    });

    test(
      'getWorkspaceModelSelections with openrouter returns models',
      () async {
        nock('https://openrouter.ai').get('/api/v1/key').reply(200, {
          'data': {'label': 'test-key'},
        });

        nock('https://openrouter.ai').get('/api/v1/models').reply(200, {
          'data': [
            {
              'id': 'anthropic/claude-sonnet-4',
              'name': 'Claude Sonnet 4',
              'context_length': 200000,
            },
          ],
        });

        final service = ModelProviderServices();
        final result = await service.getWorkspaceModelSelections(
          const ModelProvider(
            type: CredentialsModelType.openrouter,
            key: 'test-key',
          ),
        );
        expect(result, isNotNull);
        expect((result ?? fail('Expected result to be non-null')).length, 1);
        expect(result.firstOrNull?.modelId, 'anthropic/claude-sonnet-4');
      },
    );

    test(
      'getWorkspaceModelSelections with openrouter returns null on bad key',
      () async {
        nock('https://openrouter.ai').get('/api/v1/key').reply(401, {
          'error': {'message': 'Unauthorized'},
        });

        final service = ModelProviderServices();
        final result = await service.getWorkspaceModelSelections(
          const ModelProvider(
            type: CredentialsModelType.openrouter,
            key: 'bad-key',
          ),
        );

        expect(result, isNull);
      },
    );

    test(
      'getWorkspaceModelSelections with openrouter returns null on API error',
      () async {
        nock('https://openrouter.ai').get('/api/v1/key').reply(200, {
          'data': {'label': 'test-key'},
        });

        nock('https://openrouter.ai').get('/api/v1/models').reply(500, {
          'error': {'message': 'Server error'},
        });

        final service = ModelProviderServices();
        final result = await service.getWorkspaceModelSelections(
          const ModelProvider(
            type: CredentialsModelType.openrouter,
            key: 'test-key',
          ),
        );

        expect(result, isNull);
      },
    );

    test(
      'getWorkspaceModelSelections with openrouter returns null on malformed '
      'models response',
      () async {
        nock('https://openrouter.ai').get('/api/v1/key').reply(200, {
          'data': {'label': 'test-key'},
        });

        nock(
          'https://openrouter.ai',
        ).get('/api/v1/models').reply(200, 'not json');

        final service = ModelProviderServices();
        final result = await service.getWorkspaceModelSelections(
          const ModelProvider(
            type: CredentialsModelType.openrouter,
            key: 'test-key',
          ),
        );

        expect(result, isNull);
      },
    );

    test('anthropic models pagination', () async {
      nock('https://api.anthropic.com').get('/v1/models')
        ..query({'limit': '1000', 'after_id': 'page1-id'})
        ..reply(200, {
          'data': [
            {
              'display_name': 'Claude 2',
              'id': 'claude-2',
              'type': 'model',
              'created_at': '2024-02-01T00:00:00Z',
            },
          ],
          'first_id': 'claude-2',
          'has_more': false,
          'last_id': 'claude-2',
        });

      nock('https://api.anthropic.com').get('/v1/models')
        ..query({'limit': '1000'})
        ..reply(200, {
          'data': [
            {
              'display_name': 'Claude 1',
              'id': 'claude-1',
              'type': 'model',
              'created_at': '2024-01-01T00:00:00Z',
            },
          ],
          'first_id': 'claude-1',
          'has_more': true,
          'last_id': 'page1-id',
        });

      final service = ModelProviderServices();
      final result = await service.getWorkspaceModelSelections(
        const ModelProvider(
          type: CredentialsModelType.anthropic,
          key: 'test-key',
        ),
      );
      expect(result, isNotNull);
      expect((result ?? fail('Expected result to be non-null')).length, 2);
      expect(result.firstOrNull?.modelId, 'claude-1');
      expect(result[1].modelId, 'claude-2');
    });
  });
}
