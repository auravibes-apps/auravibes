import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_management_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('workspace manager shows Back only with a real predecessor', (
    tester,
  ) async {
    const listPath = '/workspaces/A/manage-workspaces';
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/previous',
          pageBuilder: (_, state) => NoTransitionPage(
            child: const Text('Predecessor'),
            key: state.pageKey,
          ),
        ),
        GoRoute(
          path: listPath,
          pageBuilder: (_, state) => NoTransitionPage(
            child: const WorkspaceManagementScreen(workspaceId: 'A'),
            key: state.pageKey,
          ),
        ),
      ],
      initialLocation: listPath,
    );
    addTearDown(router.dispose);
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: Router.withConfig(config: router),
          overrides: [
            allWorkspacesProvider.overrideWith((_) => Stream.value(const [])),
            cloudAccountsProvider.overrideWith((_) => Future.value(const [])),
          ],
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    const backKey = ValueKey<String>('app_navigation_back');
    const managerKey = ValueKey<String>('workspace_management_back');
    expect(router.canPop(), isFalse);
    expect(find.byKey(backKey), findsNothing);
    expect(find.byKey(managerKey), findsNothing);
    router.go('/previous');
    final _ = await tester.pumpAndSettle();
    final popped = router.push<void>(listPath);
    final _ = await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);
    expect(find.byKey(backKey), findsOneWidget);
    expect(find.byKey(managerKey), findsOneWidget);
    await tester.tap(find.byKey(backKey));
    final _ = await tester.pumpAndSettle();
    await popped;
    expect(find.text('Predecessor'), findsOneWidget);
    expect(router.state.uri.path, '/previous');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
