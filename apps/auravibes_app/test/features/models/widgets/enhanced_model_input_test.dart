// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.

import 'package:auravibes_app/features/models/models/add_model_provider_model.dart';
import 'package:auravibes_app/features/models/widgets/enhanced_model_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../helpers/test_app.dart';

void main() {
  group('ModelInputFieldType', () {
    test('has name, key, url values', () {
      expect(ModelInputFieldType.values, contains(ModelInputFieldType.name));
      expect(ModelInputFieldType.values, contains(ModelInputFieldType.key));
      expect(ModelInputFieldType.values, contains(ModelInputFieldType.url));
    });

    test('has exactly 3 values', () {
      expect(ModelInputFieldType.values.length, 3);
    });

    test('name index is 0', () {
      expect(ModelInputFieldType.name.index, 0);
    });

    test('key index is 1', () {
      expect(ModelInputFieldType.key.index, 1);
    });

    test('url index is 2', () {
      expect(ModelInputFieldType.url.index, 2);
    });
  });

  group('EnhancedModelInput', () {
    test('constructor sets required properties', () {
      const widget = EnhancedModelInput(
        workspaceId: 'ws-1',
        fieldType: ModelInputFieldType.name,
      );
      expect(widget.workspaceId, 'ws-1');
      expect(widget.fieldType, ModelInputFieldType.name);
      expect(widget.focusNode, isNull);
      expect(widget.onSubmitted, isNull);
    });

    test('constructor accepts all field types', () {
      for (final type in ModelInputFieldType.values) {
        final widget = EnhancedModelInput(
          workspaceId: 'ws-1',
          fieldType: type,
        );
        expect(widget.fieldType, type);
      }
    });

    test('constructor accepts optional params', () {
      final focusNode = FocusNode();
      void onSubmitted() {
        final _ = Object();
      }

      final widget = EnhancedModelInput(
        workspaceId: 'ws-1',
        fieldType: ModelInputFieldType.key,
        focusNode: focusNode,
        onSubmitted: onSubmitted,
      );
      expect(widget.focusNode, focusNode);
      expect(widget.onSubmitted, onSubmitted);
    });

    test('constructor accepts key', () {
      const widget = EnhancedModelInput(
        workspaceId: 'ws-1',
        fieldType: ModelInputFieldType.url,
        key: Key('test'),
      );
      expect(widget.key, const Key('test'));
    });

    test('is a HookConsumerWidget', () {
      const widget = EnhancedModelInput(
        workspaceId: 'ws-1',
        fieldType: ModelInputFieldType.name,
      );
      expect(widget, isA<HookConsumerWidget>());
    });

    test('is const constructable', () {
      const widget = EnhancedModelInput(
        workspaceId: 'ws-1',
        fieldType: ModelInputFieldType.name,
      );
      expect(widget.workspaceId, 'ws-1');
    });

    testWidgets('renders validation error and hint', (tester) async {
      await tester.pumpWidget(
        testableApp(
          child: const Scaffold(
            body: EnhancedModelInput(
              workspaceId: 'ws-1',
              fieldType: ModelInputFieldType.name,
            ),
          ),
        ),
      );
      final pumpCount = await tester.pumpAndSettle();
      expect(pumpCount, isNonNegative);

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });
  });

  group('AddModelProviderModel', () {
    test('defaults are null', () {
      const model = AddModelProviderModel();
      expect(model.name, isNull);
      expect(model.modelId, isNull);
      expect(model.key, isNull);
      expect(model.url, isNull);
    });

    test('copyWith works', () {
      const model = AddModelProviderModel();
      final updated = model.copyWith(name: 'Test', key: 'secret');
      expect(updated.name, 'Test');
      expect(updated.key, 'secret');
      expect(updated.url, isNull);
    });

    test('validateName returns error for null', () {
      const model = AddModelProviderModel();
      expect(model.validateName(), 'Name is required');
    });

    test('validateName returns error for empty', () {
      const model = AddModelProviderModel(name: '');
      expect(model.validateName(), 'Name is required');
    });

    test('validateName returns error for short name', () {
      const model = AddModelProviderModel(name: 'a');
      expect(model.validateName(), 'Name must be at least 2 characters');
    });

    test('validateName returns null for valid name', () {
      const model = AddModelProviderModel(name: 'Valid Name');
      expect(model.validateName(), isNull);
    });

    test('validateName returns error for long name', () {
      final model = AddModelProviderModel(name: 'a' * 51);
      expect(model.validateName(), 'Name must be less than 50 characters');
    });

    test('validateKey returns error for null', () {
      const model = AddModelProviderModel();
      expect(model.validateKey(), 'API key is required');
    });

    test('validateKey returns error for short key', () {
      const model = AddModelProviderModel(key: 'abc');
      expect(model.validateKey(), 'API key appears to be too short');
    });

    test('validateKey returns null for valid key', () {
      const model = AddModelProviderModel(key: 'sk-12345');
      expect(model.validateKey(), isNull);
    });

    test('validateModelId returns error for null', () {
      const model = AddModelProviderModel();
      expect(model.validateModelId(), 'Please select a model provider');
    });

    test('validateModelId returns null for valid', () {
      const model = AddModelProviderModel(modelId: 'openai');
      expect(model.validateModelId(), isNull);
    });

    test('validateUrl returns null for null url', () {
      const model = AddModelProviderModel();
      expect(model.validateUrl(), isNull);
    });

    test('validateUrl returns null for empty url', () {
      const model = AddModelProviderModel(url: '');
      expect(model.validateUrl(), isNull);
    });

    test('validateUrl returns error for invalid scheme', () {
      const model = AddModelProviderModel(url: 'ftp://example.com');
      expect(model.validateUrl(), 'URL must start with http:// or https://');
    });

    test('validateUrl returns error for invalid url', () {
      const model = AddModelProviderModel(url: 'https://');
      expect(model.validateUrl(), 'Please enter a valid URL');
    });

    test('validateUrl returns null for valid url', () {
      const model = AddModelProviderModel(url: 'https://api.openai.com');
      expect(model.validateUrl(), isNull);
    });

    test('validateUrl returns error for remote http url', () {
      const model = AddModelProviderModel(url: 'http://api.openai.com');
      expect(model.validateUrl(), 'Remote URLs must use https://');
    });

    test('isValid returns false for empty model', () {
      const model = AddModelProviderModel();
      expect(model.isValid(), isFalse);
    });

    test('isValid returns true for complete valid model', () {
      const model = AddModelProviderModel(
        name: 'Test',
        modelId: 'openai',
        key: 'sk-12345',
      );
      expect(model.isValid(), isTrue);
    });
  });
}
