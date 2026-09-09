import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolCallResultStatus.localeKey', () {
    test('each status has a non-empty locale key', () {
      for (final status in ToolCallResultStatus.values) {
        expect(status.localeKey, isNotEmpty);
      }
    });

    test('all locale keys are unique', () {
      final keys = ToolCallResultStatus.values.map((s) => s.localeKey).toSet();
      expect(keys.length, ToolCallResultStatus.values.length);
    });
  });

  group('ToolCallResultStatusConverter', () {
    const converter = ToolCallResultStatusConverter();

    group('fromJson', () {
      test('returns null for null input', () {
        expect(converter.fromJson(null), isNull);
      });

      test('parses all snake_case values', () {
        const cases = {
          'running': ToolCallResultStatus.running,
          'success': ToolCallResultStatus.success,
          'skipped_by_user': ToolCallResultStatus.skippedByUser,
          'stopped_by_user': ToolCallResultStatus.stoppedByUser,
          'tool_not_found': ToolCallResultStatus.toolNotFound,
          'disabled_in_workspace': ToolCallResultStatus.disabledInWorkspace,
          'disabled_in_conversation':
              ToolCallResultStatus.disabledInConversation,
          'disabled_by_agent': ToolCallResultStatus.disabledByAgent,
          'not_configured': ToolCallResultStatus.notConfigured,
          'execution_error': ToolCallResultStatus.executionError,
        };
        cases.forEach((key, value) {
          expect(converter.fromJson(key), value);
        });
      });

      test('returns null for unknown value', () {
        expect(converter.fromJson('unknown_value'), isNull);
      });
    });

    group('toJson', () {
      test('returns null for null input', () {
        expect(converter.toJson(null), isNull);
      });

      test('serializes all values to snake_case', () {
        expect(converter.toJson(.running), 'running');
        expect(converter.toJson(.success), 'success');
        expect(converter.toJson(.skippedByUser), 'skipped_by_user');
        expect(converter.toJson(.stoppedByUser), 'stopped_by_user');
        expect(converter.toJson(.toolNotFound), 'tool_not_found');
        expect(converter.toJson(.disabledInWorkspace), 'disabled_in_workspace');
        expect(
          converter.toJson(.disabledInConversation),
          'disabled_in_conversation',
        );
        expect(converter.toJson(.disabledByAgent), 'disabled_by_agent');
        expect(converter.toJson(.notConfigured), 'not_configured');
        expect(converter.toJson(.executionError), 'execution_error');
      });

      test('round-trip fromJson -> toJson is identity', () {
        for (final status in ToolCallResultStatus.values) {
          final json = converter.toJson(status);
          expect(converter.fromJson(json), status);
        }
      });
    });
  });
}
