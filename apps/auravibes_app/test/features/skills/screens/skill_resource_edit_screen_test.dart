import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_resources_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/skill_entity.dart';
import 'package:auravibes_app/domain/entities/skill_resource_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/markdown/screens/markdown_editor_screen.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_detail_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_resources_provider.dart';
import 'package:auravibes_app/features/skills/screens/skill_resource_edit_screen.dart';
import 'package:auravibes_app/features/skills/usecases/resolved_skill_resource.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show AppSkillResourceDefinition;
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../data/database/drift/database_test_utils.dart';

class _PendingCreate extends CreateSkillResourceUsecase {
  new() : super(null);
  final requests = <Completer<SkillResourceEntity>>[];
  SkillResourceToCreate? value;
  @override
  Future<SkillResourceEntity> call(
    String skillId,
    SkillResourceToCreate value,
  ) {
    this.value = value;
    final request = Completer<SkillResourceEntity>();
    requests.add(request);

    return request.future;
  }
}

class _Fixture {
  new(
    this.database,
    this.workspace,
    this.skill,
    this.resource, {
    required this.builtIn,
  });
  final AppDatabase database;
  final WorkspaceEntity workspace;
  final SkillEntity skill;
  final SkillResourceEntity? resource;
  final bool builtIn;
  String get resourceId => builtIn ? 'guide' : resource?.id ?? '';

  SkillDetail get _readOnlyDetail => .new(
    id: skill.id,
    workspaceId: workspace.id,
    source: .app,
    kind: .native,
    title: 'Built in parent',
    slug: 'built_in',
    description: 'Description',
    content: 'Instructions',
    isEnabled: true,
    isCredentialOptional: false,
    appResources: const [
      AppSkillResourceDefinition(
        slug: 'guide',
        title: 'Built in guide',
        description: 'Read only',
        content: 'Immutable instructions',
      ),
    ],
  );

  static Future<_Fixture> create({
    required AppDatabase database,
    bool existing = false,
    bool builtIn = false,
  }) async {
    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(name: 'Resource workspace', type: .local),
    );
    final skill = await SkillsRepository(database).createSkill(
      workspace.id,
      const SkillToCreate(
        kind: .template,
        title: 'Parent skill',
        description: 'Parent description',
        content: 'Persisted parent instructions',
      ),
    );
    final resource = existing
        ? await SkillResourcesRepository(database).createResource(
            skill.id,
            const SkillResourceToCreate(
              title: 'Existing resource',
              description: 'Description',
              content: '  Saved Markdown\n',
            ),
          )
        : null;

    return _Fixture(database, workspace, skill, resource, builtIn: builtIn);
  }

  Future<GoRouter> pump(WidgetTester tester, {_PendingCreate? pending}) async {
    final session = WorkspaceSession(
      LocalWorkspaceRef(localWorkspaceId: workspace.id),
    );
    final detail = builtIn ? _readOnlyDetail : SkillDetail.fromUserSkill(skill);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        workspaceSessionProvider(session).overrideWithValue(session),
        cloudWorkspaceStateGatewayProvider.overrideWith((_, _) async => null),
        cloudSkillStoreProvider(workspace.id).overrideWithValue(null),
        skillDetailProvider(
          workspace.id,
          skill.id,
        ).overrideWith((_) async => detail),
        if (resourceId.isNotEmpty)
          skillResourceProvider(
            workspace.id,
            resourceId,
          ).overrideWith((_) async => resource),
        if (pending != null)
          createSkillResourceUsecaseProvider(workspace.id)
              .overrideWithValue(pending),
      ],
    );
    addTearDown(container.dispose);
    final route = resourceId.isEmpty
        ? SkillResourceCreateRoute(workspaceId: workspace.id, skillId: skill.id)
        : SkillResourceEditRoute(
            workspaceId: workspace.id,
            skillId: skill.id,
            resourceId: resourceId,
          );
    final router = GoRouter(
      routes: [
        GoRoute(path: '/draft', builder: route.build, onExit: route.onExit),
        GoRoute(
          path: SkillDetailRoute(
            workspaceId: workspace.id,
            skillId: skill.id,
          ).location,
          builder: (_, _) => const Text('Parent detail'),
        ),
        GoRoute(
          path: '/destination',
          builder: (_, _) => const Text('Destination'),
        ),
      ],
      initialLocation: '/draft',
    );
    addTearDown(router.dispose);
    final _ = await tester.runAsync(
      () => tester.pumpWidget(
        EasyLocalization(
          child: Builder(
            builder: (context) => UncontrolledProviderScope(
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
            ),
          ),
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          startLocale: const Locale('en'),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    return router;
  }
}

void main() {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  setUp(() => clearAppDatabase(database));
  tearDownAll(database.close);

  testWidgets(
    'reverted resource is clean and direct Back returns to its parent',
    (tester) async {
      final fixture = await _Fixture.create(database: database, existing: true);
      final _ = await fixture.pump(tester);
      await tester.enterText(find.byType(AuraInput).first, 'Changed resource');
      await tester.enterText(find.byType(AuraInput).first, 'Existing resource');
      await tester.tap(find.byIcon(Icons.arrow_back));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Parent detail'), findsOneWidget);
      expect(find.text('Keep editing'), findsNothing);
      expect(
        (await SkillResourcesRepository(fixture.database)
                .getResourceById(fixture.resourceId))
            ?.content,
        '  Saved Markdown\n',
      );
    },
  );

  testWidgets(
    'built-in resource remains read-only and can exit without a prompt',
    (tester) async {
      final fixture = await _Fixture.create(database: database, builtIn: true);
      final router = await fixture.pump(tester);
      expect(
        tester.widget<AuraInput>(find.byType(AuraInput).first).enabled,
        isFalse,
      );
      expect(
        find.text('Immutable instructions', findRichText: true),
        findsWidgets,
      );
      router.go('/destination');
      final _ = await tester.pumpAndSettle();
      expect(find.text('Destination'), findsOneWidget);
      expect(find.text('Keep editing'), findsNothing);
      expect(
        await SkillResourcesRepository(fixture.database)
            .getSkillResources(fixture.skill.id),
        isEmpty,
      );
    },
  );

  testWidgets(
    'pending and failed resource saves preserve exact applied Markdown '
    'until successful persistence',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = await _Fixture.create(database: database);
      final pending = _PendingCreate();
      final router = await fixture.pump(tester, pending: pending);
      await tester.enterText(find.byType(AuraInput).first, 'Draft resource');
      await tester.tap(find.text('Edit content'));
      final _ = await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(MarkdownEditorScreen),
          matching: find.byType(EditableText),
        ),
        '  Exact **Markdown**\n',
      );
      await tester.tap(find.byTooltip('Apply changes'));
      final _ = await tester.pumpAndSettle();
      expect(find.byType(SkillResourceEditScreen), findsOneWidget);
      expect(
        await SkillResourcesRepository(fixture.database)
            .getSkillResources(fixture.skill.id),
        isEmpty,
      );
      final save = find.widgetWithText(AuraButton, 'Save resource');
      await tester.ensureVisible(save);
      await tester.tap(save);
      final _ = await tester.pumpAndSettle();
      expect(pending.value?.content, '  Exact **Markdown**\n');
      router.go('/destination');
      final _ = await tester.pumpAndSettle();
      expect(find.byType(SkillResourceEditScreen), findsOneWidget);
      expect(find.text('Keep editing'), findsNothing);
      pending.requests.first.completeError(StateError('Write failed'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Unable to save skill resource'), findsOneWidget);
      router.go('/destination');
      final _ = await tester.pumpAndSettle();
      expect(find.text('Keep editing'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Draft resource'), findsOneWidget);
      await tester.ensureVisible(save);
      await tester.tap(save);
      final _ = await tester.pumpAndSettle();
      final saved = await SkillResourcesRepository(fixture.database)
          .createResource(
            fixture.skill.id,
            pending.value ?? (throw StateError('Save payload missing')),
          );
      pending.requests.last.complete(saved);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Parent detail'), findsOneWidget);
      expect(find.text('Keep editing'), findsNothing);
      expect(
        (await SkillResourcesRepository(fixture.database)
                .getResourceById(saved.id))
            ?.content,
        '  Exact **Markdown**\n',
      );
      expect(
        (await SkillsRepository(fixture.database)
                .getSkillById(fixture.skill.id))
            ?.content,
        'Persisted parent instructions',
      );
    },
  );
}
