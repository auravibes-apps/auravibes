import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModelProvidersType', () {
    test('openai has value openai', () {
      expect(ModelProvidersType.openai.value, 'openai');
    });
    test('anthropic has value anthropic', () {
      expect(ModelProvidersType.anthropic.value, 'anthropic');
    });
  });

  group('ApiModelProviderEntity.fromJson', () {
    test('parses openai provider', () {
      final json = <String, dynamic>{
        'id': 'openai',
        'name': 'OpenAI',
        'npm': '@ai-sdk/openai-compatible',
        'api': 'https://api.openai.com/v1',
        'doc': 'https://platform.openai.com/docs',
      };
      final provider = ApiModelProviderEntity.fromJson(json);
      expect(provider.id, 'openai');
      expect(provider.name, 'OpenAI');
      expect(provider.type, ModelProvidersType.openai);
      expect(provider.url, 'https://api.openai.com/v1');
      expect(provider.doc, 'https://platform.openai.com/docs');
      expect(provider.hasUrl, isTrue);
      expect(provider.hasDocumentation, isTrue);
    });

    test('parses anthropic provider', () {
      final json = <String, dynamic>{
        'id': 'anthropic',
        'name': 'Anthropic',
        'npm': '@ai-sdk/anthropic',
      };
      final provider = ApiModelProviderEntity.fromJson(json);
      expect(provider.type, ModelProvidersType.anthropic);
    });

    test('returns null type for unknown npm', () {
      final json = <String, dynamic>{
        'id': 'unknown',
        'name': 'Unknown',
        'npm': '@unknown/sdk',
      };
      final provider = ApiModelProviderEntity.fromJson(json);
      expect(provider.type, isNull);
    });

    test('returns null type when npm is missing', () {
      final json = <String, dynamic>{
        'id': 'custom',
        'name': 'Custom',
      };
      final provider = ApiModelProviderEntity.fromJson(json);
      expect(provider.type, isNull);
    });

    test('hasUrl false when url is null', () {
      final json = <String, dynamic>{'id': 'p', 'name': 'P'};
      final provider = ApiModelProviderEntity.fromJson(json);
      expect(provider.hasUrl, isFalse);
    });

    test('hasUrl false when url is empty', () {
      final json = <String, dynamic>{
        'id': 'p',
        'name': 'P',
        'api': '',
      };
      final provider = ApiModelProviderEntity.fromJson(json);
      expect(provider.hasUrl, isFalse);
    });

    test('hasDocumentation false when doc is null or empty', () {
      var json = <String, dynamic>{'id': 'p', 'name': 'P'};
      var provider = ApiModelProviderEntity.fromJson(json);
      expect(provider.hasDocumentation, isFalse);

      json = <String, dynamic>{'id': 'p', 'name': 'P', 'doc': ''};
      provider = ApiModelProviderEntity.fromJson(json);
      expect(provider.hasDocumentation, isFalse);
    });
  });
}
