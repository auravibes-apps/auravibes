import 'package:auravibes_app/domain/enums/tool_call_result_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolCallResultStatus.toResponseString', () {
    test('success returns empty string', () {
      expect(ToolCallResultStatus.success.toResponseString(), '');
    });

    test('skippedByUser', () {
      expect(
        ToolCallResultStatus.skippedByUser.toResponseString(),
        'Tool was skipped by the user.',
      );
    });

    test('stoppedByUser', () {
      expect(
        ToolCallResultStatus.stoppedByUser.toResponseString(),
        'Tool execution was stopped by the user.',
      );
    });

    test('toolNotFound', () {
      expect(
        ToolCallResultStatus.toolNotFound.toResponseString(),
        'Tool not found.',
      );
    });

    test('disabledInWorkspace', () {
      expect(
        ToolCallResultStatus.disabledInWorkspace.toResponseString(),
        'Tool is disabled in workspace.',
      );
    });

    test('disabledInConversation', () {
      expect(
        ToolCallResultStatus.disabledInConversation.toResponseString(),
        'Tool is disabled for this conversation.',
      );
    });

    test('notConfigured', () {
      expect(
        ToolCallResultStatus.notConfigured.toResponseString(),
        'Tool is not configured.',
      );
    });

    test('executionError', () {
      expect(
        ToolCallResultStatus.executionError.toResponseString(),
        'Tool execution failed.',
      );
    });
  });

  group('ToolCallResultStatus.stopsAgentLoop', () {
    test('stoppedByUser returns true', () {
      expect(ToolCallResultStatus.stoppedByUser.stopsAgentLoop, isTrue);
    });

    test('other statuses return false', () {
      expect(ToolCallResultStatus.success.stopsAgentLoop, isFalse);
      expect(ToolCallResultStatus.skippedByUser.stopsAgentLoop, isFalse);
      expect(ToolCallResultStatus.toolNotFound.stopsAgentLoop, isFalse);
      expect(ToolCallResultStatus.disabledInWorkspace.stopsAgentLoop, isFalse);
      expect(
        ToolCallResultStatus.disabledInConversation.stopsAgentLoop,
        isFalse,
      );
      expect(ToolCallResultStatus.notConfigured.stopsAgentLoop, isFalse);
      expect(ToolCallResultStatus.executionError.stopsAgentLoop, isFalse);
    });
  });

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
          'success': ToolCallResultStatus.success,
          'skipped_by_user': ToolCallResultStatus.skippedByUser,
          'stopped_by_user': ToolCallResultStatus.stoppedByUser,
          'tool_not_found': ToolCallResultStatus.toolNotFound,
          'disabled_in_workspace': ToolCallResultStatus.disabledInWorkspace,
          'disabled_in_conversation':
              ToolCallResultStatus.disabledInConversation,
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
        expect(converter.toJson(ToolCallResultStatus.success), 'success');
        expect(
          converter.toJson(ToolCallResultStatus.skippedByUser),
          'skipped_by_user',
        );
        expect(
          converter.toJson(ToolCallResultStatus.stoppedByUser),
          'stopped_by_user',
        );
        expect(
          converter.toJson(ToolCallResultStatus.toolNotFound),
          'tool_not_found',
        );
        expect(
          converter.toJson(ToolCallResultStatus.disabledInWorkspace),
          'disabled_in_workspace',
        );
        expect(
          converter.toJson(ToolCallResultStatus.disabledInConversation),
          'disabled_in_conversation',
        );
        expect(
          converter.toJson(ToolCallResultStatus.notConfigured),
          'not_configured',
        );
        expect(
          converter.toJson(ToolCallResultStatus.executionError),
          'execution_error',
        );
      });

      test('round-trip fromJson → toJson is identity', () {
        for (final status in ToolCallResultStatus.values) {
          final json = converter.toJson(status);
          expect(converter.fromJson(json), status);
        }
      });
    });
  });
}
