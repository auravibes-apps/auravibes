import 'package:auravibes_app/data/database/drift/enums/message_table_enums.dart';
import 'package:auravibes_app/domain/enums/message_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageStatus compatibility', () {
    test('does not accept delivered in domain status parser', () {
      expect(
        () => MessageStatus.fromString('delivered'),
        throwsArgumentError,
      );
    });

    test('does not accept delivered in table status parser', () {
      expect(
        () => MessageTableStatus.fromString('delivered'),
        throwsArgumentError,
      );
    });
  });
}
