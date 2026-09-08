import 'package:auravibes_app/data/database/drift/enums/messages_table_type.dart';
import 'package:auravibes_app/domain/enums/message_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageStatus compatibility', () {
    test('domain and table statuses preserve persisted values', () {
      for (final status in MessageStatus.values) {
        expect(MessageStatus.fromString(status.value), status);
      }
      for (final status in MessageTableStatus.values) {
        expect(MessageTableStatus.fromString(status.value), status);
      }
    });

    test('does not accept delivered in domain status parser', () {
      expect(() => MessageStatus.fromString('delivered'), throwsArgumentError);
    });

    test('does not accept delivered in table status parser', () {
      expect(
        () => MessageTableStatus.fromString('delivered'),
        throwsArgumentError,
      );
    });
  });
}
