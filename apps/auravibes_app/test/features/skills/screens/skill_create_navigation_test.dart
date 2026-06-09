// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository_impl.dart';
import 'package:auravibes_app/data/repositories/skills_repository_impl.dart';
import 'package:auravibes_app/data/repositories/workspace_repository_impl.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/skills/screens/skill_detail_screen.dart';
import 'package:auravibes_app/features/skills/screens/skills_screen.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creating a skill leaves the create page', (tester) async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    final workspace = await WorkspaceRepositoryImpl(database).createWorkspace(
      const WorkspaceToCreate(
        name: 'Test Workspace',
        type: WorkspaceType.local,
      ),
    );
    final _ =
        await SkillCredentialDefinitionsRepositoryImpl(
          database,
        ).createDefinition(
          workspace.id,
          const SkillCredentialDefinitionToCreate(
            title: 'Example Service',
            attributesJson: '{"api_key":{"description":"API key"}}',
          ),
        );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/workspaces/:workspaceId/more/skills/new',
          builder: (context, state) => SkillDetailScreen(
            workspaceId: state.pathParameters['workspaceId']!,
          ),
        ),
        GoRoute(
          path: '/workspaces/:workspaceId/more/skills/:skillId',
          builder: (context, state) => SkillDetailScreen(
            workspaceId: state.pathParameters['workspaceId']!,
            skillId: state.pathParameters['skillId'],
          ),
        ),
        GoRoute(
          path: '/workspaces/:workspaceId/more/skills',
          builder: (context, state) => SkillsScreen(
            workspaceId: state.pathParameters['workspaceId']!,
          ),
        ),
      ],
      initialLocation: '/workspaces/${workspace.id}/more/skills',
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

    await tester.tap(find.byIcon(Icons.add));
    final _ = await tester.pumpAndSettle();
    final _ = await tester.pump();
    final _ = await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Write Summary');
    await tester.enterText(find.byType(TextFormField).at(1), 'Summarize text');
    await tester.enterText(find.byType(TextFormField).at(2), 'Summarize text.');
    await tester.tap(find.byIcon(Icons.save_outlined));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Unable to save skill'), findsNothing);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/workspaces/${workspace.id}/more/skills',
    );
    expect(find.text('Workspace Skills'), findsOneWidget);
    expect(find.text('Write Summary'), findsOneWidget);

    final skill = await SkillsRepositoryImpl(
      database,
    ).getSkillByTitle(workspace.id, 'Write Summary');
    expect(skill?.credentialDefinitionId, null);

    final _ = router.push(
      '/workspaces/${workspace.id}/more/skills/${skill!.id}',
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('No credential definition'), findsOneWidget);
    expect(
      find.text('This skill needs a credential before it can be loaded.'),
      findsNothing,
    );
  });
}
