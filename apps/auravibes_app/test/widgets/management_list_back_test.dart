import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/screens/skill_credential_definitions_screen.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_management_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

void main() {
  for (final isManager in [false, true]) {
    final label = isManager ? 'workspace manager' : 'credential definitions';
    testWidgets('$label shows Back only with a real predecessor', (
      tester,
    ) async {
      final listPath = isManager
          ? '/workspaces/A/more/manage-workspaces'
          : '/workspaces/A/more/skill-credential-definitions';
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/previous',
            builder: (_, _) => const Text('Predecessor'),
          ),
          GoRoute(
            path: listPath,
            builder: (_, _) => isManager
                ? const WorkspaceManagementScreen(workspaceId: 'A')
                : const SkillCredentialDefinitionsScreen(workspaceId: 'A'),
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
              skillCredentialDefinitionsProvider('A')
                  .overrideWith((_) => Future.value(const [])),
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
      expect(find.byKey(managerKey), isManager ? findsOneWidget : findsNothing);
      await tester.tap(find.byKey(backKey));
      final _ = await tester.pumpAndSettle();
      await popped;
      expect(find.text('Predecessor'), findsOneWidget);
      expect(router.state.uri.path, '/previous');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
