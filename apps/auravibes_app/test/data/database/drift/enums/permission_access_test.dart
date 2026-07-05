import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PermissionAccess', () {
    test('has correct values', () {
      expect(PermissionAccess.values, hasLength(3));
      expect(PermissionAccess.ask.value, 'ask');
      expect(PermissionAccess.granted.value, 'granted');
      expect(PermissionAccess.denied.value, 'denied');
    });

    test('fromString returns matching enum', () {
      expect(PermissionAccess.fromString('ask'), PermissionAccess.ask);
      expect(PermissionAccess.fromString('granted'), PermissionAccess.granted);
      expect(PermissionAccess.fromString('denied'), PermissionAccess.denied);
    });

    test('fromString returns ask for unknown value', () {
      expect(PermissionAccess.fromString('unknown'), PermissionAccess.ask);
      expect(PermissionAccess.fromString(''), PermissionAccess.ask);
    });

    test('fromString uses name not value', () {
      expect(PermissionAccess.fromString('ask'), same(PermissionAccess.ask));
      expect(
        PermissionAccess.fromString('granted'),
        same(PermissionAccess.granted),
      );
      expect(
        PermissionAccess.fromString('denied'),
        same(PermissionAccess.denied),
      );
    });
  });
}
