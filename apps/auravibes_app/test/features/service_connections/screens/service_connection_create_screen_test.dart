import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/models/models/model_connection_store.dart';
import 'package:auravibes_app/features/models/models/model_provider_verification.dart';
import 'package:auravibes_app/features/models/providers/add_model_provider_state.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/models/widgets/add_model_provider_widget.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_create_screen.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final action in ['dirty-back', 'clean-back', 'cancel', 'create']) {
    testWidgets('embedded provider $action has one exit owner', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = await _pumpEmbeddedProvider(tester);
      final provider = fixture.container.read(
        addModelProviderStateProvider(fixture.workspaceId).notifier,
      );
      if (action == 'clean-back') {
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        final _ = await tester.pumpAndSettle();
        expect(find.text('Previous'), findsOneWidget);
        expect(find.text('Keep editing', skipOffstage: false), findsNothing);

        return;
      }
      provider
        ..setModel('openai')
        ..setName('Unsaved provider')
        ..setKey('private-test-key');
      final _ = await tester.pumpAndSettle();
      if (action == 'create') {
        await tester.tap(find.text('Verify connection'));
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.text('Add provider'));
        final _ = await tester.pumpAndSettle();
        expect(fixture.store.created?.name, 'Unsaved provider');
        expect(fixture.store.created?.workspaceId, fixture.workspaceId);
        expect(fixture.store.created?.key, 'private-test-key');
        expect(find.text('Previous'), findsOneWidget);
        expect(find.text('Keep editing', skipOffstage: false), findsNothing);
        expect(
          fixture.container
              .read(addModelProviderStateProvider(fixture.workspaceId))
              .hasUnsavedChanges,
          isFalse,
        );

        return;
      }
      if (action == 'cancel') {
        await tester.tap(find.widgetWithText(AuraButton, 'Cancel'));
      } else {
        final _ = await Navigator.of(
          tester.element(find.byType(AddModelProviderWidget)),
        ).maybePop();
      }
      final _ = await tester.pumpAndSettle();
      expect(find.text('Keep editing', skipOffstage: false), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Keep editing', skipOffstage: false), findsNothing);
      expect(find.byType(ServiceConnectionCreateScreen), findsOneWidget);
      expect(
        fixture.container
            .read(addModelProviderStateProvider(fixture.workspaceId))
            .key,
        'private-test-key',
      );
      if (action == 'cancel') {
        await tester.tap(find.widgetWithText(AuraButton, 'Cancel'));
      } else {
        final _ = await Navigator.of(
          tester.element(find.byType(AddModelProviderWidget)),
        ).maybePop();
      }
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Keep editing', skipOffstage: false), findsNothing);
    });
  }

  test('exposes all supported create types', () {
    expect(ServiceConnectionCreateType.values, [
      ServiceConnectionCreateType.modelProvider,
      ServiceConnectionCreateType.skillCredential,
      ServiceConnectionCreateType.appSkillCredential,
    ]);
  });

  testWidgets('preselects credential definition from initial params', (
    tester,
  ) async {
    final database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    final workspace = await WorkspaceRepository(database).createWorkspace(
      const WorkspaceToCreate(name: 'Test Workspace', type: .local),
    );
    final definition = await SkillCredentialDefinitionsRepository(database)
        .createDefinition(
          workspace.id,
          const SkillCredentialDefinitionToCreate(
            title: 'TheCatAPI Key',
            attributesJson: '{"apiKey":{"description":"API key"}}',
          ),
        );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          key: UniqueKey(),
          child: Builder(
            builder: (context) {
              return UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  home: ServiceConnectionCreateScreen(
                    workspaceId: workspace.id,
                    initialType: .skillCredential,
                    initialCredentialDefinitionId: definition.id,
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
      );
    });
    final _ = await tester.pumpAndSettle();

    expect(find.text('Add saved access'), findsOneWidget);
    expect(
      find.byType(AuraChoicePicker<ServiceConnectionCreateType>),
      findsNothing,
    );
    expect(find.text('TheCatAPI Key'), findsOneWidget);
    expect(find.text('apiKey'), findsOneWidget);
    final inputs = tester
        .widgetList<AuraInput>(find.byType(AuraInput))
        .toList();
    expect(inputs.map((input) => input.textInputAction), [
      TextInputAction.next,
      TextInputAction.done,
    ]);
  });
}

Future<
  ({ProviderContainer container, String workspaceId, _ProviderStore store})
>
_pumpEmbeddedProvider(WidgetTester tester) async {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  addTearDown(database.close);
  final workspace = await WorkspaceRepository(database)
      .createWorkspace(const .new(name: 'Provider workspace', type: .local));
  final session = WorkspaceSession(
    LocalWorkspaceRef(localWorkspaceId: workspace.id),
  );
  final store = _ProviderStore();
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      workspaceSessionProvider(session).overrideWithValue(session),
      workspaceSessionForRouteProvider(workspace.id)
          .overrideWithValue(AsyncData(session)),
      modelConnectionStoreProvider(workspace.id)
          .overrideWith((_) async => store),
      apiModelProvidersProvider.overrideWith(
        (_, _) async => const [
          ApiModelProviderEntity(id: 'openai', name: 'OpenAI', type: .openai),
        ],
      ),
    ],
  );
  addTearDown(container.dispose);
  final route = ServiceConnectionCreateRoute(
    workspaceId: workspace.id,
    type: 'modelProvider',
  );
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/previous',
        builder: (_, _) => const Text('Previous'),
        routes: [
          GoRoute(path: 'draft', builder: route.build, onExit: route.onExit),
        ],
      ),
    ],
    initialLocation: '/previous/draft',
  );
  addTearDown(router.dispose);
  final _ = await container.read(
    apiModelProvidersProvider(workspaceId: workspace.id).future,
  );
  await tester.runAsync(() async {
    final bytes = await const SvgStringLoader(
      '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><circle cx="10" cy="10" r="8"/></svg>',
    ).loadBytes(null);
    const loader = SvgNetworkLoader('https://models.dev/logos/openai.svg');
    final _ = await svg.cache.putIfAbsent(
      loader.cacheKey(null),
      () async => bytes,
    );
    await tester.pumpWidget(
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
    );
  });
  final _ = await tester.pumpAndSettle();

  return (container: container, workspaceId: workspace.id, store: store);
}

class _ProviderStore implements ModelConnectionStore {
  ModelConnectionToCreate? created;

  @override
  Future<ModelProviderVerification> verifyModelConnection(
    ModelProviderVerificationRequest request,
  ) async => ModelProviderVerification.fromRequest(
    request: request,
    modelIds: const ['gpt-4o'],
  );

  @override
  Future<ModelConnectionEntity> createModelConnection(
    ModelConnectionToCreate connection, {
    ModelProviderVerification? verification,
  }) async {
    expect(verification, isNotNull);
    created = connection;

    return .new(
      id: 'created',
      name: connection.name,
      modelId: connection.modelId,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      workspaceId: connection.workspaceId,
      hasKey: true,
    );
  }

  @override
  Future<ModelConnectionForEdit?> getModelConnectionForEdit(String _) async =>
      null;

  @override
  Future<ModelConnectionEntity> updateModelConnection(
    String id,
    ModelConnectionToUpdate connection, {
    ModelProviderVerification? verification,
  }) async => throw UnimplementedError();

  @override
  Future<void> deleteModelConnection(String _) => Future<void>.value();

  @override
  Stream<List<ModelConnectionEntity>> watchModelConnections(
    ModelConnectionFilter filter,
  ) => Stream.value(const []);
}
