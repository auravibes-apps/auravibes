import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/router/draft_exit_registry_provider.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class _Draft extends StatefulWidget {
  const new();
  @override
  State<_Draft> createState() => _DraftState();
}

class _DraftState extends State<_Draft> {
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

void main() {
  testWidgets(
    'same URI child unregisters only itself and leaves the parent draft '
    'guarded',
    (tester) async {
      final registry = DraftExitRegistry();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/editor',
            builder: (_, _) => const _Draft(),
            onExit: (_, state) => registry.canExitRoute(state.uri),
          ),
          GoRoute(path: '/done', builder: (_, _) => const Text('Done')),
        ],
        initialLocation: '/editor',
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [draftExitRegistryProvider.overrideWithValue(registry)],
      );
      addTearDown(container.dispose);
      addTearDown(registry.dispose);
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
      await tester.enterText(find.byType(TextField), 'Parent draft');
      final child = router.push<void>('/editor');
      final _ = await tester.pumpAndSettle();
      expect(find.text('Keep editing'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Child draft');
      router.pop();
      final _ = await tester.pumpAndSettle();
      expect(find.text('Keep editing'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Child draft'), findsOneWidget);
      router.pop();
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes'));
      final _ = await tester.pumpAndSettle();
      await child;
      expect(find.text('Parent draft'), findsOneWidget);
      router.go('/done');
      final _ = await tester.pumpAndSettle();
      expect(find.text('Done'), findsNothing);
      expect(find.text('Keep editing'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Parent draft'), findsOneWidget);
    },
  );
}
