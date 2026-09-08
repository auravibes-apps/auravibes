import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/workspaces/models/management_mode.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_management_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _WorkspaceManagementModeFixture {
  ProviderContainer? _container;

  ProviderContainer get container =>
      _container ?? fail('container not initialized');

  void reset() {
    _container = ProviderContainer();
  }

  void dispose() {
    _container?.dispose();
    _container = null;
  }

  WorkspaceManagementState get state =>
      container.read(workspaceManagementModeProvider);

  void editWorkspace(WorkspaceEntity workspace) {
    container
        .read(workspaceManagementModeProvider.notifier)
        .editWorkspace(workspace);
  }

  void clearEditing() {
    container.read(workspaceManagementModeProvider.notifier).clearEditing();
  }
}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkspaceManagementMode', () {
    final fixture = _WorkspaceManagementModeFixture();

    setUp(fixture.reset);

    tearDown(fixture.dispose);

    test('initial state is list mode with no editing workspace', () {
      final state = fixture.state;

      expect(state.mode, ManagementMode.list);
      expect(state.editingWorkspace, isNull);
    });

    test('editWorkspace changes mode and workspace', () {
      final workspace = WorkspaceEntity(
        id: 'ws-1',
        name: 'Test',
        type: WorkspaceType.local,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      fixture.editWorkspace(workspace);

      final state = fixture.state;
      expect(state.mode, ManagementMode.edit);
      expect(state.editingWorkspace, workspace);
    });

    test('clearEditing resets to list mode', () {
      final workspace = WorkspaceEntity(
        id: 'ws-1',
        name: 'Test',
        type: WorkspaceType.local,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      fixture
        ..editWorkspace(workspace)
        ..clearEditing();

      final state = fixture.state;
      expect(state.mode, ManagementMode.list);
      expect(state.editingWorkspace, isNull);
    });
  });
}
