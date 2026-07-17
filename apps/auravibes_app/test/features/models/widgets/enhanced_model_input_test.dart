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
        const TestableApp(
          child: Scaffold(
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
}
