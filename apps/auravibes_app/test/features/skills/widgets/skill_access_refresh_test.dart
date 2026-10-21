import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_app/features/skills/providers/skill_access_summary_provider.dart';
import 'package:auravibes_app/features/skills/widgets/skill_access_status_view.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('returning from Connections refreshes connector readiness', (
    tester,
  ) async {
    var connectionReady = false;
    var reads = 0;
    var returns = 0;
    const workspaceId = 'workspace';
    const skillId = 'skill';
    final destination = ServiceConnectionsRoute(
      workspaceId: workspaceId,
      view: 'connectors',
    ).location;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: SkillAccessStatusView(
              workspaceId: workspaceId,
              skillId: skillId,
              showDependencies: true,
              onChanged: () => returns++,
            ),
          ),
        ),
        GoRoute(
          path: Uri.parse(destination).path,
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () {
                connectionReady = true;
                context.pop(true);
              },
              child: const Text('Save Connection'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: Builder(
            builder: (context) => MaterialApp.router(
              routerConfig: router,
              builder: (_, child) => AuraThemeScope(
                theme: .light,
                child: child ?? const SizedBox.shrink(),
              ),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            ),
          ),
          overrides: [
            skillAccessSummaryProvider(workspaceId, skillId).overrideWith((
              _,
            ) async {
              reads++;

              return SkillAccessSummary(
                status: connectionReady ? .saved : .missing,
                instructionsAvailable: connectionReady,
                tools: [
                  SkillToolAccess(
                    id: 'connector/custom/search',
                    title: 'Search',
                    status: connectionReady ? .available : .missing,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(reads, 1);
    expect(find.text('Needs access'), findsOneWidget);
    await tester.tap(find.text('Manage Connections'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, Uri.parse(destination).path);

    await tester.tap(find.text('Save Connection'));
    await tester.pumpAndSettle();
    expect(returns, 1);
    expect(reads, 2);
    expect(find.text('Saved access available'), findsOneWidget);
    expect(find.text('Manage Connections'), findsNothing);
  });
}
