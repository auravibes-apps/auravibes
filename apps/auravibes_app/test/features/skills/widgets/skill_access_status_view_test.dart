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
  for (final kind in ['override', 'undefined', 'jina', 'anthropic']) {
    testWidgets('access recovery retains context for $kind', (tester) async {
      final isApp = kind == 'jina' || kind == 'anthropic';
      final skillId = isApp ? kind : 'saved-skill';
      final connectionType = switch (kind) {
        'jina' => 'appSkillCredential',
        'anthropic' => 'modelProvider',
        _ => 'skillCredential',
      };
      final definitionId = isApp ? null : 'tool-override';
      final expected = kind == 'undefined'
          ? SkillToolEditRoute(
              workspaceId: 'owned-workspace',
              skillId: skillId,
              toolId: 'affected-tool',
            ).location
          : ServiceConnectionCreateRoute(
              workspaceId: 'owned-workspace',
              type: connectionType,
              credentialDefinitionId: definitionId,
            ).location;
      var returned = false;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: SkillAccessStatusView(
                workspaceId: 'owned-workspace',
                skillId: skillId,
                showDependencies: true,
                isAppSkill: isApp,
                onChanged: () => returned = true,
              ),
            ),
          ),
          GoRoute(
            path: Uri.parse(expected).path,
            builder: (_, _) => const Text('Access destination'),
          ),
        ],
      );
      addTearDown(router.dispose);
      final _ = await tester.runAsync(() async {
        await tester.pumpWidget(
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
              skillAccessSummaryProvider.overrideWith(
                (_, _) async => SkillAccessSummary(
                  status: .partial,
                  instructionsAvailable: true,
                  tools: [
                    SkillToolAccess(
                      id: 'affected-tool',
                      title: 'Affected tool',
                      status: .missing,
                      credentialDefinitionId: kind == 'undefined'
                          ? null
                          : 'tool-override',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      });
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Set up credentials'));
      final _ = await tester.pumpAndSettle();
      expect(router.state.uri.path, Uri.parse(expected).path);
      expect(router.state.uri.queryParameters, {
        ...Uri.parse(expected).queryParameters,
        if (kind == 'jina') 'appSkillId': skillId,
      });
      expect(find.text('Access destination'), findsOneWidget);
      router.pop();
      final _ = await tester.pumpAndSettle();
      expect(returned, isTrue);
      expect(find.text('Set up credentials'), findsOneWidget);
    });
  }
}
