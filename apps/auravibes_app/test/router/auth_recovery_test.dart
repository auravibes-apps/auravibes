import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/chats/screens/new_chat_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_health.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_email_delivery_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_accounts_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/cloud_account_usecases.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_auth_content.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_route_failure.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_access_gate.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/services/cloud_auth_protocol.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

import '../data/database/drift/database_test_utils.dart';

class _AuthRepository extends Mock implements WorkspaceRepository;

class _AuthProtocol extends Mock implements CloudAuthProtocol;

Future<void> _pump(
  WidgetTester tester,
  GoRouter router,
  ProviderContainer container,
) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1500));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final _ = await tester.runAsync(
    () => tester.pumpWidget(
      EasyLocalization(
        child: Builder(
          builder: (context) => UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              builder: (_, child) => AuraLegacyMaterialBridge(
                child: Portal(
                  child: AuraSnackBarHost(
                    child: child ?? const SizedBox.shrink(),
                  ),
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
  await tester.pump();
  await tester.pump();
}

void main() {
  final database = AppDatabase(
    connection: DatabaseConnection(NativeDatabase.memory()),
  );
  tearDownAll(database.close);
  for (final page in ['login', 'register', 'forgot-password']) {
    for (final leave in [false, true]) {
      testWidgets(
        'pending $page completion respects active route leave=$leave',
        (tester) async {
          FlutterSecureStorage.setMockInitialValues({});
          const workspace = 'local';
          const origin = 'https://intended.example';
          const account = '11111111-1111-4111-8111-111111111111';
          const email = 'person@example.com';
          const destination =
              '/workspaces/local/more/cloud-accounts?intent=preserved';
          const chatPath = '/workspaces/local/chat/new';
          const session = WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: workspace),
          );
          await clearAppDatabase(database);
          final completion = Completer<CloudAuthResult>();
          final resetCompletion = Completer<void>();
          final protocol = _AuthProtocol();
          final request = UuidValue.fromString(account);
          when(() => protocol.login(email, 'password'))
              .thenAnswer((_) => completion.future);
          when(() => protocol.startRegistration(email))
              .thenAnswer((_) async => request);
          when(() => protocol.verifyRegistrationCode(request, '123456'))
              .thenAnswer((_) async => 'verified');
          when(() => protocol.finishRegistration('verified', 'password'))
              .thenAnswer((_) => completion.future);
          when(() => protocol.startPasswordReset(email))
              .thenAnswer((_) async => request);
          when(() => protocol.verifyPasswordResetCode(request, '123456'))
              .thenAnswer((_) async => 'verified');
          when(() => protocol.finishPasswordReset('verified', 'password'))
              .thenAnswer((_) => resetCompletion.future);
          final store = ServerpodAuthStore();
          final usecases = CloudAccountUseCases(
            store: store,
            workspaceRepository: _AuthRepository(),
            deleteRemoteAccount: ({required serverUrl, required userId}) =>
                Future<void>.value(),
            invalidateAccount: (server, user) {
              expect(server, origin);
              expect(user, account);
            },
            createAuthProtocol: (server) {
              expect(server, origin);

              return protocol;
            },
            emailDelivery: .email,
          );
          final router = GoRouter(
            routes: $appRoutes,
            initialLocation: chatPath,
          );
          addTearDown(router.dispose);
          final container = ProviderContainer(
            overrides: [
              appDatabaseProvider.overrideWithValue(database),
              routerProvider.overrideWithValue(router),
              cloudAccountUseCasesProvider.overrideWithValue(usecases),
              cloudEmailDeliveryProvider.overrideWithValue(.email),
              conversationsStreamProvider(
                workspaceId: workspace,
                pagination: (limit: 10, offset: 0),
              ).overrideWith((_) => Stream.value([])),
              conversationsStreamProvider(
                workspaceId: workspace,
                pagination: (limit: 21, offset: 0),
              ).overrideWith((_) => Stream.value([])),
              cloudAccountsProvider.overrideWith((_) async => []),
              workspaceSessionForRouteProvider(workspace)
                  .overrideWith((_) async => session),
            ],
            retry: (_, _) => null,
          );
          addTearDown(container.dispose);
          await _pump(tester, router, container);
          final _ = await tester.pumpAndSettle();
          router.go(
            Uri(
              path: '/workspaces/$workspace/more/cloud-accounts/$page',
              queryParameters: {
                'serverUrl': origin,
                'accountId': account,
                'email': email,
                'return-path': destination,
              },
            ).toString(),
          );
          final _ = await tester.pumpAndSettle();
          if (page == 'forgot-password') {
            await tester.tap(find.text('Send reset code'));
            final _ = await tester.pumpAndSettle();
            await tester.enterText(find.byType(EditableText).first, '123456');
            await tester.enterText(find.byType(EditableText).last, 'password');
            await tester.tap(find.text('Reset password').last);
          } else {
            await tester.enterText(find.byType(EditableText).last, 'password');
            if (page == 'register') {
              await tester.tap(find.text('Send code'));
              final _ = await tester.pumpAndSettle();
              await tester.enterText(find.byType(EditableText), '123456');
              await tester.tap(find.text('Finish registration'));
            } else {
              await tester.tap(find.text('Log in').last);
            }
          }
          await tester.pump();
          switch (page) {
            case 'login':
              verify(() => protocol.login(email, 'password')).called(1);
            case 'register':
              verify(() => protocol.finishRegistration('verified', 'password'))
                  .called(1);
            default:
              verify(() => protocol.finishPasswordReset('verified', 'password'))
                  .called(1);
          }
          if (leave) {
            tester
                .widget<StatefulNavigationShell>(
                  find.byType(StatefulNavigationShell),
                )
                .goBranch(0);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            expect(router.state.uri.path, chatPath);
            expect(find.byType(NewChatScreen), findsOneWidget);
            expect(find.byType(CloudAccountAuthContent), findsNothing);
            expect(
              find.byType(CloudAccountAuthContent, skipOffstage: false),
              findsOneWidget,
            );
          }
          if (page == 'forgot-password') {
            resetCompletion.complete();
          } else {
            completion.complete((
              session: const CloudAccountSession(
                serverUrl: origin,
                userId: account,
                email: email,
              ),
              auth: AuthSuccess(
                authStrategy: 'jwt',
                token: 'fixture-token',
                authUserId: request,
                scopeNames: {},
              ),
            ));
          }
          final _ = await tester.pumpAndSettle();
          if (leave) {
            expect(router.state.uri.toString(), chatPath);
            expect(find.byType(NewChatScreen), findsOneWidget);
          } else if (page == 'forgot-password') {
            expect(
              router.state.uri.path,
              '/workspaces/$workspace/more/cloud-accounts/login',
            );
            expect(
              router.state.uri.queryParameters['password-changed'],
              'true',
            );
            expect(
              router.state.uri.queryParameters['return-path'],
              destination,
            );
            expect(router.state.uri.queryParameters['serverUrl'], origin);
            expect(router.state.uri.queryParameters['accountId'], account);
            expect(router.state.uri.queryParameters['email'], email);
            expect(
              find.text('Password changed. Log in with your new password.'),
              findsOneWidget,
            );
          } else {
            expect(router.state.uri.toString(), destination);
          }
          if (page != 'forgot-password') {
            final saved = await store.listAccounts();
            expect(saved.single.serverUrl, origin);
            expect(saved.single.userId, account);
            expect(saved.single.email, email);
          }
        },
      );
    }
  }
  const workspace = 'remote';
  const origin = 'https://intended.example';
  const account = 'account';
  const session = WorkspaceSession(
    CloudWorkspaceRef(
      localWorkspaceId: workspace,
      serverUrl: origin,
      accountId: account,
      cloudWorkspaceId: 9,
    ),
  );
  for (final page in ['add', 'login', 'register', 'forgot-password']) {
    testWidgets('expired workspace permits $page with auth context', (
      tester,
    ) async {
      await clearAppDatabase(database);
      final location =
          '/workspaces/$workspace/more/cloud-accounts/$page?serverUrl=$origin'
          '&accountId=$account&email=person%40example.com'
          '&return-path=%2Fworkspaces%2Fremote%2Fmore%2Ftools';
      final router = GoRouter(routes: $appRoutes, initialLocation: location);
      addTearDown(router.dispose);
      var checks = 0;
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          routerProvider.overrideWithValue(router),
          conversationsStreamProvider(
            workspaceId: workspace,
            pagination: (limit: 10, offset: 0),
          ).overrideWith((_) => Stream.value([])),
          cloudAccountsProvider.overrideWith((_) async => []),
          workspaceSessionForRouteProvider(workspace)
              .overrideWith((_) => throw StateError('expired-session-secret')),
          workspaceAvailabilityProvider(workspace).overrideWith((_) async {
            checks++;

            return const WorkspaceAuthenticationRequired(session);
          }),
        ],
      );
      addTearDown(container.dispose);
      await _pump(tester, router, container);
      final _ = await tester.pumpAndSettle();
      expect(find.byType(CloudAccountAuthContent), findsOneWidget);
      expect(find.text(origin), findsOneWidget);
      expect(checks, 0);
      expect(find.textContaining('Could not open'), findsNothing);
    });
  }

  testWidgets(
    'gated workspace reauth targets owning origin/account and validated return',
    (tester) async {
      await clearAppDatabase(database);
      final router = GoRouter(
        routes: $appRoutes,
        initialLocation: '/workspaces/$workspace/more/tools',
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          routerProvider.overrideWithValue(router),
          conversationsStreamProvider(
            workspaceId: workspace,
            pagination: (limit: 10, offset: 0),
          ).overrideWith((_) => Stream.value([])),
          cloudAccountsProvider.overrideWith(
            (_) async => [
              const CloudAccountSession(
                serverUrl: origin,
                userId: account,
                email: 'owner@example.com',
              ),
            ],
          ),
          workspaceSessionForRouteProvider(workspace)
              .overrideWith((_) async => session),
          workspaceAvailabilityProvider(workspace).overrideWith(
            (_) async => const WorkspaceAuthenticationRequired(session),
          ),
        ],
      );
      addTearDown(container.dispose);
      await _pump(tester, router, container);
      final _ = await tester.pumpAndSettle();
      expect(
        find.text('Sign in again to open this cloud workspace.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Sign in again'));
      final _ = await tester.pumpAndSettle();
      expect(router.state.uri.queryParameters['serverUrl'], origin);
      expect(router.state.uri.queryParameters['accountId'], account);
      expect(router.state.uri.queryParameters['email'], 'owner@example.com');
      expect(
        router.state.uri.queryParameters['return-path'],
        '/workspaces/$workspace/more/tools',
      );
      expect(find.byType(CloudAccountAuthContent), findsOneWidget);
    },
  );

  for (final invalid in [false, true]) {
    testWidgets('structural failure $invalid offers management without retry', (
      tester,
    ) async {
      final router = GoRouter(
        routes: $appRoutes,
        initialLocation: '/workspaces/$workspace/more/tools',
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [
          routerProvider.overrideWithValue(router),
          workspaceSessionForRouteProvider(workspace).overrideWith(
            (_) => throw WorkspaceRouteFailure(invalidMirror: invalid),
          ),
        ],
        retry: (_, _) => null,
      );
      addTearDown(container.dispose);
      await _pump(tester, router, container);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Retry'), findsNothing);
      expect(find.text('Choose workspace'), findsOneWidget);
      expect(
        find.textContaining(
          invalid ? 'incomplete account details' : 'no longer exists',
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('safe availability refresh retains the mounted editor', (
    tester,
  ) async {
    final attempts = <Completer<WorkspaceAvailability>>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/workspaces/$workspace/more/tools',
          builder: (_, _) => WorkspaceAccessGate(
            workspaceId: workspace,
            session: session,
            child: const Scaffold(body: TextField()),
            onChooseWorkspace: () => fail('Unexpected cancellation'),
          ),
        ),
      ],
      initialLocation: '/workspaces/$workspace/more/tools',
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        workspaceAvailabilityProvider(workspace).overrideWith((_) {
          final attempt = Completer<WorkspaceAvailability>();
          attempts.add(attempt);

          return attempt.future;
        }),
      ],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
    await _pump(tester, router, container);
    attempts.single.complete(const WorkspaceAvailable(session));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'retained draft');
    final element = tester.element(find.byType(EditableText));
    container.invalidate(workspaceAvailabilityProvider(workspace));
    await tester.pump();
    expect(tester.element(find.byType(EditableText)), same(element));
    expect(find.text('retained draft'), findsOneWidget);
    attempts.last.complete(const WorkspaceAvailable(session));
    final _ = await tester.pumpAndSettle();
    expect(tester.element(find.byType(EditableText)), same(element));
  });
  testWidgets('transient retry invalidates only the owning account health', (
    tester,
  ) async {
    final key = cloudAccountKey(origin, account);
    final other = cloudAccountKey('https://other.example', account);
    var checks = 0;
    var otherChecks = 0;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/workspaces/$workspace/more/tools',
          builder: (_, _) => WorkspaceAccessGate(
            workspaceId: workspace,
            session: session,
            child: const Text('Workspace recovered'),
            onChooseWorkspace: () => fail('Unexpected return'),
          ),
        ),
      ],
      initialLocation: '/workspaces/$workspace/more/tools',
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        workspaceSessionForRouteProvider(workspace)
            .overrideWith((_) async => session),
        cloudAccountHealthProvider(key).overrideWith((_) async {
          checks++;

          return CloudAccountHealth(
            status: checks == 1 ? .unknown : .verified,
            checkedAt: .utc(2026),
          );
        }),
        cloudAccountHealthProvider(other).overrideWith((_) async {
          otherChecks++;

          return CloudAccountHealth(status: .verified, checkedAt: .utc(2026));
        }),
      ],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
    final _ = await container.read(cloudAccountHealthProvider(other).future);
    await _pump(tester, router, container);
    final _ = await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Workspace recovered'), findsOneWidget);
    expect(checks, 2);
    expect(otherChecks, 1);
  });
  testWidgets(
    'child auth rejection recovers exact account after cached health',
    (tester) async {
      await clearAppDatabase(database);
      const location = '/workspaces/$workspace/chats/parent/sub-agents/child';
      final router = GoRouter(routes: $appRoutes, initialLocation: location);
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          routerProvider.overrideWithValue(router),
          conversationsStreamProvider(
            workspaceId: workspace,
            pagination: (limit: 10, offset: 0),
          ).overrideWith((_) => Stream.value([])),
          cloudAccountsProvider.overrideWith(
            (_) async => [
              const CloudAccountSession(
                serverUrl: origin,
                userId: account,
                email: 'owner@example.com',
              ),
            ],
          ),
          workspaceSessionForRouteProvider(workspace)
              .overrideWith((_) async => session),
          workspaceAvailabilityProvider(workspace)
              .overrideWith((_) async => const WorkspaceAvailable(session)),
          conversationByIdStreamProvider(
            workspace,
            conversationId: 'child',
          ).overrideWith(
            (_) => Stream.error(
              ConversationException(code: .authenticationRequired),
            ),
          ),
        ],
        retry: (_, _) => null,
      );
      addTearDown(container.dispose);
      await _pump(tester, router, container);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Sign in again'), findsOneWidget);
      expect(find.textContaining('token-hidden'), findsNothing);
      expect(find.text('Return to parent conversation'), findsOneWidget);
      await tester.tap(find.text('Sign in again'));
      final _ = await tester.pumpAndSettle();
      expect(router.state.uri.queryParameters['accountId'], account);
      expect(router.state.uri.queryParameters['serverUrl'], origin);
      expect(router.state.uri.queryParameters['return-path'], location);
    },
  );
  testWidgets(
    'account management remains usable after selected session fails',
    (tester) async {
      await clearAppDatabase(database);
      final router = GoRouter(
        routes: $appRoutes,
        initialLocation: '/workspaces/$workspace/more/cloud-accounts',
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          routerProvider.overrideWithValue(router),
          conversationsStreamProvider(
            workspaceId: workspace,
            pagination: (limit: 10, offset: 0),
          ).overrideWith((_) => Stream.value([])),
          cloudAccountsProvider.overrideWith((_) async => []),
          workspaceSessionForRouteProvider(
            workspace,
          ).overrideWith((_) => throw StateError('unavailable-session-secret')),
        ],
        retry: (_, _) => null,
      );
      addTearDown(container.dispose);
      await _pump(tester, router, container);
      final _ = await tester.pumpAndSettle();
      expect(find.byType(CloudAccountsScreen), findsOneWidget);
      expect(find.textContaining('unavailable-session-secret'), findsNothing);
    },
  );
}
