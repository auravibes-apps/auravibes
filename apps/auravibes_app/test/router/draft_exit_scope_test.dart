import 'dart:async';

import 'package:auravibes_app/domain/repositories/workspace_selection_repository.dart';
import 'package:auravibes_app/features/workspaces/models/switch_status.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_switcher.dart';
import 'package:auravibes_app/features/workspaces/providers/last_workspace_selection_repository_provider.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/draft_exit_registry_provider.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class _SelectionRepository implements WorkspaceSelectionRepository {
  String? selected = 'original';
  final attempts = <String>[];
  final pending = <Completer<void>>[];

  @override
  Future<String?> read() async => selected;

  @override
  Future<void> clearIfMatches(String workspaceId) async {
    if (selected == workspaceId) selected = null;
  }

  @override
  Future<void> save(String workspaceId) async {
    attempts.add(workspaceId);
    if (workspaceId == 'original') {
      selected = workspaceId;

      return;
    }
    final request = Completer<void>();
    pending.add(request);
    await request.future;
    selected = workspaceId;
  }
}

class _Editor extends StatefulWidget {
  const new();
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  final controller = TextEditingController();
  final guard = DraftExitGuard();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    guard.bind(
      isDirty: () => controller.text.isNotEmpty,
      isSaving: () => false,
    );

    return DraftExitScope(
      guard: guard,
      child: Scaffold(body: TextField(controller: controller)),
    );
  }
}

Future<void> _pumpRouter(
  WidgetTester tester,
  GoRouter router,
  ProviderContainer container,
) async {
  final _ = await tester.runAsync(
    () => tester.pumpWidget(
      EasyLocalization(
        child: Builder(
          builder: (context) => UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              builder: (_, child) => AuraLegacyMaterialBridge(
                child: child ?? const SizedBox.shrink(),
              ),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            ),
          ),
        ),
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        startLocale: const Locale('en'),
      ),
    ),
  );
  final _ = await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'workspace preflight cancels before writes and failed consent prompts '
    'on retry',
    (tester) async {
      final repository = _SelectionRepository();
      final registry = DraftExitRegistry();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/editor',
            builder: (_, _) => const _Editor(),
            onExit: (_, state) => registry.canExitRoute(state.uri),
          ),
          GoRoute(
            path: '/workspaces/:id/chat/new',
            builder: (_, _) => const Text('New workspace'),
          ),
        ],
        initialLocation: '/editor',
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [
          routerProvider.overrideWithValue(router),
          draftExitRegistryProvider.overrideWithValue(registry),
          lastWorkspaceSelectionRepositoryProvider.overrideWithValue(
            repository,
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(registry.dispose);
      await _pumpRouter(tester, router, container);
      final field = find.byType(TextField);
      await tester.enterText(field, 'Exact draft');
      final focus = tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode;
      final switcher = container.read(workspaceSwitcherProvider.notifier)
        ..switchToWorkspace('next');
      await tester.pump(const Duration(milliseconds: 350));
      final _ = await tester.pumpAndSettle();
      expect(repository.attempts, isEmpty);
      await tester.tap(find.text('Keep editing'));
      final _ = await tester.pumpAndSettle();
      expect(repository.selected, 'original');
      expect(router.state.uri.path, '/editor');
      expect(focus.hasFocus, isTrue);
      expect(find.text('Exact draft'), findsOneWidget);
      switcher.switchToWorkspace('next');
      await tester.pump(const Duration(milliseconds: 350));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes'));
      final _ = await tester.pumpAndSettle();
      expect(repository.attempts, ['next']);
      expect(focus.hasFocus, isFalse);
      final editorScope = find.byType(DraftExitScope);
      expect(
        tester
            .widget<AbsorbPointer>(
              find
                  .descendant(
                    of: editorScope,
                    matching: find.byType(AbsorbPointer),
                  )
                  .first,
            )
            .absorbing,
        isTrue,
      );
      final _ = await tester.sendKeyEvent(.tab);
      final _ = await tester.pumpAndSettle();
      expect(focus.hasFocus, isFalse);
      expect(focus.canRequestFocus, isFalse);
      final _ = await tester.sendKeyEvent(.keyA, character: 'a');
      expect(find.text('Exact draft'), findsOneWidget);
      router.go('/workspaces/bypass/chat/new');
      final _ = await tester.pumpAndSettle();
      expect(router.state.uri.path, '/editor');
      repository.pending.first.completeError(StateError('Selection failed'));
      final _ = await tester.pumpAndSettle();
      expect(repository.selected, 'original');
      expect(router.state.uri.path, '/editor');
      expect(find.text('Exact draft'), findsOneWidget);
      expect(focus.hasFocus, isTrue);
      await tester.enterText(field, 'Revised draft');
      switcher.switchToWorkspace('next');
      await tester.pump(const Duration(milliseconds: 350));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Keep editing'), findsOneWidget);
      await tester.tap(find.text('Discard changes'));
      final _ = await tester.pumpAndSettle();
      repository.pending.last.complete();
      final _ = await tester.pumpAndSettle();
      expect(repository.selected, 'next');
      expect(find.text('New workspace'), findsOneWidget);
      expect(find.text('Keep editing'), findsNothing);
    },
  );

  testWidgets(
    'stale persistence rolls back original selection before latest failure',
    (tester) async {
      final repository = _SelectionRepository();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/original',
            builder: (_, _) => const Text('Original workspace'),
          ),
          GoRoute(
            path: '/workspaces/:id/chat/new',
            builder: (_, _) => const Text('Other workspace'),
          ),
        ],
        initialLocation: '/original',
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [
          routerProvider.overrideWithValue(router),
          lastWorkspaceSelectionRepositoryProvider.overrideWithValue(
            repository,
          ),
        ],
      );
      addTearDown(container.dispose);
      await _pumpRouter(tester, router, container);
      final switcher = container.read(workspaceSwitcherProvider.notifier)
        ..switchToWorkspace('stale');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      switcher.switchToWorkspace('latest');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      repository.pending.first.complete();
      final _ = await tester.pumpAndSettle();
      expect(repository.attempts, ['stale', 'original', 'latest']);
      expect(repository.selected, 'original');
      repository.pending.last.completeError(StateError('Latest save failed'));
      final _ = await tester.pumpAndSettle();
      expect(repository.selected, 'original');
      expect(router.state.uri.path, '/original');
      expect(find.text('Original workspace'), findsOneWidget);
      expect(
        container.read(workspaceSwitcherProvider).status,
        SwitchStatus.error,
      );
    },
  );

  testWidgets(
    'retained parent and hidden shell drafts do not prompt for another '
    'active route',
    (tester) async {
      final registry = DraftExitRegistry();
      StatefulNavigationShell? shell;
      final router = GoRouter(
        routes: [
          StatefulShellRoute.indexedStack(
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/editor',
                    builder: (_, _) => const _Editor(),
                    onExit: (_, state) => registry.canExitRoute(state.uri),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/other',
                    builder: (_, _) => const Text('Other branch'),
                  ),
                ],
              ),
            ],
            builder: (_, _, navigationShell) {
              shell = navigationShell;

              return navigationShell;
            },
          ),
          GoRoute(path: '/child', builder: (_, _) => const Text('Child setup')),
          GoRoute(
            path: '/destination',
            builder: (_, _) => const Text('Destination'),
          ),
        ],
        initialLocation: '/editor',
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [draftExitRegistryProvider.overrideWithValue(registry)],
      );
      addTearDown(container.dispose);
      addTearDown(registry.dispose);
      await _pumpRouter(tester, router, container);
      await tester.enterText(find.byType(TextField), 'Retained draft');
      final child = router.push<void>('/child');
      final _ = await tester.pumpAndSettle();
      expect(find.text('Keep editing'), findsNothing);
      expect(await registry.canExitActive(router), isTrue);
      router.pop();
      await child;
      final _ = await tester.pumpAndSettle();
      expect(find.text('Retained draft'), findsOneWidget);
      final consent = registry.canExitActive(router);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Keep editing'), findsOneWidget);
      await tester.tap(find.text('Discard changes'));
      expect(await consent, isTrue);
      shell?.goBranch(1);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Other branch'), findsOneWidget);
      expect(await registry.canExitActive(router), isTrue);
      router.go('/destination');
      final _ = await tester.pumpAndSettle();
      expect(find.text('Destination'), findsOneWidget);
      expect(find.text('Keep editing'), findsNothing);
    },
  );
}
