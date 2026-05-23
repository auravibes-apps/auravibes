import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/chatbot_service/tool_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatbotService.generateFallbackTitle additional', () {
    test('handles single very long word exceeding 30 chars', () {
      final title = ChatbotService.generateFallbackTitle('a' * 100);
      expect(title.length, 30);
      expect(title.endsWith('...'), isTrue);
    });

    test('exactly 30 chars does not truncate', () {
      final words = List.generate(4, (i) => 'a' * 6).join(' ');
      expect(words.length, 27);
      final title = ChatbotService.generateFallbackTitle(words);
      expect(title, words);
    });

    test('title at 31 chars truncates', () {
      const words = 'aaaaaa bbbbbb cccccc dddddd';
      expect(words.length, 27);
      const longTitle = 'aaaaaa bbbbbb cccccc dddddde';
      expect(longTitle.length, 28);
      final title = ChatbotService.generateFallbackTitle(longTitle);
      if (title.length > 30) {
        expect(title.endsWith('...'), isTrue);
      }
    });

    test('handles message with only spaces', () {
      expect(ChatbotService.generateFallbackTitle('     '), '');
    });

    test('preserves original casing', () {
      expect(
        ChatbotService.generateFallbackTitle('Hello World Foo Bar'),
        'Hello World Foo Bar',
      );
    });

    test('handles Unicode characters', () {
      final title = ChatbotService.generateFallbackTitle('こんにちは 世界 テスト');
      expect(title, isNotEmpty);
    });
  });

  group('ToolAdapter', () {
    test('converts tool specs to dartantic Tools', () {
      const adapter = ToolAdapter();
      final specs = [
        const ToolSpec(
          name: 'test_tool',
          description: 'A test tool',
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
        onCall: (toolName, args) async => {'result': 'ok'},
      );

      expect(tools.length, 1);
      expect(tools.firstOrNull?.name, 'test_tool');
      expect(tools.firstOrNull?.description, 'A test tool');
    });

    test('handles empty tool specs list', () {
      const adapter = ToolAdapter();
      final tools = adapter(
        [],
        onCall: (toolName, args) async => {},
      );
      expect(tools, isEmpty);
    });

    test('converts multiple tool specs', () {
      const adapter = ToolAdapter();
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

      final tools = adapter(
        specs,
        onCall: (toolName, args) async => {},
      );

      expect(tools.length, 2);
      expect(tools.firstOrNull?.name, 'tool_a');
      expect(tools[1].name, 'tool_b');
    });
  });
}
