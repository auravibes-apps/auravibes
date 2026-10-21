import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_app/features/skills/providers/skill_access_summary_provider.dart';
import 'package:auravibes_app/features/skills/widgets/skill_access_status_view.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('missing connector opens its connection form', (tester) async {
    final connector = connectorDefinitions.firstWhere(
      (item) =>
          item.compatibleModelProviderIds.isEmpty &&
          item.tools.any((tool) => tool.urlTemplate != null),
    );
    final connectorTool = connector.tools.firstWhere(
      (tool) => tool.urlTemplate != null,
    );
    final toolId = connectorToolId(connector, connectorTool);
    final expected = ServiceConnectionCreateRoute(
      workspaceId: 'workspace',
      type: 'connector',
      connectorId: connector.identifier,
    ).location;
    var returned = false;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: SkillAccessStatusView(
              workspaceId: 'workspace',
              skillId: 'skill',
              showDependencies: true,
              onChanged: () => returned = true,
            ),
          ),
        ),
        GoRoute(
          path: Uri.parse(expected).path,
          builder: (_, _) => const Text('Connection form'),
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
            skillAccessSummaryProvider('workspace', 'skill').overrideWith(
              (_) async => SkillAccessSummary(
                status: .missing,
                instructionsAvailable: false,
                tools: [
                  SkillToolAccess(
                    id: toolId,
                    title: connectorTool.title,
                    status: .missing,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage Connections'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, Uri.parse(expected).path);
    expect(find.text('Connection form'), findsOneWidget);
    router.pop(true);
    await tester.pumpAndSettle();
    expect(returned, isTrue);
  });
}
