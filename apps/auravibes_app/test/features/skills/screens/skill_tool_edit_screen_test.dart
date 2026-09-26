// Required: Tests use numeric fixtures.
import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/features/skills/screens/skill_tool_edit_screen.dart';
import 'package:auravibes_app/features/skills/usecases/create_skill_template_tool_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guards all skill tool exit paths', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(name: 'Test Workspace', type: .local),
    );
    final definition = await database.skillCredentialDefinitionsDao
        .createDefinition(
          .insert(
            workspaceId: workspace.id,
            title: 'Example Service',
            slug: 'example_service',
            attributesJson: jsonEncode({
              'api_key': {'description': 'API key'},
            }),
          ),
        );
    final skill = await SkillsRepository(database).createSkill(
      workspace.id,
      .new(
        kind: SkillKind.template,
        title: 'Example Services',
        description: 'Call Example APIs',
        content: 'Use Example Services.',
        credentialDefinitionId: definition.id,
      ),
    );
    final skillsRepository = SkillsRepository(database);
    final skillTemplateToolsRepository = SkillTemplateToolsRepository(database);
    final skillCredentialDefinitionsRepository =
        SkillCredentialDefinitionsRepository(database);
    final session = WorkspaceSession(
      LocalWorkspaceRef(localWorkspaceId: workspace.id),
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        workspaceSessionProvider(session).overrideWithValue(session),
        cloudWorkspaceStateGatewayProvider.overrideWith((_, _) async => null),
        cloudSkillStoreProvider(workspace.id).overrideWithValue(null),
        skillsRepositoryProvider.overrideWithValue(skillsRepository),
        skillTemplateToolsRepositoryProvider.overrideWithValue(
          skillTemplateToolsRepository,
        ),
        skillCredentialDefinitionsRepositoryProvider.overrideWithValue(
          skillCredentialDefinitionsRepository,
        ),
        skillDetailProvider(
          workspace.id,
          skill.id,
        ).overrideWith((_) async => SkillDetail.fromUserSkill(skill)),
        createSkillTemplateToolUsecaseProvider(workspace.id).overrideWithValue(
          CreateSkillTemplateToolUsecase(
            skillTemplateToolsRepository,
            skillsRepository: skillsRepository,
            skillCredentialDefinitionsRepository:
                skillCredentialDefinitionsRepository,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final createRouteGuard = SkillToolEditRouteGuard();
    final editRouteGuard = SkillToolEditRouteGuard();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/workspaces/:workspaceId/more/skills/:skillId',
          builder: (context, state) => const Text('Skill detail'),
        ),
        GoRoute(
          path: '/workspaces/:workspaceId/more/skills/:skillId/tools/new',
          builder: (context, state) => SkillToolEditScreen(
            workspaceId: state.pathParameters['workspaceId']!,
            skillId: state.pathParameters['skillId']!,
            routeExitGuard: createRouteGuard,
          ),
          onExit: (context, _) => createRouteGuard.canExit(context),
        ),
        GoRoute(
          path: '/workspaces/:workspaceId/more/skills/:skillId/tools/:toolId/edit',
          builder: (context, state) => SkillToolEditScreen(
            workspaceId: state.pathParameters['workspaceId']!,
            skillId: state.pathParameters['skillId']!,
            toolId: state.pathParameters['toolId'],
            routeExitGuard: editRouteGuard,
          ),
          onExit: (context, _) => editRouteGuard.canExit(context),
        ),
      ],
      initialLocation: '/workspaces/${workspace.id}/more/skills/${skill.id}',
    );
    addTearDown(router.dispose);

    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        EasyLocalization(
          child: Builder(
            builder: (context) {
              return UncontrolledProviderScope(
                container: container,
                child: MaterialApp.router(
                  routerConfig: router,
                  builder: (_, child) => AuraLegacyMaterialBridge(
                    child: AuraSnackBarHost(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                  locale: context.locale,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                ),
              );
            },
          ),
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          useOnlyLangCode: true,
          useFallbackTranslations: true,
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    final _ = router.push(
      '/workspaces/${workspace.id}/more/skills/${skill.id}/tools/new',
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Request body'), findsOneWidget);
    expect(find.text('AI agent inputs'), findsOneWidget);
    expect(find.text('URL template JSON'), findsNothing);
    expect(find.text('Inputs JSON'), findsNothing);
    expect(find.text('Requires credential'), findsOneWidget);

    Future<void> enterLabeledField(
      String label,
      String value, {
      bool last = false,
    }) async {
      final input = find.byWidgetPredicate((widget) {
        if (widget is! AuraInput) return false;
        final labelWidget = widget.label;

        return labelWidget is Text && labelWidget.data == label;
      });
      final selectedInput = last ? input.last : input.first;
      await tester.scrollUntilVisible(
        selectedInput,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(selectedInput, value);
      final _ = await tester.pumpAndSettle();
    }

    await enterLabeledField('Title', 'Find Company');
    await tester.tap(find.text('Edit description'));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).last,
      'Find company records.',
    );
    await tester.tap(find.byIcon(Icons.save_outlined).last);
    final _ = await tester.pumpAndSettle();
    await enterLabeledField('URL', 'https://example.com/company');
    await tester.tap(find.text('GET'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('POST').last);
    final _ = await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add header'));
    await tester.tap(find.text('Add header'));
    final _ = await tester.pumpAndSettle();
    await enterLabeledField('Name', 'Authorization');
    await enterLabeledField('Value', 'Bearer {{ credential.api_key }}');
    await tester.ensureVisible(find.text('Add query parameter'));
    await tester.tap(find.text('Add query parameter'));
    final _ = await tester.pumpAndSettle();
    await enterLabeledField('Key', 'token');
    await enterLabeledField('Value', '{credential:api_key}', last: true);
    await enterLabeledField(
      'Request body',
      '{"company_id":{{ input.company_id | json }}}',
    );
    await enterLabeledField('Input name', 'company_id');
    await enterLabeledField('Description', 'Company id');
    await tester.tap(find.text('Requires credential'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save_outlined));
    final _ = await tester.pumpAndSettle();

    final tool = await SkillTemplateToolsRepository(database)
        .getToolBySlug(skill.id, 'find_company');
    final templateJson = (tool ?? fail('tool missing')).templateJson;
    expect(tool.description, 'Find company records.');
    expect(jsonDecode(templateJson), {
      'url': 'https://example.com/company',
      'method': 'POST',
      'headers': {'Authorization': 'Bearer {{ credential.api_key }}'},
      'query': {'token': '{{ credential.api_key }}'},
      'body': '{"company_id":{{ input.company_id | json }}}',
      'bodyFormat': 'json',
    });
    expect(jsonDecode(tool.inputsJson), {
      'company_id': {'type': 'string', 'description': 'Company id'},
    });
    expect(tool.requiresCredential, isTrue);

    final editorLocation =
        '/workspaces/${workspace.id}/more/skills/${skill.id}/tools/${tool.id}/edit';
    Future<void> openToolEditor() async {
      final _ = router.push(editorLocation);
      final _ = await tester.pumpAndSettle();
    }

    Future<void> goBack() async {
      final _ = await tester.binding.handlePopRoute();
      final _ = await tester.pumpAndSettle();
    }

    await openToolEditor();
    await goBack();
    expect(find.byType(AuraConfirmDialog), findsNothing);
    expect(find.text('Skill detail'), findsOneWidget);

    await openToolEditor();
    await tester.ensureVisible(find.text('Edit raw definition JSON'));
    await tester.tap(find.text('Edit raw definition JSON'));
    final _ = await tester.pumpAndSettle();
    await goBack();
    expect(find.byType(AuraConfirmDialog), findsNothing);
    expect(find.text('Skill detail'), findsOneWidget);

    await openToolEditor();
    await tester.ensureVisible(find.text('Add query parameter'));
    await tester.tap(find.text('Add query parameter'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove').last);
    final _ = await tester.pumpAndSettle();
    await goBack();
    expect(find.byType(AuraConfirmDialog), findsNothing);
    expect(find.text('Skill detail'), findsOneWidget);

    await openToolEditor();
    await enterLabeledField('Description', 'Company identifier');
    await goBack();
    expect(find.byType(AuraConfirmDialog), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();
    await enterLabeledField('Description', 'Company id');
    await goBack();
    expect(find.byType(AuraConfirmDialog), findsNothing);
    expect(find.text('Skill detail'), findsOneWidget);

    await openToolEditor();
    await enterLabeledField('Description', 'Company identifier');
    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();
    expect(find.byType(AuraConfirmDialog), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();
    await enterLabeledField('Description', 'Company id');
    await goBack();
    expect(find.byType(AuraConfirmDialog), findsNothing);
    expect(find.text('Skill detail'), findsOneWidget);

    await openToolEditor();
    await enterLabeledField('Description', 'Company identifier');
    router.go('/workspaces/${workspace.id}/more/skills/${skill.id}');
    final _ = await tester.pumpAndSettle();
    expect(find.byType(AuraConfirmDialog), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();
    expect(find.byType(SkillToolEditScreen), findsOneWidget);
    await enterLabeledField('Description', 'Company id');
    await goBack();
    expect(find.byType(AuraConfirmDialog), findsNothing);
    expect(find.text('Skill detail'), findsOneWidget);

    await openToolEditor();
    await enterLabeledField('Description', 'Company identifier');
    router.go('/workspaces/${workspace.id}/more/skills/${skill.id}');
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    final _ = await tester.pumpAndSettle();
    expect(find.byType(SkillToolEditScreen), findsNothing);
    expect(find.text('Skill detail'), findsOneWidget);
    final persistedTool = await skillTemplateToolsRepository.getToolBySlug(
      skill.id,
      'find_company',
    );
    expect(persistedTool?.inputsJson, tool.inputsJson);

    const secret = 'private-tool-secret';
    await openToolEditor();
    await tester.ensureVisible(find.text('Add header'));
    await tester.tap(find.text('Add header'));
    final _ = await tester.pumpAndSettle();
    await enterLabeledField('Name', 'X-Test-Header', last: true);
    final addedHeaderName = find.byWidgetPredicate((widget) {
      if (widget is! AuraInput) return false;
      final label = widget.label;

      return label is Text && label.data == 'Name';
    }).last;
    final addedHeaderRow = find
        .ancestor(of: addedHeaderName, matching: find.byType(Row))
        .first;
    final addedHeaderFields = find.descendant(
      of: addedHeaderRow,
      matching: find.byType(TextFormField),
    );
    await tester.enterText(addedHeaderFields.last, secret);
    final _ = await tester.pumpAndSettle();
    await goBack();

    final dialog = find.byType(AuraConfirmDialog);
    expect(dialog, findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text(secret)),
      findsNothing,
    );
    await tester.tap(find.text('Keep editing'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: addedHeaderRow, matching: find.byTooltip('Remove')),
    );
    final _ = await tester.pumpAndSettle();
    await goBack();
    expect(find.byType(AuraConfirmDialog), findsNothing);
    expect(find.text('Skill detail'), findsOneWidget);
  });
}
