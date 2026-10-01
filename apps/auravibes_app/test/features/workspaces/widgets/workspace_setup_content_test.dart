import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_auth_content.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_creation_draft_notifier.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_setup_content.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  for (final mode in ['Sign in', 'Create new account', 'Forgot password?']) {
    for (final success in [false, true]) {
      testWidgets(
        'management draft survives $mode success=$success and remount',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(1000, 1400));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          const task = '/workspaces/origin/more/manage-workspaces/create';
          final accounts = <CloudAccountSession>[];
          var mounts = 0;
          await tester.runAsync(
            () => tester.pumpWidget(
              TestableApp(
                child: Portal(
                  child: StatefulBuilder(
                    builder: (context, setState) => Scaffold(
                      body: ListView(
                        children: [
                          WorkspaceSetupContent(
                            taskId: task,
                            onCreated: (_) =>
                                fail('auth must not create a workspace'),
                            key: ValueKey<int>(mounts),
                          ),
                          TextButton(
                            onPressed: () => setState(() => mounts++),
                            child: const Text('Remount'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                overrides: [
                  cloudAccountsProvider.overrideWith((ref) async => accounts),
                ],
              ),
            ),
          );
          final _ = await tester.pumpAndSettle();
          await tester.enterText(find.byType(AuraInput), 'Management draft');
          await tester.tap(find.text('Create cloud'));
          final _ = await tester.pumpAndSettle();
          if (mode != 'Sign in') {
            await tester.ensureVisible(find.text(mode).last);
            await tester.tap(find.text(mode).last);
            final _ = await tester.pumpAndSettle();
          }
          final auth = tester.widget<CloudAccountAuthContent>(
            find.byType(CloudAccountAuthContent),
          );
          final container = ProviderScope.containerOf(
            tester.element(find.byType(CloudAccountAuthContent)),
          );
          if (success) {
            const account = CloudAccountSession(
              serverUrl: 'https://cloud.example',
              userId: 'same-id',
              email: 'person@example.com',
            );
            accounts.add(account);
            container.invalidate(cloudAccountsProvider);
            auth.onSignedIn(account);
          } else {
            auth.onCancel();
          }
          final _ = await tester.pumpAndSettle();
          expect(find.text('Management draft'), findsOneWidget);
          expect(
            container.read(workspaceCreationDraftProvider(task)).intent.name,
            'cloud',
          );
          expect(
            container.read(workspaceCreationDraftProvider('intro')).name,
            isEmpty,
          );
          await tester.ensureVisible(find.text('Remount'));
          await tester.tap(find.text('Remount'));
          final _ = await tester.pumpAndSettle();
          expect(find.text('Management draft'), findsOneWidget);
          if (success) {
            expect(
              find.text('person@example.com (https://cloud.example)'),
              findsOneWidget,
            );
            expect(find.text('Add another account'), findsOneWidget);
          }
        },
      );
    }
  }
}
