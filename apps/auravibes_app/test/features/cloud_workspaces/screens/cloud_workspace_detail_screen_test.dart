import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/repositories/workspace_selection_repository.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_health.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/screens/cloud_workspace_detail_screen.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/last_workspace_selection_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_management_screen.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_app.dart';

class _MirrorRepository extends Mock implements WorkspaceRepository;
class _UnusedClient extends Mock implements Client;
class _CloudEndpoint extends Mock implements EndpointCloudWorkspace;
class _SelectionRepository extends Mock implements WorkspaceSelectionRepository;

void main() {
  setUpAll(() {
    registerFallbackValue(
      RenameCloudWorkspaceRequest(
        workspaceId: 11,
        name: 'Name',
        requestId: 'fixture',
        expectedWorkspaceRevision: 8,
      ),
    );
  });

  const connectedElsewhereTest =
      'discovery details keeps viewed account '
      'and opens existing other-account mirror';
  testWidgets(connectedElsewhereTest, (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _MirrorRepository();
    final selection = _SelectionRepository();
    final client = _UnusedClient();
    final endpoint = _CloudEndpoint();
    final mirror = WorkspaceEntity(
      id: 'mirror-a',
      name: 'Team Studio',
      type: .remote,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      url: 'https://one.example/api',
      cloudWorkspaceId: '11',
      cloudAccountId: 'account-a',
    );
    final local = WorkspaceEntity(
      id: 'local',
      name: 'Local',
      type: .local,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    final mirrors = [local, mirror];
    when(repository.getAllWorkspaces).thenAnswer((_) async => mirrors);
    when(repository.watchAllWorkspaces)
        .thenAnswer((_) => Stream.value(mirrors));
    when(() => repository.getWorkspaceById('mirror-a'))
        .thenAnswer((_) async => mirror);
    when(() => repository.workspaceExists('mirror-a'))
        .thenAnswer((_) async => true);
    when(
      () => repository.getCloudWorkspaceMirrorByCloudId(
        '11',
        cloudAccountId: 'account-b',
        serverUrl: 'https://one.example',
      ),
    ).thenAnswer((_) async => null);
    when(selection.read).thenAnswer((_) async => 'local');
    when(() => selection.save('mirror-a'))
        .thenAnswer((_) => Future<void>.value());
    when(() => client.cloudWorkspace).thenReturn(endpoint);
    final summary = CloudWorkspaceSummary(
      id: 11,
      name: 'Team Studio',
      role: 'admin',
      revision: 8,
      sequence: 9,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    when(() => endpoint.renameWorkspace(any()))
        .thenAnswer((_) async => summary.copyWith(name: 'Renamed Team'));
    const accounts = [
      CloudAccountSession(
        serverUrl: 'https://one.example',
        userId: 'account-a',
        email: 'owner@example.test',
      ),
      CloudAccountSession(
        serverUrl: 'https://one.example',
        userId: 'account-b',
        email: 'viewer@example.test',
      ),
    ];
    final requested = <CloudAccountKey>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/workspaces/:workspaceId/more/manage-workspaces',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const WorkspaceManagementScreen(
              workspaceId: 'local',
              connectView: true,
            ),
            key: state.pageKey,
          ),
          routes: [
            GoRoute(
              path: 'cloud/:accountId/:cloudId',
              pageBuilder: (context, state) => NoTransitionPage(
                child: CloudWorkspaceDetailScreen(
                  workspaceId: state.pathParameters['workspaceId'] ?? '',
                  cloudAccountId: state.pathParameters['accountId'] ?? '',
                  cloudWorkspaceId: .parse(
                    state.pathParameters['cloudId'] ?? '',
                  ),
                  serverUrl: state.uri.queryParameters['server-url'],
                ),
                key: state.pageKey,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/workspaces/:workspaceId/chat/new',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const Text('Opened existing workspace'),
            key: state.pageKey,
          ),
        ),
      ],
      initialLocation: '/workspaces/local/more/manage-workspaces?view=connect',
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        routerProvider.overrideWithValue(router),
        currentRouteWorkspaceIdProvider.overrideWithValue('local'),
        workspaceRepositoryProvider.overrideWithValue(repository),
        lastWorkspaceSelectionRepositoryProvider.overrideWithValue(selection),
        cloudAccountsProvider.overrideWith((ref) async => accounts),
        cloudAccountHealthProvider.overrideWith(
          (ref, key) async =>
              CloudAccountHealth(status: .verified, checkedAt: .new(2026)),
        ),
        cloudWorkspaceStateProvider.overrideWith(
          (ref, key) async => CloudWorkspaceViewState(
            workspaces: key.accountId == 'account-b' ? [summary] : [],
            pendingInvites: [],
          ),
        ),
        cloudWorkspaceUseCasesProvider.overrideWith((ref, key) async {
          requested.add(key);

          return CloudWorkspaceUseCases(
            cloudRepository: .new(client),
            workspaceRepository: repository,
            cloudAccountId: key.accountId,
            serverUrl: key.serverUrl,
          );
        }),
        cloudWorkspaceDetailProvider.overrideWith(
          (ref, key) async => CloudWorkspaceDetailState(
            detail: .new(
              workspace: summary,
              ownerUserId: 'account-a',
              capabilities: .new(
                canViewMembers: false,
                canInviteMembers: false,
                canInviteAdmins: false,
                canManageMembers: false,
                canManageAdmins: false,
                canRename: true,
                canTransferOwnership: false,
                canLeave: true,
                canDelete: false,
              ),
            ),
            members: [],
            invites: [],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          child: UncontrolledProviderScope(
            container: container,
            child: Builder(
              builder: (context) => MaterialApp.router(
                routerConfig: router,
                builder: (context, child) =>
                    AuraSnackBarHost(child: child ?? const SizedBox()),
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
        ),
      );
    });
    final _ = await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey(
          'workspace_available_menu_https://one.example_account-b_11',
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Details'));
    final _ = await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      endsWith('/cloud/account-b/11'),
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['server-url'],
      'https://one.example',
    );
    expect(
      find.text('Already connected through owner@example.test'),
      findsOneWidget,
    );
    expect(find.text('Connect to this app'), findsNothing);
    expect(find.text('Remove from this app'), findsNothing);
    await tester.tap(find.text('Rename workspace'));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Renamed Team');
    await tester.tap(find.text('Confirm'));
    final _ = await tester.pumpAndSettle();
    final request =
        verify(() => endpoint.renameWorkspace(captureAny())).captured.single
            as RenameCloudWorkspaceRequest;
    expect(request.workspaceId, 11);
    expect(request.expectedWorkspaceRevision, 8);
    expect(request.name, 'Renamed Team');
    expect(requested, [accounts.last.key]);
    await tester.tap(find.text('Open workspaces'));
    final _ = await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/workspaces/mirror-a/chat/new',
    );
    verify(() => selection.save('mirror-a')).called(1);
    expect(mirrors.where((item) => item.cloudWorkspaceId != null), [mirror]);
    expect(mirror.cloudAccountId, 'account-a');
    final _ = verifyNever(
      () => repository.upsertCloudWorkspaceMirror(
        cloudWorkspaceId: '11',
        cloudAccountId: 'account-b',
        name: 'Team Studio',
        serverUrl: 'https://one.example',
      ),
    );
    final _ = verifyNever(
      () => repository.deleteCloudWorkspaceMirror(
        cloudWorkspaceId: '11',
        cloudAccountId: 'account-a',
        serverUrl: 'https://one.example',
      ),
    );
    final _ = verifyNever(
      () => repository.deleteCloudWorkspaceMirror(
        cloudWorkspaceId: '11',
        cloudAccountId: 'account-b',
        serverUrl: 'https://one.example',
      ),
    );
    expect(tester.takeException(), isNull);
  });

  for (final connected in [false, true]) {
    testWidgets(
      'device connection preserves membership, connected=$connected',
      (tester) async {
        final repository = _MirrorRepository();
        final client = _UnusedClient();
        when(repository.getAllWorkspaces).thenAnswer((_) async => []);
        final mirror = WorkspaceEntity(
          id: 'mirror',
          name: 'Team Studio',
          type: .remote,
          createdAt: .new(2026),
          updatedAt: .new(2026),
          url: 'https://two.example',
          cloudWorkspaceId: '11',
          cloudAccountId: 'same',
        );
        when(
          () => repository.upsertCloudWorkspaceMirror(
            cloudWorkspaceId: '11',
            cloudAccountId: 'same',
            name: 'Team Studio',
            serverUrl: 'https://two.example',
          ),
        ).thenAnswer((_) async => mirror);
        when(
          () => repository.deleteCloudWorkspaceMirror(
            cloudWorkspaceId: '11',
            cloudAccountId: 'same',
            serverUrl: 'https://two.example',
          ),
        ).thenAnswer((_) async => true);
        await tester.runAsync(() async {
          await tester.pumpWidget(
            TestableApp(
              child: const CloudWorkspaceDetailScreen(
                workspaceId: 'local',
                cloudAccountId: 'same',
                cloudWorkspaceId: 11,
                serverUrl: 'https://two.example',
              ),
              overrides: [
                cloudAccountsProvider.overrideWith(
                  (ref) async => const [
                    CloudAccountSession(
                      serverUrl: 'https://two.example',
                      userId: 'same',
                      email: 'right@example.test',
                    ),
                  ],
                ),
                allWorkspacesProvider.overrideWith(
                  (ref) => Stream.value(connected ? [mirror] : []),
                ),
                cloudAccountHealthProvider.overrideWith(
                  (ref, key) async =>
                      const CloudAccountHealth(status: .unknown),
                ),
                cloudWorkspaceUseCasesProvider.overrideWith(
                  (ref, key) async => CloudWorkspaceUseCases(
                    cloudRepository: .new(client),
                    workspaceRepository: repository,
                    cloudAccountId: key.accountId,
                    serverUrl: key.serverUrl,
                  ),
                ),
                cloudWorkspaceDetailProvider.overrideWith(
                  (ref, key) async => CloudWorkspaceDetailState(
                    detail: .new(
                      workspace: .new(
                        id: 11,
                        name: 'Team Studio',
                        role: 'member',
                        revision: 8,
                        sequence: 9,
                        createdAt: .new(2026),
                        updatedAt: .new(2026),
                      ),
                      ownerUserId: 'owner',
                      capabilities: .new(
                        canViewMembers: false,
                        canInviteMembers: false,
                        canInviteAdmins: false,
                        canManageMembers: false,
                        canManageAdmins: false,
                        canRename: false,
                        canTransferOwnership: false,
                        canLeave: true,
                        canDelete: false,
                      ),
                    ),
                    members: [],
                    invites: [],
                  ),
                ),
              ],
            ),
          );
        });
        final _ = await tester.pumpAndSettle();
        await tester.tap(
          find.text(connected ? 'Remove from this app' : 'Connect to this app'),
        );
        final _ = await tester.pumpAndSettle();
        if (connected) {
          expect(
            find.textContaining('Cloud data stays in the cloud'),
            findsOneWidget,
          );
          await tester.tap(find.text('Cancel'));
          final _ = await tester.pumpAndSettle();
          final _ = verifyNever(
            () => repository.deleteCloudWorkspaceMirror(
              cloudWorkspaceId: '11',
              cloudAccountId: 'same',
              serverUrl: 'https://two.example',
            ),
          );
          await tester.tap(find.text('Remove from this app'));
          final _ = await tester.pumpAndSettle();
          await tester.tap(find.text('Confirm'));
          final _ = await tester.pumpAndSettle();
          verify(
            () => repository.deleteCloudWorkspaceMirror(
              cloudWorkspaceId: '11',
              cloudAccountId: 'same',
              serverUrl: 'https://two.example',
            ),
          ).called(1);
        } else {
          verify(
            () => repository.upsertCloudWorkspaceMirror(
              cloudWorkspaceId: '11',
              cloudAccountId: 'same',
              name: 'Team Studio',
              serverUrl: 'https://two.example',
            ),
          ).called(1);
        }
        final _ = verifyNever(() => client.cloudWorkspace);
      },
    );
  }

  for (final role in ['owner', 'admin', 'member']) {
    testWidgets(
      '$role sees workspace identity and only permitted lifecycle actions',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final isOwner = role == 'owner';
        final canManage = role != 'member';
        CloudWorkspaceDetailKey? requested;
        await tester.runAsync(() async {
          await tester.pumpWidget(
            TestableApp(
              child: const CloudWorkspaceDetailScreen(
                workspaceId: 'local',
                cloudAccountId: 'same',
                cloudWorkspaceId: 11,
                serverUrl: 'https://two.example',
              ),
              overrides: [
                cloudAccountsProvider.overrideWith(
                  (ref) async => const [
                    CloudAccountSession(
                      serverUrl: 'https://one.example',
                      userId: 'same',
                      email: 'wrong@example.test',
                    ),
                    CloudAccountSession(
                      serverUrl: 'https://two.example',
                      userId: 'same',
                      email: 'right@example.test',
                    ),
                  ],
                ),
                allWorkspacesProvider.overrideWith((ref) => Stream.value([])),
                cloudAccountHealthProvider.overrideWith(
                  (ref, key) async => CloudAccountHealth(
                    status: .verified,
                    checkedAt: .new(2026),
                  ),
                ),
                cloudWorkspaceDetailProvider.overrideWith((ref, key) async {
                  requested = key;

                  return CloudWorkspaceDetailState(
                    detail: .new(
                      workspace: .new(
                        id: 11,
                        name: 'Team Studio',
                        role: role,
                        revision: 8,
                        sequence: 9,
                        createdAt: .new(2026),
                        updatedAt: .new(2026),
                      ),
                      ownerUserId: 'owner',
                      capabilities: .new(
                        canViewMembers: true,
                        canInviteMembers: canManage,
                        canInviteAdmins: isOwner,
                        canManageMembers: canManage,
                        canManageAdmins: isOwner,
                        canRename: canManage,
                        canTransferOwnership: isOwner,
                        canLeave: !isOwner,
                        canDelete: isOwner,
                      ),
                    ),
                    members: [],
                    invites: [],
                  );
                }),
              ],
            ),
          );
        });
        final _ = await tester.pumpAndSettle();
        expect(requested, (
          serverUrl: 'https://two.example',
          accountId: 'same',
          workspaceId: 11,
        ));
        expect(find.text('Team Studio'), findsWidgets);
        expect(find.text('right@example.test'), findsOneWidget);
        expect(find.text('wrong@example.test'), findsNothing);
        expect(find.text('https://two.example'), findsOneWidget);
        expect(find.text('Not connected to this app'), findsOneWidget);
        expect(
          find.text('Rename workspace'),
          canManage ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Delete cloud workspace'),
          isOwner ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Leave workspace'),
          isOwner ? findsNothing : findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
