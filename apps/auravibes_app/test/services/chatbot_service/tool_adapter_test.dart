import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/services/chatbot_service/tool_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolAdapter', () {
    const adapter = ToolAdapter();

    test('converts ToolSpec to dartantic Tool', () async {
      final specs = [
        const ToolSpec(
          name: 'calculator',
          description: 'Perform calculations',
          inputJsonSchema: {
            'type': 'object',
            'properties': {
              'expression': {'type': 'string'},
            },
            'required': ['expression'],
          },
        ),
      ];

      final tools = adapter(specs, onCall: (_, _) async => {});

      expect(tools, hasLength(1));
      expect(tools.first.name, 'calculator');
      expect(tools.first.description, 'Perform calculations');
      expect(tools.first.inputSchema, isNotNull);
    });

    test('wires onCall callback with tool name and args', () async {
      String? capturedName;
      Map<String, dynamic>? capturedArgs;

      final specs = [
        const ToolSpec(
          name: 'search',
          description: 'Search',
          inputJsonSchema: {
            'type': 'object',
            'properties': {
              'query': {'type': 'string'},
            },
          },
        ),
      ];

      final tools = adapter(
        specs,
        onCall: (name, args) async {
          capturedName = name;
          capturedArgs = args;
          return {'result': 'found'};
        },
      );

      final result = await tools.first.onCall({'query': 'test'});

      expect(capturedName, 'search');
      expect(capturedArgs, {'query': 'test'});
      expect(result, {'result': 'found'});
    });

    test('converts empty specs list', () {
      final tools = adapter([], onCall: (_, _) async => {});

      expect(tools, isEmpty);
    });

    test('converts multiple specs', () {
      final specs = [
        const ToolSpec(
          name: 'tool_a',
          description: 'Tool A',
          inputJsonSchema: {'type': 'object'},
        ),
        const ToolSpec(
          name: 'tool_b',
          description: 'Tool B',
          inputJsonSchema: {'type': 'object'},
        ),
      ];

      final tools = adapter(specs, onCall: (_, _) async => {});

      expect(tools, hasLength(2));
      expect(tools[0].name, 'tool_a');
      expect(tools[1].name, 'tool_b');
    });
  });
}
