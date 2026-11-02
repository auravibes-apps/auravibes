import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/skill_resources_repository.dart';
import 'package:auravibes_app/data/repositories/skills_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_workspaces/models/cloud_workspace_view_state.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/flavor.dart';
import 'package:auravibes_app/main.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/drift/database_test_utils.dart';

/// Local persisted objects and production routes; no remote writes.
class UxValidationFixture {
  static const erasureAccount = CloudAccountSession(
    serverUrl: 'https://fixture.example',
    userId: 'fixture-account',
    email: 'reviewer@example.test',
  );
  static const erasureLocalWorkspaceId = '019a1e91-0000-7000-8000-000000001691';

  new _(
    this.database,
    this.workspaceId,
    this.skillId,
    this.resourceId,
    this.agentId,
    this.chatId,
    this.childId,
  );

  final AppDatabase database;
  final String workspaceId;
  final String skillId;
  final String resourceId;
  final String agentId;
  final String chatId;
  final String childId;

  static AppDatabase? _database;

  static CloudWorkspaceViewState get erasureConfirmationState =>
      CloudWorkspaceViewState(
        workspaces: const [],
        pendingInvites: const [],
        deletedOwnedWorkspaces: [
          CloudWorkspaceSummary(
            id: 7,
            name: 'Shared research space',
            role: 'owner',
            revision: 1,
            sequence: 1,
            createdAt: .utc(2026, 10, 30),
            updatedAt: .utc(2026, 10, 30),
          ),
        ],
      );

  static Future<void> closeDatabase() async {
    await _database?.close();
    _database = null;
  }

  static Future<UxValidationFixture> create({
    bool empty = false,
    String? localWorkspaceId,
  }) async {
    final isNewDatabase = _database == null;
    final database = _database ??= .new(connection: NativeDatabase.memory());
    if (!isNewDatabase) await clearAppDatabase(database);
    if (empty) {
      return UxValidationFixture._(database, '', '', '', '', '', '');
    }
    final WorkspaceEntity workspace;
    if (localWorkspaceId == null) {
      workspace = await WorkspaceRepository(database)
          .createWorkspace(const .new(name: 'Design studio', type: .local));
    } else {
      final row = await database.workspaceDao.insertWorkspace(
        .insert(
          id: .new(localWorkspaceId),
          createdAt: .new(.utc(2026, 10, 30)),
          updatedAt: .new(.utc(2026, 10, 30)),
          name: 'Design studio',
          type: .local,
        ),
      );
      workspace = WorkspaceEntity(
        id: row.id,
        name: row.name,
        type: row.type,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
    }
    final skills = SkillsRepository(database);
    final skill = await skills.createSkill(
      workspace.id,
      const .new(
        kind: .template,
        title: 'Research notes',
        description: 'Collect cited findings for a project.',
        content: '# Research\n\nKeep sources alongside every finding.',
      ),
    );
    final _ = await skills.createSkill(
      workspace.id,
      const .new(
        kind: .template,
        title: 'Disabled helper',
        description: 'Kept for later use.',
        content: 'Summarize notes.',
        isEnabled: false,
      ),
    );
    final resource = await SkillResourcesRepository(database).createResource(
      skill.id,
      const .new(
        title: 'Writing guide',
        description: 'A short guide to clear evidence.',
        content: '# Evidence\n\nKeep findings concise and cite sources.',
      ),
    );
    final agent = await AgentsRepository(database).createAgent(
      workspace.id,
      .new(
        name: 'Research assistant',
        description: 'Collects and checks sources.',
        content: 'Use the shared research skill.',
        skills: [.user(skill.id)],
      ),
    );
    final _ = await AgentsRepository(database).createAgent(
      workspace.id,
      .new(
        name: 'Review assistant',
        description: 'Reviews the same source notes.',
        content: 'Check research claims.',
        skills: [.user(skill.id)],
        visibility: .subAgentList,
        isEnabled: false,
      ),
    );
    final repository = ConversationRepository(database);
    final chat = await repository.createConversation(
      .new(
        workspaceId: workspace.id,
        title: 'Project research',
        createdAt: DateTime.utc(2026, 9, 30),
        updatedAt: DateTime.utc(2026, 9, 30),
      ),
    );
    final child = await repository.createConversation(
      .new(
        workspaceId: workspace.id,
        title: 'Source review',
        parentConversationId: chat.id,
        createdAt: DateTime.utc(2026, 9, 30),
        updatedAt: DateTime.utc(2026, 9, 30),
      ),
    );

    return UxValidationFixture._(
      database,
      workspace.id,
      skill.id,
      resource.id,
      agent.id,
      chat.id,
      child.id,
    );
  }

  Future<GoRouter> pump(
    WidgetTester tester,
    String location, {
    Size size = const Size(1280, 1200),
    String locale = 'en',
    double scale = 1,
    bool dark = false,
    List<Object> overrides = const [],
    List<CloudAccountSession> accounts = const [],
    CloudWorkspaceViewState? cloudWorkspaceState,
    Future<List<CloudAccountSession>> Function()? accountsLoad,
    WorkspaceSession? sessionOverride,
    Exception? sessionFailure,
    bool emptyModels = true,
    bool realSessions = false,
    bool useProductionRouter = false,
  }) async {
    AppFlavorConfig.instance.setAppFlavor(.prod);
    SharedPreferences.setMockInitialValues({
      'app_theme': dark ? 1 : 0,
      'app_accent_hue': 186.0,
    });
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    GoRouter.optionURLReflectsImperativeAPIs = true;
    final router = GoRouter(routes: $appRoutes, initialLocation: location);
    addTearDown(router.dispose);
    final session =
        sessionOverride ??
        WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: workspaceId));
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        if (!useProductionRouter) routerProvider.overrideWithValue(router),
        if (!useProductionRouter)
          routerInformationProvider.overrideWithValue(
            router.routeInformationProvider,
          ),
        workspaceSessionProvider(session).overrideWithValue(session),
        if (!realSessions)
          workspaceSessionForRouteProvider.overrideWith((ref, id) async {
            if (sessionFailure != null) throw sessionFailure;

            return session;
          }),
        cloudAccountsProvider.overrideWith(
          (ref) async => accountsLoad == null ? accounts : await accountsLoad(),
        ),
        if (cloudWorkspaceState case final workspaceState?)
          for (final account in accounts)
            cloudWorkspaceStateProvider(account.key)
                .overrideWith((ref) async => workspaceState),
        if (emptyModels)
          chatModelConnectionsProvider(workspaceId)
              .overrideWith((ref) => Stream.value([])),
        if (emptyModels)
          listModelsGroupedByProviderProvider(workspaceId: workspaceId)
              .overrideWith((ref) => Stream.value({})),
        ...overrides.cast(),
      ],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
    final effectiveRouter = useProductionRouter
        ? container.read(routerProvider)
        : router;
    if (useProductionRouter) {
      addTearDown(effectiveRouter.dispose);
      effectiveRouter.go(location);
    }
    await tester.runAsync(
      () => tester.pumpWidget(
        EasyLocalization(
          child: UncontrolledProviderScope(
            container: container,
            child: const RepaintBoundary(
              key: ValueKey('ux-capture'),
              child: MyApp(),
            ),
          ),
          supportedLocales: const [Locale('en'), Locale('es')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: .new(locale),
          saveLocale: false,
        ),
      ),
    );

    await settle(tester);

    return effectiveRouter;
  }

  Future<void> settle(WidgetTester tester) async {
    // Preserve the prior minimum wait while collapsing five virtual frames.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byType(AuraSpinner).evaluate().isEmpty &&
        !tester.binding.hasScheduledFrame) {
      return;
    }

    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(AuraSpinner).evaluate().isEmpty &&
          !tester.binding.hasScheduledFrame) {
        return;
      }
    }
    expect(
      find.byType(AuraSpinner),
      findsNothing,
      reason: 'The fixture must render a settled production state.',
    );
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  }
}
