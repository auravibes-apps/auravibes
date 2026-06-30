// Required: Tests use numeric fixtures.
import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_template_tools_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/skills/screens/skill_tool_edit_screen.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creates template tool from structured fields', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(
        name: 'Test Workspace',
        type: WorkspaceType.local,
      ),
    );
    final definition = await database.skillCredentialDefinitionsDao
        .createDefinition(
          SkillCredentialDefinitionsCompanion.insert(
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
      SkillToCreate(
        kind: SkillKind.template,
        title: 'Example Services',
        description: 'Call Example APIs',
        content: 'Use Example Services.',
        credentialDefinitionId: definition.id,
      ),
    );
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
          ),
        ),
      ],
      initialLocation: '/workspaces/${workspace.id}/more/skills/${skill.id}',
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      EasyLocalization(
        child: Builder(
          builder: (context) {
            return UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                routerConfig: router,
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

    Future<void> enterLabeledField(String label, String value) async {
      final input = find.byWidgetPredicate(
        (widget) {
          if (widget is! AuraInput) return false;
          final labelWidget = widget.label;

          return labelWidget is Text && labelWidget.data == label;
        },
      ).first;
      await tester.scrollUntilVisible(
        input,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final field = find.descendant(
        of: input,
        matching: find.byType(TextFormField),
      );
      await tester.enterText(field, value);
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
    await tester.ensureVisible(find.text('Add query parameter'));
    await tester.tap(find.text('Add query parameter'));
    final _ = await tester.pumpAndSettle();
    await enterLabeledField('Key', 'token');
    await enterLabeledField('Value', '{credential:api_key}');
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

    final tool = await SkillTemplateToolsRepository(
      database,
    ).getToolBySlug(skill.id, 'find_company');
    final templateJson = (tool ?? fail('tool missing')).templateJson;
    expect(tool.description, 'Find company records.');
    expect(jsonDecode(templateJson), {
      'url': 'https://example.com/company',
      'method': 'POST',
      'query': {'token': '{{ credential.api_key }}'},
      'body': '{"company_id":{{ input.company_id | json }}}',
      'bodyFormat': 'json',
    });
    expect(jsonDecode(tool.inputsJson), {
      'company_id': {
        'type': 'string',
        'description': 'Company id',
      },
    });
    expect(tool.requiresCredential, isTrue);
  });
}
