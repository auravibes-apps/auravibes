import 'package:auravibes_app/features/models/models/add_model_provider_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddModelProviderModel.validateName', () {
    test('returns null for valid name', () {
      const model = AddModelProviderModel(name: 'My Provider');
      expect(model.validateName(), isNull);
    });

    test('returns error for null name', () {
      const model = AddModelProviderModel();
      expect(model.validateName(), 'Name is required');
    });

    test('returns error for empty name', () {
      const model = AddModelProviderModel(name: '');
      expect(model.validateName(), 'Name is required');
    });

    test('returns error for whitespace-only name', () {
      const model = AddModelProviderModel(name: '   ');
      expect(model.validateName(), 'Name is required');
    });

    test('returns error for name too short', () {
      const model = AddModelProviderModel(name: 'A');
      expect(model.validateName(), 'Name must be at least 2 characters');
    });

    test('returns error for name too long', () {
      final model = AddModelProviderModel(name: 'A' * 51);
      expect(model.validateName(), 'Name must be less than 50 characters');
    });

    test('trims whitespace before validation', () {
      const model = AddModelProviderModel(name: '  ab  ');
      expect(model.validateName(), isNull);
    });

    test('accepts exactly 2 character name', () {
      const model = AddModelProviderModel(name: 'ab');
      expect(model.validateName(), isNull);
    });

    test('accepts exactly 50 character name', () {
      final model = AddModelProviderModel(name: 'A' * 50);
      expect(model.validateName(), isNull);
    });
  });

  group('AddModelProviderModel.validateKey', () {
    test('returns null for valid API key', () {
      const model = AddModelProviderModel(key: 'sk-1234567890');
      expect(model.validateKey(), isNull);
    });

    test('returns error for null key', () {
      const model = AddModelProviderModel();
      expect(model.validateKey(), 'API key is required');
    });

    test('returns error for empty key', () {
      const model = AddModelProviderModel(key: '');
      expect(model.validateKey(), 'API key is required');
    });

    test('returns error for whitespace-only key', () {
      const model = AddModelProviderModel(key: '     ');
      expect(model.validateKey(), 'API key is required');
    });

    test('returns error for key too short', () {
      const model = AddModelProviderModel(key: 'abc');
      expect(model.validateKey(), 'API key appears to be too short');
    });

    test('accepts exactly 5 character key', () {
      const model = AddModelProviderModel(key: '12345');
      expect(model.validateKey(), isNull);
    });
  });

  group('AddModelProviderModel.validateModelId', () {
    test('returns null for valid model ID', () {
      const model = AddModelProviderModel(modelId: 'openai');
      expect(model.validateModelId(), isNull);
    });

    test('returns error for null model ID', () {
      const model = AddModelProviderModel();
      expect(model.validateModelId(), 'Please select a model provider');
    });
  });

  group('AddModelProviderModel.validateUrl', () {
    test('returns null for null URL (optional)', () {
      const model = AddModelProviderModel();
      expect(model.validateUrl(), isNull);
    });

    test('returns null for empty URL (optional)', () {
      const model = AddModelProviderModel(url: '');
      expect(model.validateUrl(), isNull);
    });

    test('returns null for localhost HTTP URL', () {
      const model = AddModelProviderModel(url: 'http://localhost:8080');
      expect(model.validateUrl(), isNull);
    });

    test('returns null for loopback HTTP URL', () {
      const model = AddModelProviderModel(url: 'http://127.0.0.1:8080');
      expect(model.validateUrl(), isNull);
    });

    test('returns null for IPv6 loopback HTTP URL', () {
      const model = AddModelProviderModel(url: 'http://[::1]:8080');
      expect(model.validateUrl(), isNull);
    });

    test('returns null for localhost subdomain HTTP URL', () {
      const model = AddModelProviderModel(url: 'http://foo.localhost:8080');
      expect(model.validateUrl(), isNull);
    });

    test('returns null for valid HTTPS URL', () {
      const model = AddModelProviderModel(url: 'https://api.example.com');
      expect(model.validateUrl(), isNull);
    });

    test('returns error for remote HTTP URL', () {
      const model = AddModelProviderModel(url: 'http://api.example.com');
      expect(model.validateUrl(), 'Remote URLs must use https://');
    });

    test('returns error for URL without scheme', () {
      const model = AddModelProviderModel(url: 'api.example.com');
      expect(model.validateUrl(), 'URL must start with http:// or https://');
    });

    test('returns error for invalid URL format', () {
      const model = AddModelProviderModel(url: 'http://');
      expect(model.validateUrl(), 'Please enter a valid URL');
    });

    test('returns error for URL with colon but no valid host', () {
      const model = AddModelProviderModel(url: 'http://:');
      expect(model.validateUrl(), 'Please enter a valid URL');
    });
  });

  group('AddModelProviderModel.isValid', () {
    test('returns true when all fields are valid', () {
      const model = AddModelProviderModel(
        name: 'My Provider',
        modelId: 'openai',
        key: 'sk-1234567890',
      );
      expect(model.isValid(), isTrue);
    });

    test('returns false when name is invalid', () {
      const model = AddModelProviderModel(
        name: 'A',
        modelId: 'openai',
        key: 'sk-1234567890',
      );
      expect(model.isValid(), isFalse);
    });

    test('returns false when key is invalid', () {
      const model = AddModelProviderModel(
        name: 'My Provider',
        modelId: 'openai',
        key: 'abc',
      );
      expect(model.isValid(), isFalse);
    });

    test('returns false when modelId is invalid', () {
      const model = AddModelProviderModel(
        name: 'My Provider',
        key: 'sk-1234567890',
      );
      expect(model.isValid(), isFalse);
    });

    test('returns false when URL is invalid', () {
      const model = AddModelProviderModel(
        name: 'My Provider',
        modelId: 'openai',
        key: 'sk-1234567890',
        url: 'invalid-url',
      );
      expect(model.isValid(), isFalse);
    });
  });
}
