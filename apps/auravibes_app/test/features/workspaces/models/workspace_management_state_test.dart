import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/workspaces/models/management_mode.dart';
import 'package:flutter_test/flutter_test.dart';

WorkspaceEntity _workspace({
  required String id,
  required String name,
}) {
  return WorkspaceEntity(
    id: id,
    name: name,
    type: WorkspaceType.local,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  group('ManagementMode', () {
    test('has three values', () {
      expect(ManagementMode.values.length, 3);
    });

    test('values are list, create, edit', () {
      expect(ManagementMode.values, [
        ManagementMode.list,
        ManagementMode.create,
        ManagementMode.edit,
      ]);
    });
  });

  group('WorkspaceManagementState', () {
    test('default state has list mode and null editingWorkspace', () {
      const state = WorkspaceManagementState();

      expect(state.mode, ManagementMode.list);
      expect(state.editingWorkspace, isNull);
    });

    test('can be constructed with create mode', () {
      const state = WorkspaceManagementState(mode: ManagementMode.create);

      expect(state.mode, ManagementMode.create);
      expect(state.editingWorkspace, isNull);
    });

    test('can be constructed with edit mode and workspace', () {
      final workspace = _workspace(id: 'ws-1', name: 'Test');
      final state = WorkspaceManagementState(
        mode: ManagementMode.edit,
        editingWorkspace: workspace,
      );

      expect(state.mode, ManagementMode.edit);
      expect(state.editingWorkspace, workspace);
    });

    test('equality works for identical states', () {
      final workspace = _workspace(id: 'ws-1', name: 'Test');
      final state1 = WorkspaceManagementState(
        mode: ManagementMode.edit,
        editingWorkspace: workspace,
      );
      final state2 = WorkspaceManagementState(
        mode: ManagementMode.edit,
        editingWorkspace: workspace,
      );

      expect(state1, state2);
    });

    test('equality fails for different modes', () {
      const state1 = WorkspaceManagementState();
      const state2 = WorkspaceManagementState(mode: ManagementMode.create);

      expect(state1, isNot(equals(state2)));
    });

    test('equality fails for different editingWorkspace', () {
      final ws1 = _workspace(id: 'ws-1', name: 'A');
      final ws2 = _workspace(id: 'ws-2', name: 'B');
      final state1 = WorkspaceManagementState(editingWorkspace: ws1);
      final state2 = WorkspaceManagementState(editingWorkspace: ws2);

      expect(state1, isNot(equals(state2)));
    });

    test('copyWith changes only specified fields', () {
      final workspace = _workspace(id: 'ws-1', name: 'Test');
      final state = WorkspaceManagementState(
        editingWorkspace: workspace,
      );
      final copied = state.copyWith(mode: ManagementMode.create);

      expect(copied.mode, ManagementMode.create);
      expect(copied.editingWorkspace, workspace);
    });

    test('copyWith can clear editingWorkspace', () {
      final workspace = _workspace(id: 'ws-1', name: 'Test');
      final state = WorkspaceManagementState(
        mode: ManagementMode.edit,
        editingWorkspace: workspace,
      );
      final copied = state.copyWith(editingWorkspace: null);

      expect(copied.editingWorkspace, isNull);
      expect(copied.mode, ManagementMode.edit);
    });
  });
}
