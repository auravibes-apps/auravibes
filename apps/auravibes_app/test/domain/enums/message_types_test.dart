import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageType', () {
    group('value', () {
      test('text', () => expect(MessageType.text.value, 'text'));
      test('image', () => expect(MessageType.image.value, 'image'));
      test('toolCall', () => expect(MessageType.toolCall.value, 'tool_call'));
      test('system', () => expect(MessageType.system.value, 'system'));
    });

    group('displayName', () {
      test('text', () => expect(MessageType.text.displayName, 'Text'));
      test('image', () => expect(MessageType.image.displayName, 'Image'));
      test(
        'toolCall',
        () => expect(MessageType.toolCall.displayName, 'Tool Call'),
      );
      test('system', () => expect(MessageType.system.displayName, 'System'));
    });

    group('fromString', () {
      test('parses all valid values', () {
        expect(MessageType.fromString('text'), MessageType.text);
        expect(MessageType.fromString('image'), MessageType.image);
        expect(MessageType.fromString('tool_call'), MessageType.toolCall);
        expect(MessageType.fromString('system'), MessageType.system);
      });

      test('is case-insensitive', () {
        expect(MessageType.fromString('TEXT'), MessageType.text);
        expect(MessageType.fromString('Image'), MessageType.image);
      });

      test('throws for invalid value', () {
        expect(() => MessageType.fromString('invalid'), throwsArgumentError);
      });
    });
  });

  group('MessageStatus', () {
    group('value', () {
      test('sending', () => expect(MessageStatus.sending.value, 'sending'));
      test(
        'unfinished',
        () => expect(MessageStatus.unfinished.value, 'unfinished'),
      );
      test('sent', () => expect(MessageStatus.sent.value, 'sent'));
      test('error', () => expect(MessageStatus.error.value, 'error'));
    });

    group('displayName', () {
      test(
        'sending',
        () => expect(MessageStatus.sending.displayName, 'Sending'),
      );
      test(
        'unfinished',
        () => expect(MessageStatus.unfinished.displayName, 'Unfinished'),
      );
      test('sent', () => expect(MessageStatus.sent.displayName, 'Sent'));
      test('error', () => expect(MessageStatus.error.displayName, 'Error'));
    });

    group('fromString', () {
      test('parses all valid values', () {
        expect(MessageStatus.fromString('sending'), MessageStatus.sending);
        expect(
          MessageStatus.fromString('unfinished'),
          MessageStatus.unfinished,
        );
        expect(MessageStatus.fromString('sent'), MessageStatus.sent);
        expect(MessageStatus.fromString('error'), MessageStatus.error);
      });

      test('is case-insensitive', () {
        expect(MessageStatus.fromString('SENDING'), MessageStatus.sending);
        expect(MessageStatus.fromString('Sent'), MessageStatus.sent);
      });

      test('throws for invalid value', () {
        expect(
          () => MessageStatus.fromString('delivered'),
          throwsArgumentError,
        );
      });
    });
  });
}
