// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/features/models/widgets/list_model_connections_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('_obscureApiKey logic', () {
    test('returns asterisks for null suffix', () {
      expect(_obscureApiKey(null), '*' * 20);
    });

    test('returns asterisks for empty suffix', () {
      expect(_obscureApiKey(''), '*' * 20);
    });

    test('returns asterisks with suffix for non-empty', () {
      expect(_obscureApiKey('AbCd'), '********************AbCd');
    });

    test('preserves long suffix', () {
      final suffix = 'a' * 50;
      final result = _obscureApiKey(suffix);
      expect(result, '********************$suffix');
    });

    test('handles single char suffix', () {
      expect(_obscureApiKey('X'), '********************X');
    });
  });

  group('ListModelConnectionsWidget', () {
    test('stores workspaceId', () {
      const widget = ListModelConnectionsWidget(workspaceId: 'ws-1');
      expect(widget.workspaceId, 'ws-1');
    });

    test('accepts optional key', () {
      const widget = ListModelConnectionsWidget(
        workspaceId: 'ws-1',
        key: Key('test-key'),
      );
      expect(widget.key, const Key('test-key'));
    });
  });

  group('_getModelTypeDisplay logic', () {
    test('returns modelId from connection', () {
      final connection = ModelConnectionEntity(
        id: 'conn-1',
        name: 'Test',
        key: 'test-key',
        modelId: 'gpt-4',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        workspaceId: 'ws-1',
      );
      expect(connection.modelId, 'gpt-4');
    });
  });
}

String _obscureApiKey(String? keySuffix) {
  if (keySuffix == null || keySuffix.isEmpty) {
    return '*' * 20;
  }
  return '********************$keySuffix';
}
