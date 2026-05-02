import 'package:auravibes_app/features/workspaces/models/workspace_switch_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SwitchStatus', () {
    test('has three values', () {
      expect(SwitchStatus.values.length, 3);
    });

    test('values are idle, loading, error', () {
      expect(SwitchStatus.values, [
        SwitchStatus.idle,
        SwitchStatus.loading,
        SwitchStatus.error,
      ]);
    });
  });

  group('WorkspaceSwitchState', () {
    test('default state is idle with no target or error', () {
      const state = WorkspaceSwitchState();

      expect(state.status, SwitchStatus.idle);
      expect(state.targetWorkspaceId, isNull);
      expect(state.errorLocalizationKey, isNull);
    });

    test('loading state has loading status and target', () {
      const state = WorkspaceSwitchState(
        status: SwitchStatus.loading,
        targetWorkspaceId: 'ws-1',
      );

      expect(state.status, SwitchStatus.loading);
      expect(state.targetWorkspaceId, 'ws-1');
      expect(state.errorLocalizationKey, isNull);
    });

    test('error state has error status, target, and message', () {
      const state = WorkspaceSwitchState(
        status: SwitchStatus.error,
        targetWorkspaceId: 'ws-1',
        errorLocalizationKey: 'Switch failed',
      );

      expect(state.status, SwitchStatus.error);
      expect(state.targetWorkspaceId, 'ws-1');
      expect(state.errorLocalizationKey, 'Switch failed');
    });

    test('equality works for identical states', () {
      const state1 = WorkspaceSwitchState(
        status: SwitchStatus.loading,
        targetWorkspaceId: 'ws-1',
      );
      const state2 = WorkspaceSwitchState(
        status: SwitchStatus.loading,
        targetWorkspaceId: 'ws-1',
      );

      expect(state1, state2);
    });

    test('equality fails for different statuses', () {
      const state1 = WorkspaceSwitchState();
      const state2 = WorkspaceSwitchState(status: SwitchStatus.loading);

      expect(state1, isNot(equals(state2)));
    });

    test('copyWith changes only specified fields', () {
      const state = WorkspaceSwitchState(
        status: SwitchStatus.loading,
        targetWorkspaceId: 'ws-1',
      );
      final copied = state.copyWith(status: SwitchStatus.error);

      expect(copied.status, SwitchStatus.error);
      expect(copied.targetWorkspaceId, 'ws-1');
      expect(copied.errorLocalizationKey, isNull);
    });
  });
}
