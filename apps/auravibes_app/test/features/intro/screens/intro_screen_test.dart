import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_auth_content.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/intro/screens/intro_screen.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_creation_draft_notifier.dart';
import 'package:auravibes_app/features/workspaces/screens/create_workspace_screen.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/database/drift/database_test_utils.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() => clearAppDatabase(_IntroFixture._sharedDatabase));
  tearDownAll(_IntroFixture._sharedDatabase.close);

  for (final management in [false, true]) {
    for (final failFirst in [false, true]) {
      testWidgets(
        'pending create keeps owner management=$management failure=$failFirst',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(1000, 1400));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final pending = Completer<CloudWorkspaceSummary>();
          final client = _Client();
          final endpoint = _CloudEndpoint();
          when(() => client.cloudWorkspace).thenReturn(endpoint);
          registerFallbackValue(
            CreateCloudWorkspaceRequest(name: 'Project', requestId: 'request'),
          );
          var requests = 0;
          when(() => endpoint.createWorkspace(any())).thenAnswer((_) {
            requests++;

            return requests == 1 ? pending.future : Future.value(_summary());
          });
          final fixture = _IntroFixture(
            accounts: [_account],
            client: client,
            management: management,
          );
          addTearDown(fixture.dispose);
          await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
          await _pumpUntilFound(tester, find.byType(AuraInput));
          await tester.enterText(find.byType(AuraInput), 'Cloud draft');
          await _tapVisible(
            tester,
            find.byKey(const Key('workspace_intent_cloud')),
          );
          final _ = await tester.pumpAndSettle();
          final create = tester.widget<AuraButton>(
            find.byKey(_createWorkspaceKey),
          );
          final local = tester.widget<AuraButton>(
            find.byKey(const Key('workspace_intent_local')),
          );
          final addAccount = tester.widget<AuraButton>(
            find.widgetWithText(AuraButton, 'Add another account'),
          );
          create.onPressed();
          // Retained callbacks model a second event before the disabled frame.
          local.onPressed();
          addAccount.onPressed();
          create.onPressed();
          await tester.pump(const Duration(milliseconds: 100));
          expect(requests, 1);
          expect(find.byType(CloudAccountAuthContent), findsNothing);
          for (final intent in ['local', 'cloud', 'connect']) {
            expect(
              tester
                  .widget<AuraButton>(
                    find.byKey(.new('workspace_intent_$intent')),
                  )
                  .disabled,
              isTrue,
            );
          }
          expect(
            tester
                .widget<AuraButton>(
                  find.widgetWithText(AuraButton, 'Add another account'),
                )
                .disabled,
            isTrue,
          );
          final scope = find.byType(DraftExitScope).last;
          expect(
            await tester
                .widget<DraftExitScope>(scope)
                .guard
                .canExit(tester.element(scope)),
            isFalse,
          );
          if (failFirst) {
            pending.completeError(
              const AppCloudWorkspaceException('cloud_errors.unavailable'),
            );
            final _ = await tester.pumpAndSettle();
            expect(
              await fixture.database.workspaceDao.getAllWorkspaces(),
              isEmpty,
            );
            expect(find.text('Cloud draft'), findsOneWidget);
            expect(
              tester
                  .widget<AuraButton>(find.byKey(_createWorkspaceKey))
                  .disabled,
              isFalse,
            );
            expect(
              tester
                  .widget<AuraButton>(
                    find.byKey(const Key('workspace_intent_cloud')),
                  )
                  .variant,
              AuraButtonVariant.primary,
            );
            await tester.tap(find.text('Add another account'));
            final _ = await tester.pumpAndSettle();
            tester
                .widget<CloudAccountAuthContent>(
                  find.byType(CloudAccountAuthContent),
                )
                .onCancel();
            final _ = await tester.pumpAndSettle();
            expect(find.text('Cloud draft'), findsOneWidget);
            await tester.tap(find.byKey(_createWorkspaceKey));
          } else {
            pending.complete(_summary());
          }
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          final _ = await tester.pumpAndSettle();
          final rows = await fixture.database.workspaceDao.getAllWorkspaces();
          expect(rows, hasLength(1));
          expect(rows.single.cloudWorkspaceId, '11');
          expect(rows.single.cloudAccountId, _account.userId);
          expect(requests, failFirst ? 2 : 1);
          if (management) {
            expect(find.text('new chat: ${rows.single.id}'), findsOneWidget);
          } else {
            expect(find.text('Workspace created'), findsOneWidget);
            await _tapVisible(tester, find.byKey(_skipAiKey));
            await _pumpUntilFound(
              tester,
              find.text('new chat: ${rows.single.id}'),
            );
          }
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets('zero-workspace discovery retries and reauth keeps its task', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var attempts = 0;
    final fixture = _IntroFixture(
      accounts: [_account],
      load: () async {
        attempts++;
        if (attempts == 1) throw StateError('offline');

        return const .authenticationRequired();
      },
    );
    addTearDown(fixture.dispose);
    await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
    await _pumpUntilFound(tester, find.byType(AuraInput));
    await tester.enterText(find.byType(AuraInput), 'Keep through retry');
    await _tapVisible(
      tester,
      find.byKey(const Key('workspace_intent_connect')),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    final _ = await tester.pumpAndSettle();
    expect(attempts, 2);
    await tester.tap(find.text('Session expired. Sign in again.'));
    final _ = await tester.pumpAndSettle();
    final auth = tester.widget<CloudAccountAuthContent>(
      find.byType(CloudAccountAuthContent),
    );
    expect(auth.target.accountId, _account.userId);
    expect(auth.target.serverUrl, _account.serverUrl);
    auth.onCancel();
    final _ = await tester.pumpAndSettle();
    expect(
      fixture.container.read(workspaceCreationDraftProvider('intro')).name,
      'Keep through retry',
    );
    expect(
      fixture.container
          .read(workspaceCreationDraftProvider('intro'))
          .intent
          .name,
      'connect',
    );
    expect(await fixture.database.workspaceDao.getAllWorkspaces(), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final accept in [false, true]) {
    testWidgets('zero-workspace invitation accept=$accept uses its account', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final client = _Client();
      final endpoint = _CloudEndpoint();
      when(() => client.cloudWorkspace).thenReturn(endpoint);
      registerFallbackValue(
        AcceptWorkspaceInviteRequest(
          inviteId: 7,
          requestId: 'fixture',
          expectedInviteRevision: 2,
        ),
      );
      registerFallbackValue(
        DeclineWorkspaceInviteRequest(
          inviteId: 7,
          requestId: 'fixture',
          expectedInviteRevision: 2,
        ),
      );
      var responded = false;
      when(() => endpoint.acceptInvite(any())).thenAnswer((_) async {
        responded = true;

        return _summary();
      });
      when(() => endpoint.declineInvite(any())).thenAnswer((_) {
        responded = true;

        return .value();
      });
      final fixture = _IntroFixture(
        accounts: [_account],
        client: client,
        load: () async => .new(
          workspaces: [],
          pendingInvites: responded
              ? []
              : [
                  PendingWorkspaceInviteSummary(
                    id: 7,
                    workspaceId: 11,
                    workspaceName: 'Invited project',
                    email: _account.email,
                    role: 'member',
                    revision: 2,
                    createdAt: .new(2026),
                  ),
                ],
        ),
      );
      addTearDown(fixture.dispose);
      await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
      await _pumpUntilFound(tester, find.byType(AuraInput));
      await _tapVisible(
        tester,
        find.byKey(const Key('workspace_intent_connect')),
      );
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text(accept ? 'Accept' : 'Decline'));
      final _ = await tester.pumpAndSettle();
      expect(responded, isTrue);
      final rows = await fixture.database.workspaceDao.getAllWorkspaces();
      if (accept) {
        expect(rows, hasLength(1));
        expect(rows.single.cloudWorkspaceId, '11');
        expect(rows.single.cloudAccountId, _account.userId);
        expect(find.text('Workspace created'), findsOneWidget);
      } else {
        expect(rows, isEmpty);
        expect(find.text('Invited project'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final intent in ['cloud', 'connect']) {
    testWidgets('zero workspace $intent uses returned cloud mirror', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final accounts = <CloudAccountSession>[];
      final client = _Client();
      final endpoint = _CloudEndpoint();
      when(() => client.cloudWorkspace).thenReturn(endpoint);
      registerFallbackValue(
        CreateCloudWorkspaceRequest(name: 'Project', requestId: 'request'),
      );
      when(() => endpoint.createWorkspace(any()))
          .thenAnswer((_) async => _summary());
      final fixture = _IntroFixture(accounts: accounts, client: client);
      addTearDown(fixture.dispose);
      await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
      await _pumpUntilFound(tester, find.byType(AuraInput));
      await tester.enterText(find.byType(AuraInput), 'Cloud draft');
      await _tapVisible(tester, find.byKey(.new('workspace_intent_$intent')));
      await _pumpUntilFound(tester, find.byType(CloudAccountAuthContent));
      expect(await fixture.database.workspaceDao.getAllWorkspaces(), isEmpty);
      expect(
        fixture.container.read(workspaceCreationDraftProvider('intro')).name,
        'Cloud draft',
      );
      accounts.add(_account);
      fixture.container.invalidate(cloudAccountsProvider);
      tester
          .widget<CloudAccountAuthContent>(find.byType(CloudAccountAuthContent))
          .onSignedIn(_account);
      await tester.pump();
      final _ = await tester.pumpAndSettle();
      if (intent == 'cloud') {
        expect(find.text('Cloud draft'), findsOneWidget);
        await _tapVisible(tester, find.byKey(_createWorkspaceKey));
      } else {
        await tester.tap(find.byType(AuraPopupMenuButton));
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.text('Connect to this app'));
      }
      await _pumpUntilFound(tester, find.text('Workspace created'));
      final rows = await fixture.database.workspaceDao.getAllWorkspaces();
      expect(rows, hasLength(1));
      expect(rows.single.cloudWorkspaceId, '11');
      expect(rows.single.cloudAccountId, _account.userId);
      await _tapVisible(tester, find.byKey(_skipAiKey));
      await _pumpUntilFound(tester, find.text('new chat: ${rows.single.id}'));
      if (intent == 'connect') {
        final _ = verifyNever(() => endpoint.createWorkspace(any()));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final mode in ['Sign in', 'Create new account', 'Forgot password?']) {
    testWidgets('Intro retains name and cloud intent after $mode cancel', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fixture = _IntroFixture();
      addTearDown(fixture.dispose);
      await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
      await _pumpUntilFound(tester, find.byType(AuraInput));
      await tester.enterText(find.byType(AuraInput), 'Retained name');
      await _tapVisible(
        tester,
        find.byKey(const Key('workspace_intent_cloud')),
      );
      await _pumpUntilFound(tester, find.byType(CloudAccountAuthContent));
      if (mode != 'Sign in') {
        await _tapVisible(tester, find.text(mode).last);
        final _ = await tester.pumpAndSettle();
      }
      tester
          .widget<CloudAccountAuthContent>(find.byType(CloudAccountAuthContent))
          .onCancel();
      final _ = await tester.pumpAndSettle();
      expect(find.text('Retained name'), findsOneWidget);
      expect(
        fixture.container
            .read(workspaceCreationDraftProvider('intro'))
            .intent
            .name,
        'cloud',
      );
      expect(await fixture.database.workspaceDao.getAllWorkspaces(), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('creates workspace and routes skip and AI setup actions', (
    tester,
  ) async {
    final fixture = _IntroFixture();
    addTearDown(fixture.dispose);

    await tester.runAsync(() => tester.pumpWidget(fixture.buildApp()));
    await _pumpUntilFound(tester, find.byKey(_createWorkspaceKey));

    expect(find.text('Welcome to AuraVibes'), findsOneWidget);

    await _pumpUntilFound(tester, find.byKey(_createWorkspaceKey));
    await _pumpUntilFound(tester, find.byKey(_createWorkspaceKey));

    await tester.enterText(find.byType(AuraInput), 'ab');
    await _tapVisible(tester, find.byKey(_createWorkspaceKey));
    await _pumpUntilFound(
      tester,
      find.text('Workspace name must be at least 3 characters'),
    );

    await tester.enterText(find.byType(AuraInput), 'a' * 21);
    await _tapVisible(tester, find.byKey(_createWorkspaceKey));
    await _pumpUntilFound(
      tester,
      find.text('Workspace name must be at most 20 characters'),
    );

    await tester.enterText(find.byType(AuraInput), 'Project');
    await _tapVisible(tester, find.byKey(_createWorkspaceKey));
    await _pumpUntilFound(tester, find.text('Workspace created'));

    final workspaces = await fixture.database.workspaceDao.getAllWorkspaces();
    expect(workspaces.single.name, 'Project');

    await _tapVisible(tester, find.byKey(_skipAiKey));
    await _pumpUntilFound(tester, find.textContaining('new chat:'));

    await tester.pumpWidget(const SizedBox.shrink());
    await clearAppDatabase(_IntroFixture._sharedDatabase);
    final connectFixture = _IntroFixture();
    addTearDown(connectFixture.dispose);

    await tester.runAsync(() => tester.pumpWidget(connectFixture.buildApp()));
    await _createWorkspace(tester, 'Connect');
    await _tapVisible(tester, find.byKey(_connectAiKey));
    await _pumpUntilFound(
      tester,
      find.text('service connection: modelProvider'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

const _connectAiKey = Key('intro_connect_ai_button');
const _createWorkspaceKey = Key('intro_create_workspace_button');
const _skipAiKey = Key('intro_skip_ai_button');

Future<void> _pumpFrame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await _pumpFrame(tester);
    if (finder.evaluate().isNotEmpty) return;
  }

  expect(finder, findsOneWidget);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    100,
    scrollable: find.byType(Scrollable).first,
  );
  final _ = await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> _createWorkspace(WidgetTester tester, String name) async {
  await _pumpUntilFound(tester, find.byKey(_createWorkspaceKey));
  expect(find.text('Welcome to AuraVibes'), findsOneWidget);

  await _pumpUntilFound(tester, find.byKey(_createWorkspaceKey));
  await _pumpUntilFound(tester, find.byKey(_createWorkspaceKey));

  await tester.enterText(find.byType(AuraInput), name);
  await _tapVisible(tester, find.byKey(_createWorkspaceKey));
  await _pumpUntilFound(tester, find.text('Workspace created'));
}

class _IntroFixture {
  static final AppDatabase _sharedDatabase = .new(
    connection: NativeDatabase.memory(),
  );

  new({
    List<CloudAccountSession> accounts = const [],
    Client? client,
    Future<CloudWorkspaceViewState?> Function()? load,
    bool management = false,
  }) : this._(_sharedDatabase, accounts, client, load, management);

  new _(
    this.database,
    List<CloudAccountSession> accounts,
    Client? client,
    Future<CloudWorkspaceViewState?> Function()? load,
    bool management,
  ) : container = .new(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          cloudAccountsProvider.overrideWith((ref) async => accounts),
          cloudWorkspaceStateProvider.overrideWith(
            (ref, key) async => load != null
                ? await load()
                : .new(workspaces: [_summary()], pendingInvites: []),
          ),
          if (client != null)
            cloudWorkspaceUseCasesProvider.overrideWith(
              (ref, key) async => CloudWorkspaceUseCases(
                cloudRepository: .new(client),
                workspaceRepository: .new(database),
                cloudAccountId: key.accountId,
                serverUrl: key.serverUrl,
              ),
            ),
        ],
      ),
      router = GoRouter(
        routes: [
          GoRoute(
            path: '/create',
            builder: (_, _) =>
                const CreateWorkspaceScreen(workspaceId: 'origin'),
          ),
          GoRoute(
            path: '/intro',
            builder: (context, state) => const IntroScreen(),
          ),
          GoRoute(
            path: '/workspaces/:workspaceId/chat/new',
            builder: (context, state) {
              return Text('new chat: ${state.pathParameters['workspaceId']}');
            },
          ),
          GoRoute(
            path: '/workspaces/:workspaceId/more/service-connections/new',
            builder: (context, state) {
              return Text(
                'service connection: ${state.uri.queryParameters['type']}',
              );
            },
          ),
        ],
        initialLocation: management ? '/create' : '/intro',
      );

  final AppDatabase database;
  final ProviderContainer container;
  final GoRouter router;

  Widget buildApp() {
    return EasyLocalization(
      key: UniqueKey(),
      child: Builder(
        builder: (context) {
          return UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              builder: (_, child) => AuraLegacyMaterialBridge(
                child: Portal(child: child ?? const SizedBox.shrink()),
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
    );
  }

  void dispose() {
    router.dispose();
    container.dispose();
  }
}

const _account = CloudAccountSession(
  serverUrl: 'https://cloud.example',
  userId: 'account',
  email: 'cloud@example.com',
);
class _Client extends Mock implements Client;
class _CloudEndpoint extends Mock implements EndpointCloudWorkspace;
CloudWorkspaceSummary _summary() => CloudWorkspaceSummary(
  id: 11,
  name: 'Cloud draft',
  role: 'owner',
  revision: 1,
  sequence: 1,
  createdAt: .new(2026),
  updatedAt: .new(2026),
);
