import 'package:auravibes_app/domain/entities/api_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiModelEntity.fromJson', () {
    final baseJson = <String, dynamic>{
      'id': 'gpt-4',
      'name': 'GPT-4',
      'open_weights': false,
      'cost': {
        'input': 30.0,
        'output': 60.0,
        'cache_read': 15.0,
      },
      'limit': {
        'context': 128000,
        'output': 4096,
      },
      'modalities': {
        'input': ['text', 'image'],
        'output': ['text'],
      },
    };

    test('parses basic fields', () {
      final model = ApiModelEntity.fromJson('openai', baseJson);
      expect(model.modelProvider, 'openai');
      expect(model.id, 'gpt-4');
      expect(model.name, 'GPT-4');
    });

    test('parses cost fields as doubles', () {
      final model = ApiModelEntity.fromJson('openai', baseJson);
      expect(model.costInput, 30.0);
      expect(model.costOutput, 60.0);
      expect(model.costCacheRead, 15.0);
    });

    test('parses limit fields', () {
      final model = ApiModelEntity.fromJson('openai', baseJson);
      expect(model.limitContext, 128000);
      expect(model.limitOutput, 4096);
    });

    test('parses modalities', () {
      final model = ApiModelEntity.fromJson('openai', baseJson);
      expect(model.modalitiesInput, ['text', 'image']);
      expect(model.modalitiesOuput, ['text']);
    });

    test('parses openWeights', () {
      final model = ApiModelEntity.fromJson('openai', baseJson);
      expect(model.openWeights, false);
    });

    test('parses reasoning support flag', () {
      final model = ApiModelEntity.fromJson('openai', {
        ...baseJson,
        'reasoning': true,
      });
      expect(model.supportsReasoning, isTrue);
    });

    test('defaults reasoning support to false', () {
      final model = ApiModelEntity.fromJson('openai', baseJson);
      expect(model.supportsReasoning, isFalse);
    });

    test('handles missing cost with nullable types', () {
      final json = <String, dynamic>{
        'id': 'free-model',
        'name': 'Free',
        'open_weights': true,
        'limit': {'context': 8000, 'output': 2048},
        'modalities': {
          'input': ['text'],
          'output': ['text'],
        },
      };
      final model = ApiModelEntity.fromJson('openai', json);
      expect(model.costInput, isNull);
      expect(model.costOutput, isNull);
      expect(model.costCacheRead, isNull);
    });

    test('handles missing modalities with defaults', () {
      final json = <String, dynamic>{
        'id': 'minimal',
        'name': 'Minimal',
        'open_weights': null,
        'limit': {'context': 4000, 'output': 1000},
        'modalities': <String, dynamic>{},
      };
      final model = ApiModelEntity.fromJson('openai', json);
      expect(model.modalitiesInput, <String>[]);
      expect(model.modalitiesOuput, <String>[]);
    });
  });

  group('ApiModelEntity computed properties', () {
    ApiModelEntity modelWith(int limitContext) {
      return ApiModelEntity(
        modelProvider: 'openai',
        id: 'test',
        name: 'Test',
        limitContext: limitContext,
        limitOutput: 1000,
        modalitiesInput: [],
        modalitiesOuput: [],
      );
    }

    test('isOpenSource returns openWeights or false', () {
      expect(modelWith(8000).isOpenSource, isFalse);
      const open = ApiModelEntity(
        modelProvider: 'openai',
        id: 'test',
        name: 'Test',
        limitContext: 8000,
        limitOutput: 1000,
        modalitiesInput: [],
        modalitiesOuput: [],
        openWeights: true,
      );
      expect(open.isOpenSource, isTrue);
    });

    test('hasLargeContext > 100k', () {
      expect(modelWith(100000).hasLargeContext, isFalse);
      expect(modelWith(100001).hasLargeContext, isTrue);
      expect(modelWith(200000).hasLargeContext, isTrue);
    });

    test('hasVeryLargeContext > 1M', () {
      expect(modelWith(1000000).hasVeryLargeContext, isFalse);
      expect(modelWith(1000001).hasVeryLargeContext, isTrue);
    });

    test('contextCategory returns correct categories', () {
      expect(modelWith(2000).contextCategory, 'Small');
      expect(modelWith(8000).contextCategory, 'Medium');
      expect(modelWith(64000).contextCategory, 'Large');
      expect(modelWith(200000).contextCategory, 'Very Large');
      expect(modelWith(2000000).contextCategory, 'Massive');
    });
  });
}
