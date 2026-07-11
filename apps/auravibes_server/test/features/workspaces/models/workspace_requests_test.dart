import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('workspace summary serializes cloud metadata', () {
    final now = DateTime.utc(2026);
    final summary = CloudWorkspaceSummary(
      id: 1,
      name: 'Cloud',
      role: 'owner',
      createdAt: now,
      updatedAt: now,
    );

    expect(summary.toJson()['role'], 'owner');
  });
}
