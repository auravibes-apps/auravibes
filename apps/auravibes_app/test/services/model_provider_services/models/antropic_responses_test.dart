// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
import 'package:auravibes_app/services/model_provider_services/models/antropic_response_models_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AntropicResponseModelsItem', () {
    test('fromJson parses correctly', () {
      final json = {
        'display_name': 'Claude 3.5 Sonnet',
        'id': 'claude-3-5-sonnet',
        'type': 'model',
        'created_at': '2024-01-15T10:30:00Z',
      };

      final item = AntropicResponseModelsItem.fromJson(json);

      expect(item.displayName, 'Claude 3.5 Sonnet');
      expect(item.id, 'claude-3-5-sonnet');
      expect(item.type, 'model');
      expect(item.createdAt, DateTime.parse('2024-01-15T10:30:00Z'));
    });

    test('fromJson handles different values', () {
      final json = {
        'display_name': 'GPT-4',
        'id': 'gpt-4',
        'type': 'model',
        'created_at': '2023-12-01T00:00:00Z',
      };

      final item = AntropicResponseModelsItem.fromJson(json);

      expect(item.id, 'gpt-4');
      expect(item.displayName, 'GPT-4');
    });
  });

  group('AntropicResponseModelsErrorMessage', () {
    test('fromJson parses error message', () {
      final json = {
        'message': 'Invalid API key',
        'type': 'authentication_error',
      };

      final error = AntropicResponseModelsErrorMessage.fromJson(json);

      expect(error.message, 'Invalid API key');
      expect(error.type, 'authentication_error');
    });
  });

  group('AntropicResponseModels', () {
    test('fromJson creates data variant when data field present', () {
      final json = {
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
      };

      final result = AntropicResponseModels.fromJson(json);

      expect(result, isA<AntropicResponseModelsData>());
      final data = result as AntropicResponseModelsData;
      expect(data.data, hasLength(1));
      expect(data.data.first.id, 'claude-3');
      expect(data.hasMore, false);
      expect(data.firstId, 'claude-3');
      expect(data.lastId, 'claude-3');
    });

    test('fromJson creates error variant when error field present', () {
      final json = {
        'error': {
          'message': 'Rate limited',
          'type': 'rate_limit_error',
        },
        'request_id': 'req-123',
        'type': 'error',
      };

      final result = AntropicResponseModels.fromJson(json);

      expect(result, isA<AntropicResponseModelsError>());
      final error = result as AntropicResponseModelsError;
      expect(error.error.message, 'Rate limited');
      expect(error.requestId, 'req-123');
      expect(error.type, 'error');
    });

    test('fromJson throws when neither data nor error present', () {
      final json = {'other_field': 'value'};

      expect(
        () => AntropicResponseModels.fromJson(json),
        throwsA(isA<Exception>()),
      );
    });

    test('fromJson handles hasMore true for pagination', () {
      final json = {
        'data': [
          {
            'display_name': 'Model 1',
            'id': 'model-1',
            'type': 'model',
            'created_at': '2024-01-01T00:00:00Z',
          },
          {
            'display_name': 'Model 2',
            'id': 'model-2',
            'type': 'model',
            'created_at': '2024-01-01T00:00:00Z',
          },
        ],
        'first_id': 'model-1',
        'has_more': true,
        'last_id': 'model-2',
      };

      final result =
          AntropicResponseModels.fromJson(json) as AntropicResponseModelsData;

      expect(result.data, hasLength(2));
      expect(result.hasMore, true);
      expect(result.lastId, 'model-2');
    });
  });
}
