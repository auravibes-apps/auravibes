import 'dart:async';

import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/repositories/workspace_selection_repository.dart';
import 'package:auravibes_app/features/agents/providers/agent_repository_providers.dart';
import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/chats/widgets/chat_input_widget.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/workspaces/models/switch_status.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_switcher.dart';
import 'package:auravibes_app/features/workspaces/providers/last_workspace_selection_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

Future<void> _pumpNewChatWithinPausedBranch(
  WidgetTester tester, {
  required List<Object> overrides,
  String workspaceId = 'test-ws',
  bool tickerEnabled = false,
}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      TestableApp(
        child: TickerMode(
          enabled: tickerEnabled,
          child: Theme(
            data: .new(extensions: [AuraTheme.light]),
            child: Portal(child: NewChatScreen(workspaceId: workspaceId)),
          ),
        ),
        overrides: overrides,
        workspaceId: workspaceId,
      ),
    );
    await Future<void>.delayed(.zero);
  });
  await tester.pump();
  final _ = await tester.pumpAndSettle();
}

WorkspaceEntity _workspace(String id) => WorkspaceEntity(
  id: id,
  name: 'Personal',
  type: .local,
  createdAt: .new(2026),
  updatedAt: .new(2026),
);

class _FailOnceWorkspaceSelectionRepository
    implements WorkspaceSelectionRepository {
  final firstSave = Completer<void>();
  final savedWorkspaceIds = <String>[];

  @override
  Future<void> clearIfMatches(String workspaceId) => Future<void>.value();

  @override
  Future<String?> read() async => null;

  @override
  Future<void> save(String workspaceId) {
    savedWorkspaceIds.add(workspaceId);
    if (savedWorkspaceIds.length == 1) return firstSave.future;

    return Future<void>.value();
  }
}

class _FakeGoRouter implements GoRouter {
  String? lastLocation;

  @override
  void go(String location, {Object? extra}) => lastLocation = location;

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

List<Object> _newChatOverrides({
  NewChatState state = const NewChatState(),
  List<WorkspaceEntity>? workspaces,
}) => [
  newChatProvider('test-ws').overrideWithValue(state),
  workspaceModelSelectionByIdProvider(
    'test-ws',
    'model',
  ).overrideWithValue(const AsyncData(null)),
  listModelsGroupedByProviderProvider.overrideWith(
    (ref, workspaceId) => Stream.value({}),
  ),
  agentsProvider('test-ws').overrideWith((ref) => Stream.value(const [])),
  allWorkspacesProvider.overrideWithValue(
    AsyncData(workspaces ?? [_workspace('test-ws')]),
  ),
];

void main() {
  test('constructor sets workspaceId', () {
    const screen = NewChatScreen(workspaceId: 'test-ws');
    expect(screen.workspaceId, 'test-ws');
  });

  test('constructor accepts different workspaceIds', () {
    const screen = NewChatScreen(workspaceId: 'other-id');
    expect(screen.workspaceId, 'other-id');
  });

  group('NewChatState', () {
    test('default values', () {
      const state = NewChatState();
      expect(state.modelId, isNull);
      expect(state.providerId, isNull);
      expect(state.isLoading, isFalse);
    });

    test('copyWith preserves values', () {
      const state = NewChatState(modelId: 'm1', providerId: 'p1');
      final copied = state.copyWith(isLoading: true);
      expect(copied.modelId, 'm1');
      expect(copied.providerId, 'p1');
      expect(copied.isLoading, isTrue);
    });

    test('copyWith allows nulling modelId', () {
      const state = NewChatState(modelId: 'm1');
      final copied = state.copyWith(modelId: null);
      expect(copied.modelId, isNull);
      expect(copied.providerId, isNull);
    });

    test('equality works', () {
      const a = NewChatState(modelId: 'm1');
      const b = NewChatState(modelId: 'm1');
      expect(a, equals(b));
    });

    test('inequality works', () {
      const a = NewChatState(modelId: 'm1');
      const b = NewChatState(modelId: 'm2');
      expect(a, isNot(equals(b)));
    });

    test('hashCode consistent with equality', () {
      const a = NewChatState(modelId: 'm1');
      const b = NewChatState(modelId: 'm1');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString includes fields', () {
      const state = NewChatState(modelId: 'm1', isLoading: true);
      final str = state.toString();
      expect(str, contains('m1'));
      expect(str, contains('true'));
    });
  });

  group('render', () {
    testWidgets('canceling workspace switch preserves unsent text', (
      tester,
    ) async {
      await _pumpNewChatWithinPausedBranch(
        tester,
        overrides: _newChatOverrides(
          state: const NewChatState(modelId: 'model'),
          workspaces: [_workspace('test-ws'), _workspace('target-ws')],
        ),
        tickerEnabled: true,
      );

      final textField = find.byType(EditableText).first;
      await tester.enterText(textField, 'unsent draft');
      await tester.pump();
      await tester.pump();
      final selector = tester.widget<AuraDropdownSelector<String>>(
        find.byKey(const Key('new_chat_workspace_selector')),
      );
      selector.onChanged?.call('target-ws');
      final _ = await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      final _ = await tester.pumpAndSettle();

      expect(
        tester.widget<EditableText>(textField).controller.text,
        'unsent draft',
      );
      expect(find.byType(NewChatScreen), findsOneWidget);
    });

    testWidgets('failed switch keeps draft and retry completes switch', (
      tester,
    ) async {
      final selectionRepository = _FailOnceWorkspaceSelectionRepository();
      final router = _FakeGoRouter();
      final overrides = [
        ..._newChatOverrides(
          state: const NewChatState(modelId: 'model'),
          workspaces: [_workspace('test-ws'), _workspace('target-ws')],
        ),
        newChatProvider('target-ws')
            .overrideWithValue(const NewChatState(modelId: 'model')),
        workspaceModelSelectionByIdProvider(
          'target-ws',
          'model',
        ).overrideWithValue(const AsyncData(null)),
        agentsProvider('target-ws')
            .overrideWith((ref) => Stream.value(const [])),
        lastWorkspaceSelectionRepositoryProvider.overrideWithValue(
          selectionRepository,
        ),
        routerProvider.overrideWithValue(router),
      ];
      await _pumpNewChatWithinPausedBranch(
        tester,
        overrides: overrides,
        tickerEnabled: true,
      );

      final textField = find.byType(EditableText).first;
      await tester.enterText(textField, 'unsent draft');
      await tester.pump();
      await tester.pump();
      final selector = tester.widget<AuraDropdownSelector<String>>(
        find.byKey(const Key('new_chat_workspace_selector')),
      );
      selector.onChanged?.call('target-ws');
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pump();
      expect(find.text('Switching workspace...'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(ChatInputWidget),
          matching: find.byWidgetPredicate(
            (widget) => widget is IgnorePointer && widget.ignoring,
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<EditableText>(textField).focusNode.hasFocus,
        isFalse,
      );
      await tester.pump(const Duration(milliseconds: 350));
      final switchStateUnderTest = ProviderScope.containerOf(
        tester.element(find.byType(NewChatScreen)),
        listen: false,
      ).read(workspaceSwitcherProvider);
      expect(switchStateUnderTest.status, SwitchStatus.loading);
      await tester.pump();
      expect(find.text('Switching workspace...'), findsOneWidget);
      selectionRepository.firstSave.completeError(
        StateError('Unable to save selected workspace.'),
      );
      await tester.pump();
      final _ = await tester.pumpAndSettle();

      expect(
        find.text('Failed to switch workspace. Please try again.'),
        findsOneWidget,
      );
      expect(
        tester.widget<EditableText>(textField).controller.text,
        'unsent draft',
      );
      expect(find.byType(NewChatScreen), findsOneWidget);

      await tester.enterText(textField, 'updated draft after failure');
      await tester.pump();
      expect(
        find.ancestor(
          of: find.byType(ChatInputWidget),
          matching: find.byWidgetPredicate(
            (widget) => widget is IgnorePointer && widget.ignoring,
          ),
        ),
        findsNothing,
      );
      await tester.tap(find.text('Retry'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      expect(
        tester.widget<EditableText>(textField).controller.text,
        'updated draft after failure',
      );
      await tester.tap(find.text('Discard'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsNothing);
      expect(router.lastLocation, '/workspaces/target-ws/chat/new');
      expect(selectionRepository.savedWorkspaceIds, ['target-ws', 'target-ws']);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NewChatScreen)),
        listen: false,
      );
      expect(
        container.read(workspaceSwitcherProvider).status,
        SwitchStatus.idle,
      );
      await _pumpNewChatWithinPausedBranch(
        tester,
        overrides: overrides,
        workspaceId: 'target-ws',
        tickerEnabled: true,
      );
      final switchedTextField = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(switchedTextField.controller.text, isEmpty);
    });
    testWidgets('keeps New Chat listeners active in a paused branch', (
      tester,
    ) async {
      await _pumpNewChatWithinPausedBranch(
        tester,
        overrides: _newChatOverrides(),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TickerMode &&
              widget.enabled &&
              widget.child is ConsumerWidget,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders unavailable New Chat for an unauthenticated workspace',
      (tester) async {
        await _pumpNewChatWithinPausedBranch(
          tester,
          overrides: [
            ..._newChatOverrides(),
            workspaceAvailabilityProvider('test-ws').overrideWith(
              (ref) async => const WorkspaceAuthenticationRequired(
                .new(
                  CloudWorkspaceRef(
                    localWorkspaceId: 'test-ws',
                    serverUrl: 'https://example.com',
                    accountId: 'account-1',
                    cloudWorkspaceId: 1,
                  ),
                ),
              ),
            ),
          ],
          tickerEnabled: true,
        );
        expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
        expect(
          tester.widget<ChatInputWidget>(find.byType(ChatInputWidget)).disabled,
          isTrue,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is TickerMode &&
                widget.enabled &&
                widget.child is ConsumerWidget,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders NewChatScreen', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Theme(
              data: .new(extensions: [AuraTheme.light]),
              child: const Portal(child: NewChatScreen(workspaceId: 'test-ws')),
            ),
            overrides: _newChatOverrides(),
            workspaceId: 'test-ws',
          ),
        );
        await Future<void>.delayed(.zero);
      });
      final _ = await tester.pumpAndSettle();
      expect(find.byType(NewChatScreen), findsOneWidget);
      expect(find.byType(AuraScreen), findsOneWidget);
      expect(find.byType(ChatInputWidget), findsOneWidget);
      expect(find.text('Select a model to enable messaging.'), findsOneWidget);
      expect(
        find.byKey(const Key('new_chat_workspace_selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('workspace_selector')),
        findsOneWidget,
      );
      expect(find.text('Personal'), findsOneWidget);
    });

    testWidgets('shows loading overlay while conversation starts', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: Theme(
              data: .new(extensions: [AuraTheme.light]),
              child: const Portal(child: NewChatScreen(workspaceId: 'test-ws')),
            ),
            overrides: _newChatOverrides(
              state: const NewChatState(isLoading: true),
            ),
            workspaceId: 'test-ws',
          ),
        );
        await Future<void>.delayed(.zero);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        tester
            .widget<AuraLoadingOverlay>(find.byType(AuraLoadingOverlay))
            .isLoading,
        isTrue,
      );
    });
  });
}
