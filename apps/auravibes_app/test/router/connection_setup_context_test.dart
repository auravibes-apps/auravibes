import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/skill_credential_definitions_repository.dart';
import 'package:auravibes_app/data/repositories/skill_credentials_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/skill_credential_definition_entity.dart';
import 'package:auravibes_app/features/service_connections/screens/service_connection_create_screen.dart';
import 'package:auravibes_app/features/skills/providers/cloud_skill_store_provider.dart';
import 'package:auravibes_app/features/skills/providers/skill_credential_definitions_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
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

  for (final contextKind in ['definition', 'service', 'type']) {
    testWidgets(
      '$contextKind query replacement confirms before clearing draft',
      (tester) async {
        final fixture = await _pumpSetup(tester, contextKind: contextKind);
        final firstUri = fixture.router.state.uri;
        await tester.enterText(
          find.byType(EditableText).first,
          'Retained name',
        );
        await tester.enterText(
          find.byType(EditableText).last,
          'private-original',
        );
        final target = switch (contextKind) {
          'definition' =>
            '/draft?credentialDefinitionId=${fixture.definitions.last.id}',
          'service' => '/draft?appSkillId=searxng',
          _ => '/draft?type=appSkillCredential',
        };
        fixture.router.go(target);
        final _ = await tester.pumpAndSettle();
        expect(find.text('Keep editing'), findsOneWidget);
        await tester.tap(find.text('Keep editing'));
        final _ = await tester.pumpAndSettle();
        expect(fixture.router.state.uri, firstUri);
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).first)
              .controller
              .text,
          'Retained name',
        );
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).last)
              .controller
              .text,
          'private-original',
        );
        fixture.router.go(target);
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.text('Discard changes'));
        final _ = await tester.pumpAndSettle();
        expect(fixture.router.state.uri.toString(), target);
        expect(find.text('Retained name'), findsNothing);
        expect(
          tester
              .widgetList<EditableText>(find.byType(EditableText))
              .every((input) => input.controller.text.isEmpty),
          isTrue,
        );
        if (contextKind == 'definition') {
          expect(find.text('Second type'), findsOneWidget);
        }
        if (contextKind == 'service') {
          expect(find.text('Instance base URL'), findsOneWidget);
        }
      },
    );
  }

  testWidgets(
    'zero types can create exact prerequisite and retain parent name',
    (tester) async {
      final fixture = await _pumpSetup(tester, contextKind: 'empty');
      await tester.enterText(
        find.byType(EditableText).first,
        'My staged credential',
      );
      await tester.tap(find.text('Create credential type'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Keep editing'), findsNothing);
      await tester.enterText(find.byType(EditableText).first, 'Created type');
      await tester.enterText(find.byType(EditableText).at(1), 'token');
      await tester.tap(find.byIcon(Icons.save_outlined));
      final _ = await tester.pumpAndSettle();
      expect(fixture.router.state.uri.path, '/draft');
      expect(find.text('My staged credential'), findsOneWidget);
      expect(find.text('Created type'), findsOneWidget);
      expect(find.text('token'), findsOneWidget);
      final created = await fixture.repository.getDefinitions(
        fixture.workspaceId,
      );
      expect(created, hasLength(1));
      expect(
        tester
            .widget<AuraDropdownSelector<String>>(
              find.byType(AuraDropdownSelector<String>),
            )
            .value,
        created.single.id,
      );
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .last
            .obscureText,
        isTrue,
      );
      await tester.enterText(
        find.byType(EditableText).last,
        'new-private-token',
      );
      await tester.tap(find.text('Save'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Credential saved'), findsOneWidget);
      final saved = await fixture.credentials.getCredentialsForDefinition(
        workspaceId: fixture.workspaceId,
        credentialDefinitionId: created.single.id,
      );
      expect(saved.single.name, 'My staged credential');
      expect(saved.single.credentialDefinitionId, created.single.id);
    },
  );

  for (final contextKind in ['missing', 'unknown']) {
    testWidgets('$contextKind required identity cannot select a substitute', (
      tester,
    ) async {
      final fixture = await _pumpSetup(tester, contextKind: contextKind);
      expect(
        find.byType(AuraChoicePicker<ServiceConnectionCreateType>),
        findsNothing,
      );
      expect(find.byType(AuraDropdownSelector<String>), findsNothing);
      expect(find.text('Create credential type'), findsNothing);
      expect(find.text('Return to task'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(
        fixture.router.state.uri.query,
        contains(
          contextKind == 'missing'
              ? 'credentialDefinitionId=missing'
              : 'appSkillId=unknown',
        ),
      );
    });
  }

  testWidgets('failed prerequisite loading retries with its name retained', (
    tester,
  ) async {
    var fail = false;
    final fixture = await _pumpSetup(
      tester,
      contextKind: 'definition',
      shouldFail: () => fail,
    );
    await tester.enterText(find.byType(EditableText).first, 'Retry name');
    fail = true;
    fixture.container.invalidate(
      skillCredentialDefinitionsProvider(fixture.workspaceId),
    );
    final _ = await tester.pumpAndSettle();
    expect(
      find.text('Could not load credential types. Your draft is retained.'),
      findsOneWidget,
    );
    expect(find.textContaining('private failure'), findsNothing);
    fail = false;
    await tester.tap(find.text('Retry'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Retry name'), findsOneWidget);
    expect(find.text('First type'), findsOneWidget);
  });

  testWidgets('custom credential drag dismisses input and clears safe area', (
    tester,
  ) async {
    final _ = await _pumpSetup(tester, contextKind: 'definition');
    tester.view
      ..devicePixelRatio = 1
      ..viewPadding = const FakeViewPadding(bottom: 96);
    addTearDown(tester.view.reset);
    await tester.binding.setSurfaceSize(const Size(360, 300));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'Retained name');
    await tester.enterText(find.byType(EditableText).last, 'retained-secret');
    final _ = await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
    final input = tester.widget<EditableText>(find.byType(EditableText).last);
    expect(input.focusNode.hasFocus, isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    final _ = await tester.pumpAndSettle();

    expect(input.focusNode.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(input.controller.text, 'retained-secret');
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .controller
          .text,
      'Retained name',
    );
    expect(
      tester.getBottomRight(find.byType(AuraCard)).dy,
      lessThanOrEqualTo(tester.getBottomRight(find.byType(ListView)).dy - 96),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<
  ({
    GoRouter router,
    ProviderContainer container,
    String workspaceId,
    SkillCredentialDefinitionsRepository repository,
    SkillCredentialsRepository credentials,
    List<SkillCredentialDefinitionEntity> definitions,
  })
>
_pumpSetup(
  WidgetTester tester, {
  required String contextKind,
  bool Function()? shouldFail,
}) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  addTearDown(database.close);
  final workspace = await WorkspaceRepository(database)
      .createWorkspace(const .new(name: 'Setup workspace', type: .local));
  final repository = SkillCredentialDefinitionsRepository(database);
  final encryption = EncryptionService(_SetupSecretKey());
  final credentials = SkillCredentialsRepository(
    database: database,
    encryptionService: encryption,
  );
  final definitions = <SkillCredentialDefinitionEntity>[];
  if (contextKind != 'empty') {
    for (final title in ['First type', 'Second type']) {
      definitions.add(
        await repository.createDefinition(
          workspace.id,
          .new(
            title: title,
            attributesJson: '{"token":{"description":"Secret token"}}',
          ),
        ),
      );
    }
  }
  final session = WorkspaceSession(
    LocalWorkspaceRef(localWorkspaceId: workspace.id),
  );
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      encryptionServiceProvider.overrideWithValue(encryption),
      workspaceSessionProvider(session).overrideWithValue(session),
      workspaceSessionForRouteProvider(workspace.id)
          .overrideWithValue(AsyncData(session)),
      cloudWorkspaceStateGatewayProvider.overrideWith((_, _) async => null),
      cloudSkillStoreProvider(workspace.id).overrideWithValue(null),
      skillCredentialDefinitionsProvider(workspace.id).overrideWith((_) async {
        if (shouldFail?.call() ?? false) throw StateError('private failure');

        return await repository.getDefinitions(workspace.id);
      }),
    ],
  );
  addTearDown(container.dispose);
  ServiceConnectionCreateRoute createRoute(GoRouterState state) =>
      ServiceConnectionCreateRoute(
        workspaceId: workspace.id,
        type: state.uri.queryParameters['type'],
        credentialDefinitionId:
            state.uri.queryParameters['credentialDefinitionId'],
      );
  final definitionRoute = SkillCredentialDefinitionCreateRoute(
    workspaceId: workspace.id,
    returnCreated: true,
  );
  final query = switch (contextKind) {
    'definition' ||
    'type' => 'credentialDefinitionId=${definitions.firstOrNull?.id}',
    'service' => 'appSkillId=brave',
    'missing' => 'credentialDefinitionId=missing',
    'unknown' => 'appSkillId=unknown',
    _ => 'type=skillCredential',
  };
  final router = GoRouter(
    routes: [
      GoRoute(
        path: ServiceConnectionsRoute(workspaceId: workspace.id).location,
        pageBuilder: (_, state) => NoTransitionPage(
          child: const Text('Credential saved'),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '/draft',
        pageBuilder: (context, state) => NoTransitionPage(
          child: createRoute(state).build(context, state),
          key: state.pageKey,
        ),
        redirect: (context, state) =>
            createRoute(state).redirect(context, state),
        onExit: (context, state) => createRoute(state).onExit(context, state),
      ),
      GoRoute(
        path: Uri.parse(definitionRoute.location).path,
        pageBuilder: (context, state) => NoTransitionPage(
          child: definitionRoute.build(context, state),
          key: state.pageKey,
        ),
        onExit: definitionRoute.onExit,
      ),
    ],
    initialLocation: '/draft?$query',
  );
  addTearDown(router.dispose);
  await tester.runAsync(
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

  return (
    router: router,
    container: container,
    workspaceId: workspace.id,
    repository: repository,
    credentials: credentials,
    definitions: definitions,
  );
}

class _SetupSecretKey extends SecretKeyManager {
  final SecretKey _key = .new(List<int>.filled(32, 7));

  @override
  Future<SecretKey> getOrCreateSecretKey() async => _key;
}
