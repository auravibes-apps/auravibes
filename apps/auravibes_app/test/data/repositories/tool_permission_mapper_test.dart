import 'package:auravibes_app/data/database/drift/enums/permission_access.dart';
import 'package:auravibes_app/data/repositories/tool_permission_mapper.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every stored permission in both directions', () {
    const expected = {
      PermissionAccess.ask: ToolPermissionMode.alwaysAsk,
      PermissionAccess.granted: ToolPermissionMode.alwaysAllow,
      PermissionAccess.denied: ToolPermissionMode.alwaysDeny,
    };
    expect(expected.keys, unorderedEquals(PermissionAccess.values));
    expect(expected.values, unorderedEquals(ToolPermissionMode.values));
    for (final entry in expected.entries) {
      expect(mapPermissionAccess(entry.key), entry.value);
      expect(mapPermissionMode(entry.value), entry.key);
    }
  });
}
