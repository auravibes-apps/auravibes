import 'package:auravibes_app/domain/entities/skill_template_tool_entity.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/providers/skill_access_summary_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/usecases/assess_skill_access_usecase.dart';
import 'package:auravibes_app/features/skills/widgets/skill_access_status_view.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('saved recovery refreshes cached tool requirements', (
    tester,
  ) async {
    var requiresCredential = true;
    var toolReads = 0;
    var returns = 0;
    final destination = SkillToolEditRoute(
      workspaceId: 'owned-workspace',
      skillId: 'saved-skill',
      toolId: 'affected-tool',
    ).location;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Column(
              children: [
                SkillAccessStatusView(
                  workspaceId: 'owned-workspace',
                  skillId: 'saved-skill',
                  showDependencies: true,
                  onChanged: () => returns++,
                ),
                Consumer(
                  builder: (_, ref, _) {
                    final tools = ref.watch(
                      skillTemplateToolsProvider(
                        'owned-workspace',
                        'saved-skill',
                      ),
                    );

                    return Text('Tools card: ${tools.value?.length}');
                  },
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: Uri.parse(destination).path,
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () {
                requiresCredential = false;
                context.pop(true);
              },
              child: const Text('Persist repair and return'),
            ),
          ),
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
            skillDetailProvider.overrideWith(
              (_, _) async => const SkillDetail(
                id: 'saved-skill',
                workspaceId: 'owned-workspace',
                source: .user,
                kind: .template,
                title: 'Saved skill',
                slug: 'saved-skill',
                description: '',
                content: 'Instructions',
                isEnabled: true,
                isCredentialOptional: false,
              ),
            ),
            assessSkillAccessUsecaseProvider.overrideWith(
              (_, _) => AssessSkillAccessUsecase(
                hasCredential: (_) async => false,
                hasAppCredential: (_) async => false,
              ),
            ),
            skillTemplateToolsProvider.overrideWith((_, _) async {
              toolReads++;

              return [
                SkillTemplateToolEntity(
                  id: 'affected-tool',
                  skillId: 'saved-skill',
                  templateType: .url,
                  title: 'Affected tool',
                  description: '',
                  slug: 'affected-tool',
                  isEnabled: true,
                  requiresCredential: requiresCredential,
                  createdAt: .new(2026),
                  updatedAt: .new(2026),
                ),
              ];
            }),
          ],
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    expect(find.text('Tool needs access'), findsOneWidget);
    await tester.tap(find.text('Set up credentials'));
    final _ = await tester.pumpAndSettle();
    expect(router.state.uri.path, Uri.parse(destination).path);
    router.pop(false);
    final _ = await tester.pumpAndSettle();
    expect(toolReads, 1);
    expect(requiresCredential, isTrue);
    expect(find.text('Tool needs access'), findsOneWidget);
    await tester.tap(find.text('Set up credentials'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Persist repair and return'));
    final _ = await tester.pumpAndSettle();
    expect(returns, 2);
    expect(toolReads, 2);
    expect(requiresCredential, isFalse);
    expect(
      find.text('Tool needs access'),
      findsNothing,
      reason: 'Saved recovery must refresh persisted tool requirements',
    );
    expect(find.text('No access required'), findsOneWidget);
  });
}
