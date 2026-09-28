// Required: Tests use numeric fixtures.
import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/screens/skill_detail_screen.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('prompts for dirty user skills and stays clean after revert', (
    tester,
  ) async {
    final fixture = await _createUserSkillFixture();
    addTearDown(fixture.dispose);

    final _ = await tester.runAsync(
      () => tester.pumpWidget(_SkillUnsavedChangesApp(fixture: fixture)),
    );
    final _ = await tester.pumpAndSettle();

    final title = _titleField();
    await tester.enterText(title, 'Changed title');
    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Unsaved changes'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsNothing);

    await tester.enterText(title, 'Example Skill');
    await tester.tap(find.byIcon(Icons.arrow_back));
    final _ = await tester.pumpAndSettle();

    expect(find.text('Unsaved changes'), findsNothing);
  });
}

Finder _titleField() => find.byWidgetPredicate((widget) {
  if (widget is! AuraInput) return false;
  final label = widget.label;

  return label is Text && label.data == 'Title';
});

class const _SkillUnsavedChangesApp({required final _SkillFixture fixture})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => EasyLocalization(
    key: UniqueKey(),
    child: Builder(
      builder: (context) => UncontrolledProviderScope(
        container: fixture.container,
        child: MaterialApp(
          home: Navigator(
            initialRoute: '/editor',
            onGenerateInitialRoutes: (_, initialRoute) => [
              MaterialPageRoute(builder: (_) => const SizedBox.shrink()),
              MaterialPageRoute(
                builder: (_) => SkillDetailScreen(
                  workspaceId: fixture.workspaceId,
                  skillId: fixture.skillId,
                ),
                settings: .new(name: initialRoute),
              ),
            ],
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (_) => SkillDetailScreen(
                workspaceId: fixture.workspaceId,
                skillId: fixture.skillId,
              ),
              settings: settings,
            ),
          ),
          builder: (context, child) =>
              AuraSnackBarHost(child: child ?? const SizedBox.shrink()),
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
        ),
      ),
    ),
    supportedLocales: const [Locale('en')],
    path: 'assets/i18n',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useOnlyLangCode: true,
    useFallbackTranslations: true,
  );
}

Future<_SkillFixture> _createUserSkillFixture() async {
  final fixture = await _createWorkspaceFixture();
  final skill = await SkillsRepository(fixture.database).createSkill(
    fixture.workspaceId,
    const .new(
      kind: SkillKind.template,
      title: 'Example Skill',
      description: 'Example description.',
      content: 'Example content.',
    ),
  );

  return fixture.withSkill(skill.id);
}

Future<_SkillFixture> _createWorkspaceFixture() async {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  final workspace = await WorkspaceRepository(database).createWorkspace(
    const WorkspaceToCreate(name: 'Test Workspace', type: .local),
  );
  final session = WorkspaceSession(
    LocalWorkspaceRef(localWorkspaceId: workspace.id),
  );
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      workspaceSessionProvider(session).overrideWithValue(session),
      cloudWorkspaceStateGatewayProvider.overrideWith((_, _) async => null),
      cloudSkillStoreProvider(workspace.id).overrideWithValue(null),
    ],
  );

  return _SkillFixture(
    database: database,
    container: container,
    workspaceId: workspace.id,
  );
}

class _SkillFixture {
  const new({
    required this.database,
    required this.container,
    required this.workspaceId,
    this.skillId,
  });

  final AppDatabase database;
  final ProviderContainer container;
  final String workspaceId;
  final String? skillId;

  _SkillFixture withSkill(String id) => _SkillFixture(
    database: database,
    container: container,
    workspaceId: workspaceId,
    skillId: id,
  );

  Future<void> dispose() async {
    container.dispose();
    await database.close();
  }
}
