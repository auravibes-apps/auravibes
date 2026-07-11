import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceToCreate', () {
    test('allows cloud remote workspace without url', () {
      const workspace = WorkspaceToCreate(
        name: 'Cloud',
        type: WorkspaceType.remote,
        cloudWorkspaceId: '1',
        cloudAccountId: 'account_1',
      );

      expect(workspace.isValid, isTrue);
    });

    test('rejects local workspace with cloud metadata', () {
      const workspace = WorkspaceToCreate(
        name: 'Local',
        type: WorkspaceType.local,
        cloudWorkspaceId: '1',
        cloudAccountId: 'account_1',
      );

      expect(workspace.isValid, isFalse);
    });
  });
}
