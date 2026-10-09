// ignore_for_file: cascade_invocations

import 'dart:async';

import 'package:auravibes_app/domain/repositories/workspace_selection_repository.dart';
import 'package:auravibes_app/features/workspaces/models/switch_status.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_switcher.dart';
import 'package:auravibes_app/features/workspaces/providers/last_workspace_selection_repository_provider.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _testDebounceDuration = Duration(milliseconds: 1);
const _testDebounceWait = Duration(milliseconds: 10);

class _PendingWorkspaceSelectionRepository
    implements WorkspaceSelectionRepository {
  final savedWorkspaceIds = <String>[];
  final _pendingSaves = <Completer<void>>[];

  @override
  Future<void> clearIfMatches(String workspaceId) => Future<void>.value();

  @override
  Future<String?> read() => Future<String?>.value();

  @override
  Future<void> save(String workspaceId) {
    savedWorkspaceIds.add(workspaceId);
    final save = Completer<void>();
    _pendingSaves.add(save);

    return save.future;
  }

  void completeSave(int index) => _pendingSaves[index].complete();

  void failSave(int index) =>
      _pendingSaves[index].completeError(StateError('Stale save failed.'));
}

class _FailingWorkspaceSelectionRepository
    implements WorkspaceSelectionRepository {
  @override
  Future<void> clearIfMatches(String workspaceId) => Future<void>.value();

  @override
  Future<String?> read() => Future<String?>.value();

  @override
  Future<void> save(String workspaceId) =>
      Future<void>.error(StateError('Unable to save the selected workspace.'));
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (condition()) return;

    await Future<void>.delayed(.zero);
  }

  fail('Condition was not met after queued asynchronous work completed.');
}

class _FakeGoRouter implements GoRouter {
  final locations = <String>[];
  String? lastLocation;

  @override
  void go(String location, {Object? extra}) {
    locations.add(location);
    lastLocation = location;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  final fastDebounceOverride = workspaceSwitcherProvider.overrideWith(
    () => WorkspaceSwitcher(debounceDuration: _testDebounceDuration),
  );

  group('WorkspaceSwitcher', () {
    var fakeRouter = _FakeGoRouter();
    var container = ProviderContainer(
      overrides: [
        routerProvider.overrideWithValue(fakeRouter),
        fastDebounceOverride,
      ],
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeRouter = _FakeGoRouter();
      container = ProviderContainer(
        overrides: [
          routerProvider.overrideWithValue(fakeRouter),
          fastDebounceOverride,
        ],
      );
      // Keep provider alive during async timer-based tests.
      final _ = container.listen(workspaceSwitcherProvider, (_, _) {
        final _ = Object();
      });
    });

    tearDown(() => container.dispose());

    test('initial state is idle', () {
      final state = container.read(workspaceSwitcherProvider);

      expect(state.status, SwitchStatus.idle);
      expect(state.targetWorkspaceId, isNull);
      expect(state.errorLocalizationKey, isNull);
    });

    test(
      'switchToWorkspace navigates to new chat route after debounce',
      () async {
        final notifier = container.read(workspaceSwitcherProvider.notifier);

        notifier.switchToWorkspace('ws-1');
        expect(fakeRouter.lastLocation, isNull);

        await Future<void>.delayed(_testDebounceWait);

        expect(fakeRouter.lastLocation, '/workspaces/ws-1/chat/new');
      },
    );

    test('persists an explicit selection before navigating', () async {
      final notifier = container.read(workspaceSwitcherProvider.notifier);

      notifier.switchToWorkspace('ws-1');
      await Future<void>.delayed(_testDebounceWait);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('last_selected_workspace_id'), 'ws-1');
      expect(fakeRouter.lastLocation, '/workspaces/ws-1/chat/new');
    });

    test(
      'queues an in-flight switch before persisting a later selection',
      () async {
        container.dispose();
        final pendingSelection = _PendingWorkspaceSelectionRepository();
        container = ProviderContainer(
          overrides: [
            routerProvider.overrideWithValue(fakeRouter),
            fastDebounceOverride,
            lastWorkspaceSelectionRepositoryProvider.overrideWithValue(
              pendingSelection,
            ),
          ],
        );
        final _ = container.listen(workspaceSwitcherProvider, (_, _) {
          final _ = Object();
        });
        final notifier = container.read(workspaceSwitcherProvider.notifier);

        notifier.switchToWorkspace('ws-1');
        await Future<void>.delayed(_testDebounceWait);
        notifier.switchToWorkspace('ws-2');
        await Future<void>.delayed(_testDebounceWait);

        expect(pendingSelection.savedWorkspaceIds, ['ws-1']);

        pendingSelection.completeSave(0);
        await _waitUntil(() => pendingSelection.savedWorkspaceIds.length == 2);
        expect(pendingSelection.savedWorkspaceIds, ['ws-1', 'ws-2']);

        pendingSelection.completeSave(1);
        await Future<void>.delayed(.zero);
        expect(fakeRouter.lastLocation, '/workspaces/ws-2/chat/new');
        expect(fakeRouter.locations, ['/workspaces/ws-2/chat/new']);
      },
    );

    for (final staleSaveFails in [false, true]) {
      final result = staleSaveFails ? 'failure' : 'success';
      test('superseded $result cannot affect the latest switch', () async {
        container.dispose();
        final pendingSelection = _PendingWorkspaceSelectionRepository();
        container = ProviderContainer(
          overrides: [
            routerProvider.overrideWithValue(fakeRouter),
            fastDebounceOverride,
            lastWorkspaceSelectionRepositoryProvider.overrideWithValue(
              pendingSelection,
            ),
          ],
        );
        final states = <WorkspaceSwitchState>[];
        final subscription = container.listen(
          workspaceSwitcherProvider,
          (previous, next) => states.add(next),
        );
        addTearDown(subscription.close);
        final notifier = container.read(workspaceSwitcherProvider.notifier);

        notifier.switchToWorkspace('ws-1');
        await Future<void>.delayed(_testDebounceWait);
        expect(pendingSelection.savedWorkspaceIds, ['ws-1']);
        notifier.switchToWorkspace('ws-2');
        await Future<void>.delayed(_testDebounceWait);
        final stateCount = states.length;

        if (staleSaveFails) {
          pendingSelection.failSave(0);
        } else {
          pendingSelection.completeSave(0);
        }
        await _waitUntil(() => pendingSelection.savedWorkspaceIds.length == 2);

        expect(fakeRouter.locations, isEmpty);
        expect(
          states.skip(stateCount).every((state) => state.status == .loading),
          isTrue,
        );
        expect(
          container.read(workspaceSwitcherProvider).targetWorkspaceId,
          'ws-2',
        );

        pendingSelection.completeSave(1);
        await _waitUntil(() => fakeRouter.locations.isNotEmpty);

        expect(fakeRouter.locations, ['/workspaces/ws-2/chat/new']);
        expect(
          container.read(workspaceSwitcherProvider).status,
          SwitchStatus.idle,
        );
      });
    }

    test('cancels an in-flight switch without navigating', () async {
      container.dispose();
      final pendingSelection = _PendingWorkspaceSelectionRepository();
      container = ProviderContainer(
        overrides: [
          routerProvider.overrideWithValue(fakeRouter),
          fastDebounceOverride,
          lastWorkspaceSelectionRepositoryProvider.overrideWithValue(
            pendingSelection,
          ),
        ],
      );
      final _ = container.listen(workspaceSwitcherProvider, (_, _) {
        final _ = Object();
      });
      final notifier = container.read(workspaceSwitcherProvider.notifier);

      notifier.switchToWorkspace('ws-1');
      await Future<void>.delayed(_testDebounceWait);
      notifier.cancelPendingSwitch();
      pendingSelection.completeSave(0);
      await Future<void>.delayed(.zero);

      expect(fakeRouter.locations, isEmpty);
      expect(
        container.read(workspaceSwitcherProvider).status,
        SwitchStatus.idle,
      );
    });

    test('shows an error without navigating when saving fails', () async {
      container.dispose();
      final failingSelection = _FailingWorkspaceSelectionRepository();
      container = ProviderContainer(
        overrides: [
          routerProvider.overrideWithValue(fakeRouter),
          fastDebounceOverride,
          lastWorkspaceSelectionRepositoryProvider.overrideWithValue(
            failingSelection,
          ),
        ],
      );
      final _ = container.listen(workspaceSwitcherProvider, (_, _) {
        final _ = Object();
      });
      final notifier = container.read(workspaceSwitcherProvider.notifier);

      notifier.switchToWorkspace('ws-1');
      await Future<void>.delayed(_testDebounceWait);

      final state = container.read(workspaceSwitcherProvider);
      expect(state.status, SwitchStatus.error);
      expect(state.targetWorkspaceId, 'ws-1');
      expect(fakeRouter.lastLocation, isNull);
    });

    test('state transitions through loading then idle on success', () async {
      final notifier = container.read(workspaceSwitcherProvider.notifier);
      final states = <WorkspaceSwitchState>[];

      final subscription = container.listen(
        workspaceSwitcherProvider,
        (previous, next) => states.add(next),
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      notifier.switchToWorkspace('ws-1');
      await Future<void>.delayed(_testDebounceWait);

      expect(states.length, greaterThanOrEqualTo(3));
      expect(states.firstOrNull?.status, SwitchStatus.idle);

      // Loading state.
      final loadingState = states.firstWhere(
        (s) => s.status == SwitchStatus.loading,
      );
      expect(loadingState.status, SwitchStatus.loading);

      // Final idle state.
      expect(states.last.status, SwitchStatus.idle);
    });

    test('debounce cancels previous pending switch', () async {
      container.dispose();
      container = ProviderContainer(
        overrides: [routerProvider.overrideWithValue(fakeRouter)],
      );
      final _ = container.listen(workspaceSwitcherProvider, (_, _) {
        final _ = Object();
      });
      final notifier = container.read(workspaceSwitcherProvider.notifier);

      notifier.switchToWorkspace('ws-1');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(fakeRouter.locations, isEmpty);
      notifier.switchToWorkspace('ws-2');

      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(fakeRouter.lastLocation, '/workspaces/ws-2/chat/new');
      expect(fakeRouter.locations, ['/workspaces/ws-2/chat/new']);
    });

    test('cancelPendingSwitch prevents navigation', () async {
      final notifier = container.read(workspaceSwitcherProvider.notifier);

      notifier.switchToWorkspace('ws-1');
      notifier.cancelPendingSwitch();

      await Future<void>.delayed(_testDebounceWait);

      expect(fakeRouter.lastLocation, isNull);
    });

    test('clearError resets error state to idle', () {
      final notifier = container.read(workspaceSwitcherProvider.notifier);

      // Manually set error state.
      notifier.state = const WorkspaceSwitchState(
        status: .error,
        targetWorkspaceId: 'ws-1',
        errorLocalizationKey: 'Failed',
      );

      notifier.clearError();

      final state = container.read(workspaceSwitcherProvider);
      expect(state.status, SwitchStatus.idle);
      expect(state.errorLocalizationKey, isNull);
      expect(state.targetWorkspaceId, isNull);
    });

    test('rapid calls process only last selection', () async {
      final notifier = container.read(workspaceSwitcherProvider.notifier);

      notifier.switchToWorkspace('ws-1');
      notifier.switchToWorkspace('ws-2');
      notifier.switchToWorkspace('ws-3');

      await Future<void>.delayed(_testDebounceWait);

      expect(fakeRouter.lastLocation, '/workspaces/ws-3/chat/new');
    });

    test('switchToWorkspace opens the workspace new chat route', () async {
      final notifier = container.read(workspaceSwitcherProvider.notifier);

      notifier.switchToWorkspace('ws-1');
      await Future<void>.delayed(_testDebounceWait);

      expect(fakeRouter.lastLocation, '/workspaces/ws-1/chat/new');
    });

    test('navigation location format is correct', () async {
      final notifier = container.read(workspaceSwitcherProvider.notifier);

      notifier.switchToWorkspace('workspace-abc-123');
      await Future<void>.delayed(_testDebounceWait);

      expect(fakeRouter.lastLocation, '/workspaces/workspace-abc-123/chat/new');
    });
  });
}
