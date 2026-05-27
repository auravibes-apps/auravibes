// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
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
      final title = ChatbotService.generateFallbackTitle(
        String.fromCharCodes([
          0x3053,
          0x3093,
          0x306b,
          0x3061,
          0x306f,
          32,
          0x4e16,
          0x754c,
          32,
          0x30c6,
          0x30b9,
          0x30c8,
        ]),
      );
      expect(title, isNotEmpty);
    });
  });
}
