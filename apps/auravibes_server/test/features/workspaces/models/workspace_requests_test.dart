import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('workspace summary serializes cloud metadata', () {
    final now = DateTime.utc(2026);
    final summary = CloudWorkspaceSummary(
      id: 1,
      name: 'Cloud',
      role: 'owner',
      revision: 1,
      sequence: 0,
      createdAt: now,
      updatedAt: now,
    );

    expect(summary.toJson()['role'], 'owner');
  });

  test('mutation receipt serializes explicit idempotency scope', () {
    final receipt = WorkspaceMutationReceipt(
      workspaceId: 1,
      scopeKey: 'workspace:1',
      actorUserId: 'user-1',
      endpoint: 'cloudWorkspace.renameWorkspace',
      requestId: 'request-1',
      requestHash: '{}',
      responseJson: '{}',
      createdAt: DateTime.utc(2026),
    );

    expect(receipt.toJson()['scopeKey'], 'workspace:1');
  });
}
