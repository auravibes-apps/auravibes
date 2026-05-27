// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: avoid-late-keyword
// Required: Test fixtures are assigned in setUp.
// ignore_for_file: no-empty-block
// Required: Tests use intentional no-op callbacks and fake hooks.
// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: no-object-declaration
// Required: Test fakes override noSuchMethod with Object return values.

// ignore_for_file: cascade_invocations

import 'package:auravibes_app/features/workspaces/models/switch_status.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_switcher.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart';

class _FakeGoRouter implements GoRouter {
  String? lastLocation;

  @override
  void go(String location, {Object? extra}) {
    lastLocation = location;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkspaceSwitcher', () {
    late _FakeGoRouter fakeRouter;
    late ProviderContainer container;

    setUp(() {
      fakeRouter = _FakeGoRouter();
      container = ProviderContainer(
        overrides: [
          routerProvider.overrideWithValue(fakeRouter),
        ],
      );
      // Keep provider alive during async timer-based tests.
      final _ = container.listen(workspaceSwitcherProvider, (_, _) {});
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

        await Future<void>.delayed(const Duration(milliseconds: 350));

        expect(fakeRouter.lastLocation, '/workspaces/ws-1/chat/new');
      },
    );

    test('state transitions through loading then idle on success', () async {
      final notifier = container.read(workspaceSwitcherProvider.notifier);
      final states = <WorkspaceSwitchState>[];

      final _ = container.listen(
        workspaceSwitcherProvider,
        (previous, next) => states.add(next),
        fireImmediately: true,
      );

      notifier.switchToWorkspace('ws-1');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(states.length, greaterThanOrEqualTo(3));
      expect(states.firstOrNull?.status, SwitchStatus.idle);

      // Loading state
      final loadingState = states.firstWhere(
        (s) => s.status == SwitchStatus.loading,
      );
      expect(loadingState.status, SwitchStatus.loading);

      // Final idle state
      expect(states.last.status, SwitchStatus.idle);
    });

    test('debounce cancels previous pending switch', () async {
      final notifier = container.read(workspaceSwitcherProvider.notifier);

      notifier.switchToWorkspace('ws-1');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      notifier.switchToWorkspace('ws-2');

      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(fakeRouter.lastLocation, '/workspaces/ws-2/chat/new');
    });

    test('cancelPendingSwitch prevents navigation', () async {
      final notifier = container.read(workspaceSwitcherProvider.notifier);

      notifier.switchToWorkspace('ws-1');
      notifier.cancelPendingSwitch();

      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(fakeRouter.lastLocation, isNull);
    });

    test('clearError resets error state to idle', () {
      final notifier = container.read(workspaceSwitcherProvider.notifier);

      // Manually set error state
      notifier.state = const WorkspaceSwitchState(
        status: SwitchStatus.error,
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

      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(fakeRouter.lastLocation, '/workspaces/ws-3/chat/new');
    });

    test(
      'switchToWorkspace opens the workspace new chat route',
      () async {
        final notifier = container.read(workspaceSwitcherProvider.notifier);

        notifier.switchToWorkspace('ws-1');
        await Future<void>.delayed(const Duration(milliseconds: 350));

        expect(fakeRouter.lastLocation, '/workspaces/ws-1/chat/new');
      },
    );

    test('navigation location format is correct', () async {
      final notifier = container.read(workspaceSwitcherProvider.notifier);

      notifier.switchToWorkspace('workspace-abc-123');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(
        fakeRouter.lastLocation,
        '/workspaces/workspace-abc-123/chat/new',
      );
    });
  });
}
