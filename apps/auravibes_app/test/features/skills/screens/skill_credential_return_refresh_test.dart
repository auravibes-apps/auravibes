import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/skill_credential_entity.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/providers/skill_access_summary_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credentials_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_resources_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_template_tools_provider.dart';
import 'package:auravibes_app/features/skills/screens/skill_detail_screen.dart';
import 'package:auravibes_app/features/skills/usecases/assess_skill_access_usecase.dart';
import 'package:auravibes_app/features/skills/usecases/list_app_skill_credential_candidates_usecase.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  for (final app in [false, true]) {
    for (final entry in ['Add Credential', 'Set up credentials']) {
      testWidgets('retained credential displays converge: app=$app $entry', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(1200, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var saved = false;
        var candidateReads = 0;
        var credentialReads = 0;
        final skillId = app ? 'jina' : 'custom-skill';
        final route = ServiceConnectionCreateRoute(
          workspaceId: 'owned-workspace',
          type: app ? 'appSkillCredential' : 'skillCredential',
          credentialDefinitionId: app ? null : 'saved-definition',
        );
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => SkillDetailScreen(
                workspaceId: 'owned-workspace',
                skillId: skillId,
              ),
            ),
            GoRoute(
              path: Uri.parse(route.location).path,
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () {
                    saved = true;
                    context.pop(true);
                  },
                  child: const Text('Persist credential and return'),
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
                skillDetailProvider.overrideWith((_, _) async => _skill(app)),
                skillResourcesProvider.overrideWith((_, _) async => []),
                skillTemplateToolsProvider.overrideWith((_, _) async => []),
                skillCredentialDefinitionsProvider.overrideWith(
                  (_, _) async => [_definition()],
                ),
                skillCredentialDefinitionProvider.overrideWith(
                  (_, _) async => _definition(),
                ),
                skillCredentialsForDefinitionProvider.overrideWith((
                  _,
                  args,
                ) async {
                  expect(args.$1, 'owned-workspace');
                  expect(args.$2, 'saved-definition');
                  credentialReads++;

                  return saved ? [_credential()] : [];
                }),
                appSkillCredentialCandidatesProvider.overrideWith((
                  _,
                  args,
                ) async {
                  expect(args.$1, 'owned-workspace');
                  expect(args.$2, 'jina');
                  candidateReads++;

                  return saved
                      ? [
                          const AppSkillCredentialCandidate(
                            id: 'saved',
                            name: 'Saved',
                          ),
                        ]
                      : [];
                }),
                assessSkillAccessUsecaseProvider.overrideWith(
                  (_, _) => AssessSkillAccessUsecase(
                    hasCredential: (_) async => saved,
                    hasAppCredential: (_) async => saved,
                  ),
                ),
              ],
            ),
          );
        });
        final _ = await tester.pumpAndSettle();
        expect(find.text('Needs access'), findsOneWidget);
        if (app) {
          expect(
            find.text(
              'Saved access does not verify remote access. '
              'Chat instructions are prepared separately.',
            ),
            findsOneWidget,
          );
        } else {
          expect(
            find.text('This skill needs a credential before it can be loaded.'),
            findsOneWidget,
          );
        }
        if (!app) {
          await tester.enterText(
            find.widgetWithText(AuraInput, 'Title'),
            'Parent draft',
          );
          await tester.tap(find.text('Edit content'));
          final _ = await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextFormField).last,
            'Draft instructions',
          );
          final _ = await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Apply changes'));
          final _ = await tester.pumpAndSettle();
          await tester.tap(find.text('Credential is optional'));
          final _ = await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.text(entry));
        await tester.tap(find.text(entry));
        final _ = await tester.pumpAndSettle();
        expect(router.state.uri.path, Uri.parse(route.location).path);
        expect(router.state.uri.queryParameters, {
          ...Uri.parse(route.location).queryParameters,
          if (app) 'appSkillId': 'jina',
        });
        await tester.tap(find.text('Persist credential and return'));
        final _ = await tester.pumpAndSettle();
        expect(find.text('Saved access available'), findsOneWidget);
        expect(find.text('1 credential configured'), findsOneWidget);
        expect(find.text('Needs access'), findsNothing);
        expect(find.text('Set up credentials'), findsNothing);
        expect(
          find.text('This skill needs a credential before it can be loaded.'),
          findsNothing,
        );
        if (app) {
          expect(candidateReads, 2);
        } else {
          expect(credentialReads, 2);
          expect(
            tester
                .widget<AuraInput>(find.widgetWithText(AuraInput, 'Title'))
                .controller
                ?.text,
            'Parent draft',
          );
          expect(
            tester
                .widget<AuraDropdownSelector<String>>(
                  find.byType(AuraDropdownSelector<String>),
                )
                .value,
            'saved-definition',
          );
          expect(
            tester
                .widget<AuraCheckboxListTile>(
                  find.widgetWithText(
                    AuraCheckboxListTile,
                    'Credential is optional',
                  ),
                )
                .value,
            isTrue,
          );
          expect(_skill(false).isCredentialOptional, isFalse);
          expect(_skill(false).title, 'Saved skill');
          expect(_skill(false).content, 'Instructions');
          await tester.tap(find.text('Edit content'));
          final _ = await tester.pumpAndSettle();
          expect(
            tester
                .widget<TextFormField>(find.byType(TextFormField).last)
                .controller
                ?.text,
            'Draft instructions',
          );
        }
      });
    }
  }
}

SkillDetail _skill(bool app) => SkillDetail(
  source: app ? .app : .user,
  id: app ? 'jina' : 'custom-skill',
  workspaceId: 'owned-workspace',
  kind: .template,
  title: 'Saved skill',
  slug: 'saved-skill',
  description: 'Description',
  content: 'Instructions',
  isEnabled: true,
  isCredentialOptional: false,
  credentialDefinitionId: app ? null : 'saved-definition',
  appTools: app
      ? const [
          AppSkillToolDefinition(
            slug: 'protected',
            title: 'Protected',
            description: '',
            requiresCredential: true,
          ),
        ]
      : const [],
);

SkillCredentialDefinitionEntity _definition() =>
    SkillCredentialDefinitionEntity(
      id: 'saved-definition',
      workspaceId: 'owned-workspace',
      title: 'Saved definition',
      slug: 'saved-definition',
      attributesJson: '{}',
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );

SkillCredentialEntity _credential() => SkillCredentialEntity(
  id: 'saved-credential',
  workspaceId: 'owned-workspace',
  credentialDefinitionId: 'saved-definition',
  name: 'Saved',
  attributes: const {},
  isEnabled: true,
  createdAt: .new(2026),
  updatedAt: .new(2026),
);
