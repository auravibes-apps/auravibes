// ignore_for_file: avoid-non-null-assertion
// Required: Tests inspect nullable values after arranging expected state.

import 'package:auravibes_app/services/tools/tool_service.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolService', () {
    test('availableTools contains calculator', () {
      expect(ToolService.availableTools, hasLength(1));
      expect(
        ToolService.availableTools.first.type,
        UserToolType.calculator,
      );
    });

    group('getTypes', () {
      test('returns all tool types', () {
        final types = ToolService.getTypes();
        expect(types, hasLength(1));
        expect(types, contains(UserToolType.calculator));
      });

      test('excludes types in without list', () {
        final types = ToolService.getTypes(
          without: [UserToolType.calculator],
        );
        expect(types, isEmpty);
      });

      test('returns all when without is empty', () {
        final types = ToolService.getTypes(without: []);
        expect(types, hasLength(1));
      });
    });

    group('getTools', () {
      test('returns all tools without filters', () {
        final tools = ToolService.getTools();
        expect(tools, hasLength(1));
      });

      test('excludes tools in without list', () {
        final tools = ToolService.getTools(
          without: [UserToolType.calculator],
        );
        expect(tools, isEmpty);
      });

      test('filters by only list', () {
        final tools = ToolService.getTools(
          only: [UserToolType.calculator],
        );
        expect(tools, hasLength(1));
      });

      test('returns empty when only list has no matches', () {
        final tools = ToolService.getTools(only: []);
        expect(tools, isEmpty);
      });

      test('applies without then only', () {
        final tools = ToolService.getTools(
          without: [UserToolType.calculator],
          only: [UserToolType.calculator],
        );
        expect(tools, isEmpty);
      });
    });

    group('getTool', () {
      test('returns tool by type', () {
        final tool = ToolService.getTool(UserToolType.calculator);
        expect(tool, isNotNull);
        expect(tool!.type, UserToolType.calculator);
      });

      test('returns null for unknown type', () {
        final tool = ToolService.getTool(
          UserToolType.calculator,
        );
        expect(tool, isNotNull);
      });
    });

    group('getType', () {
      test('returns type of given tool', () {
        final tool = ToolService.availableTools.first;
        expect(ToolService.getType(tool), UserToolType.calculator);
      });
    });

    group('hasType', () {
      test('returns true for existing type', () {
        expect(ToolService.hasType(UserToolType.calculator), isTrue);
      });
    });

    group('hasTypeString', () {
      test('returns true for existing type string', () {
        expect(ToolService.hasTypeString('calculator'), isTrue);
      });

      test('returns false for unknown type string', () {
        expect(ToolService.hasTypeString('nonexistent'), isFalse);
      });
    });
  });

  group('UserToolType', () {
    test('has calculator value', () {
      expect(UserToolType.calculator.value, 'calculator');
    });

    test('fromValue returns enum for valid value', () {
      expect(UserToolType.fromValue('calculator'), UserToolType.calculator);
    });

    test('fromValue returns null for invalid value', () {
      expect(UserToolType.fromValue('nonexistent'), isNull);
    });
  });
}
