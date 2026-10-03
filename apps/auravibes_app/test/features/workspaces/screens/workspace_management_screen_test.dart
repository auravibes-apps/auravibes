// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/repositories/workspace_selection_repository.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_health.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/screens/cloud_accounts_screen.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/check_cloud_account_usecase.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_configuration_archive.dart';
import 'package:auravibes_app/features/workspaces/providers/last_workspace_selection_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_management_screen.dart';
import 'package:auravibes_app/features/workspaces/services/workspace_configuration_file_service.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_configuration_archive_usecase.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show DatabaseConnection, Value;
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _UnusedCloudClient extends Mock implements Client;
class _CloudEndpoint extends Mock implements EndpointCloudWorkspace;

class _FakeGoRouter implements GoRouter {
  String? lastLocation;

  @override
  void go(String location, {Object? extra}) {
    lastLocation = location;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _MemoryArchiveFileService({final String? pickedJson})
    extends WorkspaceConfigurationFileService {
  String? savedJson;
  int pickCount = 0;

  @override
  Future<String?> pickArchiveJson() async {
    pickCount++;

    return pickedJson;
  }

  @override
  Future<bool> saveArchiveJson(String json) async {
    savedJson = json;

    return true;
  }
}

String _agentArchiveJson({String workspaceName = 'Portable'}) =>
    WorkspaceConfigurationArchiveCodec.encode(
      .new(
        workspaceName: workspaceName,
        entries: const [
          WorkspaceConfigurationEntry(
            kind: .agent,
            id: 'archive-agent',
            data: {
              'name': 'Imported assistant',
              'description': 'Archive preview',
              'content': 'Instructions',
              'isEnabled': true,
              'visibility': 'both',
            },
          ),
        ],
      ),
    );

WorkspaceConfigurationArchiveUsecase _archiveUsecase(
  AppDatabase database,
  _MemoryArchiveFileService fileService,
) => WorkspaceConfigurationArchiveUsecase(
  localRepository: .new(database),
  localImporter: .new(database),
  cloudRepositoryFor: (_) async =>
      throw StateError('Local archive actions must not request a cloud repo.'),
  fileService: fileService,
);

class _FakeWorkspaceSelectionRepository
    implements WorkspaceSelectionRepository {
  String? selectedWorkspaceId;
  Exception? saveError;

  @override
  Future<void> clearIfMatches(String workspaceId) async {
    if (selectedWorkspaceId == workspaceId) selectedWorkspaceId = null;
  }

  @override
  Future<String?> read() async => selectedWorkspaceId;

  @override
  Future<void> save(String workspaceId) async {
    final error = saveError;
    if (error != null) throw error;

    selectedWorkspaceId = workspaceId;
  }
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  Exception? deleteError;
  final Set<String> failedDeleteIds = {};
  final List<String> deleteAttempts = [];
  bool failCloudRemoval = false;
  final removedMirrors = <CloudAccountKey>[];
  final List<WorkspaceEntity> _workspaces = [];
  final _controller = StreamController<List<WorkspaceEntity>>.broadcast();
  var _nextId = 1;

  @override
  Future<List<WorkspaceEntity>> getAllWorkspaces() async =>
      List.unmodifiable(_workspaces);

  @override
  Stream<List<WorkspaceEntity>> watchAllWorkspaces() async* {
    yield List.unmodifiable(_workspaces);
    yield* _controller.stream;
  }

  @override
  Future<WorkspaceEntity> createWorkspace(WorkspaceToCreate workspace) async {
    final entity = WorkspaceEntity(
      id: 'ws-${_nextId++}',
      name: workspace.name,
      type: workspace.type,
      createdAt: .new(2026),
      updatedAt: .new(2026),
    );
    _workspaces.add(entity);
    _emit();

    return entity;
  }

  void addWorkspaceForTest(WorkspaceEntity workspace) {
    _workspaces.add(workspace);
    _emit();
  }

  @override
  Future<WorkspaceEntity> duplicateWorkspace(
    String id, {
    required String name,
  }) async {
    if (!await workspaceExists(id)) throw Exception('Workspace not found');

    return await createWorkspace(.new(name: name, type: .local));
  }

  @override
  Future<WorkspaceEntity> patchWorkspace(
    String id,
    WorkspacePatch workspace,
  ) async {
    final index = _workspaces.indexWhere((w) => w.id == id);
    if (index == -1) throw Exception('Workspace not found');
    final existing = _workspaces[index];
    final updated = existing.copyWith(
      name: workspace.name ?? existing.name,
      updatedAt: .new(2026),
    );
    _workspaces[index] = updated;
    _emit();

    return updated;
  }

  @override
  Future<bool> deleteWorkspace(String id) async {
    deleteAttempts.add(id);
    final error = deleteError;
    if (error != null) throw error;
    if (failedDeleteIds.contains(id)) throw StateError('delete failed');

    final index = _workspaces.indexWhere((w) => w.id == id);
    if (index == -1) return false;
    final _ = _workspaces.removeAt(index);
    _emit();

    return true;
  }

  @override
  Future<int> getWorkspaceCount() async => _workspaces.length;

  @override
  Future<int> getWorkspaceCountByType(WorkspaceType type) async =>
      _workspaces.where((w) => w.type == type).length;

  @override
  Future<WorkspaceEntity?> getWorkspaceById(String id) async =>
      _workspaces.where((w) => w.id == id).firstOrNull;

  @override
  Future<List<WorkspaceEntity>> getWorkspacesByType(WorkspaceType type) async =>
      _workspaces.where((w) => w.type == type).toList();

  @override
  Future<List<WorkspaceEntity>> searchWorkspacesByName(String query) async =>
      _workspaces.where((w) => w.name.contains(query)).toList();

  @override
  Future<bool> validateWorkspace(WorkspaceToCreate workspace) async => true;

  @override
  Future<bool> workspaceExists(String id) async =>
      _workspaces.any((w) => w.id == id);

  @override
  Future<bool> patchWorkspaceTimestamp(String id) async => true;

  @override
  Future<WorkspaceEntity?> getCloudWorkspaceMirror({
    required String cloudWorkspaceId,
    required String cloudAccountId,
    required String serverUrl,
  }) async => null;

  @override
  Future<WorkspaceEntity?> getCloudWorkspaceMirrorByCloudId(
    String cloudWorkspaceId, {
    required String cloudAccountId,
    required String serverUrl,
  }) async => _workspaces.firstWhereOrNull(
    (w) =>
        w.cloudWorkspaceId == cloudWorkspaceId &&
        w.cloudAccountId == cloudAccountId &&
        w.url == serverUrl,
  );

  @override
  Future<WorkspaceEntity> upsertCloudWorkspaceMirror({
    required String cloudWorkspaceId,
    required String cloudAccountId,
    required String name,
    required String serverUrl,
  }) async {
    final entity = WorkspaceEntity(
      id: 'ws-${_nextId++}',
      name: name,
      type: .remote,
      createdAt: .new(2026),
      updatedAt: .new(2026),
      url: serverUrl,
      cloudWorkspaceId: cloudWorkspaceId,
      cloudAccountId: cloudAccountId,
    );
    _workspaces.add(entity);
    _emit();

    return entity;
  }

  @override
  Future<bool> deleteCloudWorkspaceMirror({
    required String cloudWorkspaceId,
    required String cloudAccountId,
    required String serverUrl,
  }) async {
    if (failCloudRemoval) throw StateError('fixture cleanup failure');
    final mirror = await getCloudWorkspaceMirrorByCloudId(
      cloudWorkspaceId,
      cloudAccountId: cloudAccountId,
      serverUrl: serverUrl,
    );
    if (mirror == null) return false;
    removedMirrors.add(cloudAccountKey(serverUrl, cloudAccountId));
    final _ = _workspaces.remove(mirror);
    _emit();

    return true;
  }

  @override
  Future<int> deleteCloudWorkspaceMirrorsForAccount(
    String cloudAccountId, {
    String? serverUrl,
  }) async {
    final before = _workspaces.length;
    _workspaces.removeWhere(
      (w) =>
          w.cloudAccountId == cloudAccountId &&
          (serverUrl == null || w.url == serverUrl),
    );
    _emit();

    return before - _workspaces.length;
  }

  void _emit() => _controller.add(List.unmodifiable(_workspaces));
}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkspaceManagementScreen', () {
    var repository = _FakeWorkspaceRepository();
    var router = _FakeGoRouter();

    setUpAll(() {
      registerFallbackValue(
        AcceptWorkspaceInviteRequest(
          inviteId: 1,
          requestId: 'fixture',
          expectedInviteRevision: 1,
        ),
      );
      registerFallbackValue(
        DeclineWorkspaceInviteRequest(
          inviteId: 1,
          requestId: 'fixture',
          expectedInviteRevision: 1,
        ),
      );
    });

    setUp(() {
      repository = _FakeWorkspaceRepository();
      router = _FakeGoRouter();
    });

    Widget _buildScreen({
      required String workspaceId,
      bool loading = false,
      String? error,
      WorkspaceRepository? repo,
      List<CloudAccountSession> accounts = const [],
      CloudWorkspaceViewState? cloudWorkspaceState,
      Map<CloudAccountKey, CloudWorkspaceViewState>
          cloudWorkspaceStatesByAccount =
          const {},
      Map<CloudAccountKey, Future<CloudWorkspaceViewState?> Function()>
          cloudLoaders =
          const {},
      GoRouter? navigationRouter,
      CheckCloudAccountUsecase? accountCheck,
      Map<CloudAccountKey, Client> clients = const {},
      bool cloudAuthenticationRequired = false,
      bool connectView = false,
      bool nullCloudUsecase = false,
      ValueNotifier<bool>? viewNotifier,
      WorkspaceSelectionRepository? selectionRepository,
      WorkspaceConfigurationArchiveUsecase? archiveUsecase,
    }) {
      final useRepo = repo ?? repository;

      return EasyLocalization(
        child: Builder(
          builder: (context) {
            final overrides = [
              if (accountCheck != null)
                checkCloudAccountUsecaseProvider.overrideWithValue(accountCheck)
              else
                cloudAccountHealthProvider.overrideWith(
                  (ref, key) async => CloudAccountHealth(
                    status: cloudAuthenticationRequired
                        ? .needsSignIn
                        : .verified,
                    checkedAt: .new(2026),
                  ),
                ),
              cloudWorkspaceUseCasesProvider.overrideWith(
                (ref, key) async => nullCloudUsecase
                    ? null
                    : CloudWorkspaceUseCases(
                        cloudRepository: .new(
                          clients[key] ?? _UnusedCloudClient(),
                        ),
                        workspaceRepository: useRepo,
                        cloudAccountId: key.accountId,
                        serverUrl: key.serverUrl,
                      ),
              ),
              cloudAccountsProvider.overrideWith((ref) async => accounts),
              routerProvider.overrideWithValue(navigationRouter ?? router),
              workspaceRepositoryProvider.overrideWithValue(useRepo),
              currentRouteWorkspaceIdProvider.overrideWithValue(workspaceId),
            ];
            if (archiveUsecase != null) {
              overrides.add(
                workspaceConfigurationArchiveUsecaseProvider.overrideWithValue(
                  archiveUsecase,
                ),
              );
            }
            if (selectionRepository != null) {
              overrides.add(
                lastWorkspaceSelectionRepositoryProvider.overrideWithValue(
                  selectionRepository,
                ),
              );
            }
            if (loading) {
              overrides.add(
                allWorkspacesProvider.overrideWith(
                  (ref) => const Stream.empty(),
                ),
              );
            }
            if (error != null) {
              overrides.add(
                allWorkspacesProvider.overrideWith(
                  (ref) => Stream.error(Exception(error)),
                ),
              );
            }
            if (cloudAuthenticationRequired) {
              for (final account in accounts) {
                overrides.add(
                  cloudWorkspaceStateProvider(account.key).overrideWith(
                    (ref) async =>
                        const CloudWorkspaceViewState.authenticationRequired(),
                  ),
                );
              }
            }
            if (cloudWorkspaceState != null ||
                cloudWorkspaceStatesByAccount.isNotEmpty ||
                cloudLoaders.isNotEmpty) {
              for (final account in accounts) {
                final loader = cloudLoaders[account.key];
                if (loader != null) {
                  overrides.add(
                    cloudWorkspaceStateProvider(account.key)
                        .overrideWith((ref) => loader()),
                  );
                  continue;
                }
                final state =
                    cloudWorkspaceStatesByAccount[account.key] ??
                    cloudWorkspaceState;
                overrides.add(
                  cloudWorkspaceStateProvider(account.key)
                      .overrideWith((ref) async => state),
                );
              }
            }

            final manager = viewNotifier == null
                ? WorkspaceManagementScreen(
                    workspaceId: workspaceId,
                    connectView: connectView,
                  )
                : ValueListenableBuilder<bool>(
                    valueListenable: viewNotifier,
                    builder: (context, value, _) => WorkspaceManagementScreen(
                      workspaceId: workspaceId,
                      connectView: value,
                    ),
                  );

            return ProviderScope(
              overrides: overrides.cast(),
              retry: (retryCount, error) => null,
              child: navigationRouter != null
                  ? MaterialApp.router(
                      routerConfig: navigationRouter,
                      builder: (context, child) =>
                          AuraSnackBarHost(child: child ?? const SizedBox()),
                      locale: context.locale,
                      localizationsDelegates: context.localizationDelegates,
                      supportedLocales: context.supportedLocales,
                    )
                  : MaterialApp(
                      routes: {
                        '/': (_) => const SizedBox(),
                        '/manager': (_) => AuraSnackBarHost(child: manager),
                      },
                      initialRoute: '/manager',
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

    Future<void> _pumpAndInit(WidgetTester tester, Widget widget) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(widget);
      });
      await tester.pump();
    }

    for (final accept in [true, false]) {
      for (final code in [
        CloudWorkspaceErrorCode.authenticationRequired,
        CloudWorkspaceErrorCode.emailAccountRequired,
      ]) {
        final testName =
            'invite auth rejection updates only its health: '
            'accept=$accept code=$code';
        testWidgets(testName, (tester) async {
          await tester.binding.setSurfaceSize(const Size(900, 1800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final local = await repository.createWorkspace(
            const WorkspaceToCreate(name: 'Local', type: .local),
          );
          final mirror = await repository.upsertCloudWorkspaceMirror(
            cloudWorkspaceId: '11',
            cloudAccountId: 'same',
            name: 'Connected',
            serverUrl: 'https://one.example',
          );
          const accounts = [
            CloudAccountSession(
              serverUrl: 'https://one.example',
              userId: 'same',
              email: 'one@example.test',
            ),
            CloudAccountSession(
              serverUrl: 'https://two.example',
              userId: 'same',
              email: 'two@example.test',
            ),
          ];
          final first = cloudAccountKey('https://one.example', 'same');
          final second = accounts.last.key;
          final checks = <CloudAccountKey>[];
          var expired = false;
          final client = _UnusedCloudClient();
          final endpoint = _CloudEndpoint();
          final otherClient = _UnusedCloudClient();
          final otherEndpoint = _CloudEndpoint();
          when(() => otherClient.cloudWorkspace).thenReturn(otherEndpoint);
          when(otherEndpoint.listAuthorizedWorkspaces)
              .thenAnswer((_) async => []);
          when(otherEndpoint.listPendingInvites).thenAnswer((_) async => []);
          when(endpoint.listAuthorizedWorkspaces).thenAnswer((_) async => []);
          when(() => client.cloudWorkspace).thenReturn(endpoint);
          final failure = CloudWorkspaceException(code: code);
          when(() => endpoint.acceptInvite(any())).thenAnswer((_) async {
            expired = true;
            throw failure;
          });
          when(() => endpoint.declineInvite(any())).thenAnswer((_) async {
            expired = true;
            throw failure;
          });
          final navigationRouter = GoRouter(
            routes: [
              GoRoute(
                path: '/manager',
                builder: (context, state) => WorkspaceManagementScreen(
                  workspaceId: local.id,
                  connectView: true,
                ),
              ),
              GoRoute(
                path: '/open',
                builder: (context, state) =>
                    WorkspaceManagementScreen(workspaceId: local.id),
              ),
              GoRoute(
                path: '/accounts',
                builder: (context, state) =>
                    CloudAccountsScreen(workspaceId: local.id),
              ),
            ],
            initialLocation: '/manager',
          );
          addTearDown(navigationRouter.dispose);
          final invite = PendingWorkspaceInviteSummary(
            id: 7,
            workspaceId: 33,
            workspaceName: 'Invited Team',
            email: 'one@example.test',
            role: 'member',
            revision: 4,
            createdAt: .new(2026),
          );
          when(endpoint.listPendingInvites).thenAnswer((_) async => [invite]);
          await _pumpAndInit(
            tester,
            _buildScreen(
              workspaceId: local.id,
              accounts: accounts,
              navigationRouter: navigationRouter,
              clients: {first: client, second: otherClient},
              accountCheck: .new(
                check: (key) async {
                  checks.add(key);
                  if (expired && key == first) throw failure;

                  return key.accountId;
                },
              ),
            ),
          );
          final _ = await tester.pumpAndSettle();
          expect(checks.where((key) => key == first), hasLength(1));
          expect(checks.where((key) => key == second), hasLength(1));
          await tester.tap(find.text(accept ? 'Accept' : 'Decline'));
          final _ = await tester.pumpAndSettle();
          expect(find.text('Sign in again to continue.'), findsOneWidget);
          expect(find.text('Session expired. Sign in again.'), findsOneWidget);
          expect(find.text('Needs sign in'), findsOneWidget);
          expect(checks.where((key) => key == first), hasLength(2));
          expect(checks.where((key) => key == second), hasLength(1));
          if (accept) {
            final request =
                verify(() => endpoint.acceptInvite(captureAny()))
                        .captured
                        .single
                    as AcceptWorkspaceInviteRequest;
            expect(request.inviteId, invite.id);
            expect(request.expectedInviteRevision, invite.revision);
            final _ = verifyNever(() => endpoint.declineInvite(any()));
          } else {
            final request =
                verify(() => endpoint.declineInvite(captureAny()))
                        .captured
                        .single
                    as DeclineWorkspaceInviteRequest;
            expect(request.inviteId, invite.id);
            expect(request.expectedInviteRevision, invite.revision);
            final _ = verifyNever(() => endpoint.acceptInvite(any()));
          }
          navigationRouter.go('/open');
          final _ = await tester.pumpAndSettle();
          expect(find.text('Needs sign in'), findsOneWidget);
          expect(find.text('Connected'), findsOneWidget);
          navigationRouter.go('/accounts');
          final _ = await tester.pumpAndSettle();
          expect(find.text('Needs sign in'), findsOneWidget);
          expect(find.text('Sign in again'), findsOneWidget);
          expect(checks.where((key) => key == second), hasLength(1));
          expect(
            (await repository.getAllWorkspaces()).any(
              (item) => item.id == mirror.id,
            ),
            isTrue,
          );
          expired = false;
          final _ = ProviderScope.containerOf(
            tester.element(find.byType(CloudAccountsScreen)),
          )..invalidate(cloudAccountHealthProvider(first));
          final _ = await tester.pumpAndSettle();
          navigationRouter.go('/manager');
          final _ = await tester.pumpAndSettle();
          expect(find.text('Invited Team'), findsOneWidget);
          expect(checks.where((key) => key == first), hasLength(3));
          expect(checks.where((key) => key == second), hasLength(1));
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('row reauthentication preserves manager and exact origin', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final active = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Active Local', type: .local),
      );
      final mirror = await repository.upsertCloudWorkspaceMirror(
        cloudWorkspaceId: '11',
        cloudAccountId: 'same',
        name: 'Expired Row',
        serverUrl: 'https://two.example/api',
      );
      const accounts = [
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
      ];
      final navigationRouter = GoRouter(
        routes: [
          GoRoute(
            path: '/manager',
            builder: (context, state) =>
                WorkspaceManagementScreen(workspaceId: active.id),
          ),
          GoRoute(
            path: '/workspaces/:workspaceId/more/cloud-accounts/login',
            builder: (context, state) => const Text('Auth destination'),
          ),
        ],
        initialLocation: '/manager',
      );
      addTearDown(navigationRouter.dispose);
      await _pumpAndInit(
        tester,
        _buildScreen(
          workspaceId: active.id,
          accounts: accounts,
          cloudAuthenticationRequired: true,
          navigationRouter: navigationRouter,
        ),
      );
      final _ = await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('account_health_https://two.example_same')),
      );
      final _ = await tester.pumpAndSettle();
      final uri = navigationRouter.routeInformationProvider.value.uri;
      expect(uri.path, '/workspaces/${active.id}/more/cloud-accounts/login');
      expect(
        uri.queryParameters['return-path'],
        '/workspaces/${active.id}/more/manage-workspaces',
      );
      expect(uri.queryParameters['serverUrl'], 'https://two.example');
      expect(uri.queryParameters['accountId'], 'same');
      expect(uri.queryParameters['email'], 'right@example.test');
      expect(uri.path, isNot(contains('/${mirror.id}/')));
      expect(tester.takeException(), isNull);
    });

    Finder _workspaceNameEditor() =>
        find.byKey(const ValueKey<String>('workspace_name_editor'));
    for (final nullUsecase in [false, true]) {
      final testName = 'mixed removal retains failure, null=$nullUsecase';
      testWidgets(testName, (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final local = await repository.createWorkspace(
          const WorkspaceToCreate(name: 'Delete Local', type: .local),
        );
        final active = await repository.createWorkspace(
          const WorkspaceToCreate(name: 'Keep Active', type: .local),
        );
        final cloud = await repository.upsertCloudWorkspaceMirror(
          cloudWorkspaceId: '11',
          cloudAccountId: 'same',
          name: 'Remove Cloud',
          serverUrl: 'https://one.example',
        );
        await _pumpAndInit(
          tester,
          _buildScreen(workspaceId: active.id, nullCloudUsecase: nullUsecase),
        );
        final _ = await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(ValueKey('workspace-selection-${local.id}')),
        );
        await tester.ensureVisible(
          find.byKey(ValueKey('workspace-selection-${cloud.id}')),
        );
        await tester.tap(
          find.byKey(ValueKey('workspace-selection-${cloud.id}')),
        );
        await tester.ensureVisible(find.byType(AuraInput));
        await tester.enterText(find.byType(AuraInput), 'Delete Local');
        final _ = await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('workspace-delete-selected')),
        );
        final _ = await tester.pumpAndSettle();
        expect(
          find.text('Delete local and remove cloud workspaces'),
          findsOneWidget,
        );
        expect(find.text('Remove Cloud'), findsOneWidget);
        expect(
          find.textContaining('Cloud content and membership remain'),
          findsOneWidget,
        );
        expect(find.textContaining('Includes 1 selected'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        final _ = await tester.pumpAndSettle();
        expect(await repository.getWorkspaceById(local.id), isNotNull);
        expect(await repository.getWorkspaceById(cloud.id), isNotNull);
        expect(repository.removedMirrors, isEmpty);
        repository.failCloudRemoval = true;
        await tester.tap(
          find.byKey(const ValueKey('workspace-delete-selected')),
        );
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.text('Delete and remove'));
        final _ = await tester.pumpAndSettle();
        expect(await repository.getWorkspaceById(local.id), isNull);
        expect(await repository.getWorkspaceById(cloud.id), isNotNull);
        expect(find.textContaining('Remove Cloud'), findsWidgets);
        expect(repository.removedMirrors, isEmpty);
        await tester.tap(find.text('Close'));
        final _ = await tester.pumpAndSettle();
        if (nullUsecase) return;
        repository.failCloudRemoval = false;
        await tester.tap(
          find.byKey(const ValueKey('workspace-delete-selected')),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.text('Remove selected cloud workspaces'), findsOneWidget);
        await tester.tap(find.text('Remove'));
        final _ = await tester.pumpAndSettle();
        expect(await repository.getWorkspaceById(cloud.id), isNull);
        expect(repository.removedMirrors, [
          cloudAccountKey('https://one.example', 'same'),
        ]);
      });
    }

    testWidgets(
      'Open defaults to connected workspaces without querying discovery',
      (tester) async {
        final active = await repository.createWorkspace(
          const WorkspaceToCreate(name: 'Local Visible', type: .local),
        );
        final _ = await repository.upsertCloudWorkspaceMirror(
          cloudWorkspaceId: '11',
          cloudAccountId: 'same',
          name: 'Connected Visible',
          serverUrl: 'https://one.example',
        );
        var discoveryCalls = 0;
        await _pumpAndInit(
          tester,
          _buildScreen(
            workspaceId: active.id,
            accounts: const [
              CloudAccountSession(
                serverUrl: 'https://one.example',
                userId: 'same',
                email: 'one@example.test',
              ),
            ],
            cloudLoaders: {
              cloudAccountKey('https://one.example', 'same'): () async {
                discoveryCalls++;

                return const CloudWorkspaceViewState(
                  workspaces: [],
                  pendingInvites: [],
                );
              },
            },
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.text('Local Visible'), findsOneWidget);
        expect(find.text('Connected Visible'), findsOneWidget);
        expect(find.text('Connect cloud'), findsOneWidget);
        expect(discoveryCalls, 0);
      },
    );

    testWidgets(
      'two servers sharing account and workspace IDs keep separate discovery',
      (tester) async {
        final active = await repository.createWorkspace(
          const WorkspaceToCreate(name: 'Local', type: .local),
        );
        final _ = await repository.upsertCloudWorkspaceMirror(
          cloudWorkspaceId: '11',
          cloudAccountId: 'same',
          name: 'Server One Mirror',
          serverUrl: 'https://one.example',
        );
        CloudWorkspaceViewState state(String name) => CloudWorkspaceViewState(
          workspaces: [
            CloudWorkspaceSummary(
              id: 11,
              name: name,
              role: 'member',
              revision: 1,
              sequence: 1,
              createdAt: .new(2026),
              updatedAt: .new(2026),
            ),
          ],
          pendingInvites: [],
        );
        await _pumpAndInit(
          tester,
          _buildScreen(
            workspaceId: active.id,
            connectView: true,
            accounts: const [
              CloudAccountSession(
                serverUrl: 'https://one.example/api',
                userId: 'same',
                email: 'one@example.test',
              ),
              CloudAccountSession(
                serverUrl: 'https://two.example',
                userId: 'same',
                email: 'two@example.test',
              ),
            ],
            cloudWorkspaceStatesByAccount: {
              cloudAccountKey('https://one.example', 'same'): state(
                'One Attached',
              ),
              cloudAccountKey('https://two.example', 'same'): state(
                'Two Available',
              ),
            },
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.text('One Attached'), findsNothing);
        expect(find.text('Two Available'), findsOneWidget);
        expect(
          find.byKey(
            const ValueKey(
              'workspace_available_menu_https://two.example_same_11',
            ),
          ),
          findsOneWidget,
        );
        await tester.enterText(find.byType(AuraInput), 'Two');
        final _ = await tester.pumpAndSettle();
        expect(find.text('two@example.test'), findsOneWidget);
        expect(find.text('one@example.test'), findsNothing);
      },
    );

    testWidgets(
      'view changes retain selection, search and inline rename text',
      (tester) async {
        final view = ValueNotifier(false);
        addTearDown(view.dispose);
        final local = await repository.createWorkspace(
          const WorkspaceToCreate(name: 'Alpha', type: .local),
        );
        await _pumpAndInit(
          tester,
          _buildScreen(workspaceId: local.id, viewNotifier: view),
        );
        final _ = await tester.pumpAndSettle();
        await tester.enterText(find.byType(AuraInput), 'Alpha');
        final _ = await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(ValueKey('workspace-selection-${local.id}')),
        );
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('workspace_menu_${local.id}')));
        final _ = await tester.pumpAndSettle();
        await tester.tap(find.text('Edit'));
        final _ = await tester.pumpAndSettle();
        await tester.enterText(_workspaceNameEditor(), 'Unsaved name');
        view.value = true;
        final _ = await tester.pumpAndSettle();
        expect(_workspaceNameEditor(), findsNothing);
        view.value = false;
        final _ = await tester.pumpAndSettle();
        expect(
          tester.widget<AuraInput>(_workspaceNameEditor()).controller?.text,
          'Unsaved name',
        );
        expect(find.textContaining('1 selected'), findsOneWidget);
        expect(
          tester
              .widget<AuraInput>(
                find.descendant(
                  of: find.byKey(const ValueKey('workspace_search')),
                  matching: find.byType(AuraInput),
                ),
              )
              .controller
              ?.text,
          'Alpha',
        );
        expect((await repository.getWorkspaceById(local.id))?.name, 'Alpha');
      },
    );

    testWidgets('renders loading initially', (tester) async {
      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));

      expect(find.byType(AuraSpinner), findsOneWidget);
    });

    testWidgets('shows loading when stream has no cached data', (tester) async {
      await _pumpAndInit(
        tester,
        _buildScreen(workspaceId: 'ws-1', loading: true),
      );
      await tester.pump();

      expect(find.byType(AuraSpinner), findsOneWidget);
    });

    testWidgets('shows error when stream fails', (tester) async {
      await _pumpAndInit(
        tester,
        _buildScreen(workspaceId: 'ws-1', error: 'test error'),
      );
      final _ = await tester.pumpAndSettle();

      expect(
        find.text('Failed to load workspaces. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('renders workspace list after loading', (tester) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: .local),
      );
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace B', type: .local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Workspace A'), findsOneWidget);
      expect(find.text('Workspace B'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('workspace_select_ws-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('workspace_select_ws-2')),
        findsOneWidget,
      );
    });

    testWidgets('shows localized workspace archive actions', (tester) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: .local),
      );
      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('workspace-archive-import-new')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('workspace_menu_ws-1')));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Export configuration'), findsOneWidget);
      expect(find.text('Import configuration here'), findsOneWidget);
    });

    testWidgets('previews import source, counts, and new destination', (
      tester,
    ) async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final fileService = _MemoryArchiveFileService(
        pickedJson: _agentArchiveJson(),
      );
      final screenRepository = _FakeWorkspaceRepository();

      await _pumpAndInit(
        tester,
        _buildScreen(
          workspaceId: 'unused',
          repo: screenRepository,
          archiveUsecase: _archiveUsecase(database, fileService),
        ),
      );
      final _ = await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('workspace-archive-import-new')),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Source: Portable'), findsOneWidget);
      expect(find.text('Destination: a new local workspace'), findsOneWidget);
      expect(find.text('Agents'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(await database.workspaceDao.getWorkspaceCount(), 0);
      expect(fileService.pickCount, 1);
    });

    testWidgets('canceling import leaves workspace data unchanged', (
      tester,
    ) async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final workspaceRepository = WorkspaceRepository(database);
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(name: 'Target', type: .local),
      );
      final screenRepository = _FakeWorkspaceRepository()
        ..addWorkspaceForTest(workspace);
      final fileService = _MemoryArchiveFileService(
        pickedJson: _agentArchiveJson(),
      );

      await _pumpAndInit(
        tester,
        _buildScreen(
          workspaceId: workspace.id,
          repo: screenRepository,
          archiveUsecase: _archiveUsecase(database, fileService),
        ),
      );
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byKey(ValueKey('workspace_menu_${workspace.id}')));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Import configuration here'));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Destination: Target'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();

      expect(await database.workspaceDao.getWorkspaceCount(), 1);
      expect(await database.select(database.agents).get(), isEmpty);
      expect(fileService.pickCount, 1);
    });

    testWidgets('confirms import once and rejects invalid archives', (
      tester,
    ) async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final screenRepository = _FakeWorkspaceRepository();
      final fileService = _MemoryArchiveFileService(
        pickedJson: _agentArchiveJson(),
      );

      await _pumpAndInit(
        tester,
        _buildScreen(
          workspaceId: 'unused',
          repo: screenRepository,
          archiveUsecase: _archiveUsecase(database, fileService),
        ),
      );
      final _ = await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('workspace-archive-import-new')),
      );
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      final _ = await tester.pumpAndSettle();

      expect(await database.workspaceDao.getWorkspaceCount(), 1);
      expect(await database.select(database.agents).get(), hasLength(1));
      expect(fileService.pickCount, 1);

      final invalidFileService = _MemoryArchiveFileService(
        pickedJson: 'not an archive',
      );
      await tester.pumpWidget(
        _buildScreen(
          workspaceId: 'unused',
          repo: screenRepository,
          archiveUsecase: _archiveUsecase(database, invalidFileService),
        ),
      );
      final _ = await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('workspace-archive-import-new')),
      );
      final _ = await tester.pumpAndSettle();

      expect(
        find.text(
          'This workspace configuration archive is invalid or damaged.',
        ),
        findsOneWidget,
      );
      expect(await database.workspaceDao.getWorkspaceCount(), 1);
      expect(await database.select(database.agents).get(), hasLength(1));
    });

    testWidgets('selects export types and includes required dependencies', (
      tester,
    ) async {
      final database = AppDatabase(
        connection: DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(database.close);
      final workspaceRepository = WorkspaceRepository(database);
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace', type: .local),
      );
      final screenRepository = _FakeWorkspaceRepository()
        ..addWorkspaceForTest(workspace);
      final _ = await database
          .into(database.serviceConnections)
          .insert(
            ServiceConnectionsCompanion.insert(
              id: const Value('connection-1'),
              name: 'Provider',
              serviceId: 'openai',
              kind: .modelProvider,
              authenticationType: .apiKey,
              workspaceId: workspace.id,
            ),
          );
      final _ = await database
          .into(database.workspaceModelSelections)
          .insert(
            WorkspaceModelSelectionsCompanion.insert(
              id: const Value('selection-1'),
              modelId: 'gpt-4o',
              modelConnectionId: 'connection-1',
              toolSamplingPolicy: const Value('prefer'),
            ),
          );
      final fileService = _MemoryArchiveFileService();

      await _pumpAndInit(
        tester,
        _buildScreen(
          workspaceId: workspace.id,
          repo: screenRepository,
          archiveUsecase: _archiveUsecase(database, fileService),
        ),
      );
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byKey(ValueKey('workspace_menu_${workspace.id}')));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Export configuration'));
      final _ = await tester.pumpAndSettle();

      expect(
        find.text('Required linked configuration is included automatically.'),
        findsOneWidget,
      );
      for (final kind in WorkspaceConfigurationKind.values) {
        final option = find.byKey(
          ValueKey('workspace-archive-kind-${kind.name}'),
        );
        await tester.ensureVisible(option);
        await tester.tap(option);
        await tester.pump();
      }

      final exportButton = find.byKey(
        const ValueKey('workspace-archive-export-confirm'),
      );
      expect(tester.widget<TextButton>(exportButton).onPressed, isNull);
      expect(fileService.savedJson, isNull);

      final modelSelection = find.byKey(
        const ValueKey('workspace-archive-kind-modelSelection'),
      );
      await tester.ensureVisible(modelSelection);
      await tester.tap(modelSelection);
      await tester.pump();
      expect(tester.widget<TextButton>(exportButton).onPressed, isNotNull);

      await tester.tap(exportButton);
      final _ = await tester.pumpAndSettle();

      final savedJson = fileService.savedJson;
      if (savedJson == null) fail('No selected archive was saved.');
      final exported = WorkspaceConfigurationArchiveCodec.decode(savedJson);
      expect(
        exported.entries.map((entry) => entry.kind),
        unorderedEquals([
          WorkspaceConfigurationKind.modelConnection,
          WorkspaceConfigurationKind.modelSelection,
        ]),
      );
    });

    testWidgets(
      'filters local and connected names, then shows no-results state',
      (tester) async {
        final _ = await repository.createWorkspace(
          const WorkspaceToCreate(name: 'Workspace Alpha', type: .local),
        );
        final _ = await repository.createWorkspace(
          const WorkspaceToCreate(name: 'Workspace Beta', type: .local),
        );
        final _ = await repository.upsertCloudWorkspaceMirror(
          cloudWorkspaceId: 'connected-alpha',
          cloudAccountId: 'account-1',
          name: 'Connected Alpha',
          serverUrl: 'http://localhost:8080',
        );
        final _ = await repository.upsertCloudWorkspaceMirror(
          cloudWorkspaceId: 'connected-beta',
          cloudAccountId: 'account-1',
          name: 'Connected Beta',
          serverUrl: 'http://localhost:8080',
        );

        await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
        final _ = await tester.pumpAndSettle();

        await tester.enterText(find.byType(AuraInput), 'alpha');
        await tester.pump();

        expect(find.text('Workspace Alpha'), findsOneWidget);
        expect(find.text('Workspace Beta'), findsNothing);
        expect(find.text('Connected Alpha'), findsOneWidget);
        expect(find.text('Connected Beta'), findsNothing);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('workspace_select_ws-1')),
            matching: find.text('Active'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('workspace_create')),
          findsOneWidget,
        );

        await tester.enterText(find.byType(AuraInput), 'missing');
        await tester.pump();

        expect(find.text('No workspaces match your search.'), findsOneWidget);
        expect(find.text('Workspace Alpha'), findsNothing);
        expect(find.text('Connected Alpha'), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('workspace_create')),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows matching cloud groups and one global no-results state', (
      tester,
    ) async {
      const accounts = [
        CloudAccountSession(
          serverUrl: 'http://localhost:8080',
          userId: 'account-1',
          email: 'first@example.com',
        ),
        CloudAccountSession(
          serverUrl: 'http://localhost:8080',
          userId: 'account-2',
          email: 'second@example.com',
        ),
      ];
      final cloudWorkspaceStates = {
        cloudAccountKey(
          'http://localhost:8080',
          'account-1',
        ): CloudWorkspaceViewState(
          workspaces: [
            CloudWorkspaceSummary(
              id: 1,
              name: 'Cloud Alpha',
              role: 'owner',
              revision: 1,
              sequence: 1,
              createdAt: .new(2026),
              updatedAt: .new(2026),
            ),
          ],
          pendingInvites: const [],
        ),
        cloudAccountKey(
          'http://localhost:8080',
          'account-2',
        ): CloudWorkspaceViewState(
          workspaces: [
            CloudWorkspaceSummary(
              id: 2,
              name: 'Cloud Beta',
              role: 'owner',
              revision: 1,
              sequence: 2,
              createdAt: .new(2026),
              updatedAt: .new(2026),
            ),
          ],
          pendingInvites: const [],
        ),
      };

      await _pumpAndInit(
        tester,
        _buildScreen(
          workspaceId: 'ws-1',
          accounts: accounts,
          connectView: true,
          cloudWorkspaceStatesByAccount: cloudWorkspaceStates,
        ),
      );
      final _ = await tester.pumpAndSettle();

      await tester.enterText(find.byType(AuraInput), 'alpha');
      await tester.pump();

      expect(find.text('Cloud Alpha'), findsOneWidget);
      expect(find.text('Cloud Beta'), findsNothing);
      expect(find.text('No workspaces match your search.'), findsNothing);
      expect(find.text('first@example.com'), findsOneWidget);
      expect(find.text('second@example.com'), findsNothing);

      await tester.enterText(find.byType(AuraInput), 'missing');
      await tester.pump();

      expect(find.text('No workspaces match your search.'), findsOneWidget);
      expect(find.text('Cloud Alpha'), findsNothing);
      expect(find.text('Cloud Beta'), findsNothing);
      expect(find.text('first@example.com'), findsNothing);
      expect(find.text('second@example.com'), findsNothing);
    });

    testWidgets('clear search restores cloud discovery and semantics', (
      tester,
    ) async {
      final local = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Local Studio', type: .local),
      );
      final _ = await repository.upsertCloudWorkspaceMirror(
        cloudWorkspaceId: 'connected-1',
        cloudAccountId: 'account-1',
        name: 'Connected Studio',
        serverUrl: 'http://localhost:8080',
      );
      const account = CloudAccountSession(
        serverUrl: 'http://localhost:8080',
        userId: 'account-1',
        email: 'first@example.com',
      );
      final cloudState = CloudWorkspaceViewState(
        workspaces: [
          CloudWorkspaceSummary(
            id: 2,
            name: 'Cloud Studio',
            role: 'owner',
            revision: 1,
            sequence: 1,
            createdAt: .new(2026),
            updatedAt: .new(2026),
          ),
        ],
        pendingInvites: const [],
      );

      await _pumpAndInit(
        tester,
        _buildScreen(
          workspaceId: local.id,
          accounts: [account],
          connectView: true,
          cloudWorkspaceState: cloudState,
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('workspace-search-clear')),
        findsNothing,
      );

      await tester.enterText(find.byType(AuraInput), 'missing');
      final _ = await tester.pumpAndSettle();
      expect(find.text('No workspaces match your search.'), findsOneWidget);
      expect(find.bySemanticsLabel('Clear search'), findsWidgets);
      expect(
        find.byKey(const ValueKey('workspace-search-clear')),
        findsOneWidget,
      );

      final _ = await tester.sendKeyEvent(.tab);
      final _ = await tester.sendKeyEvent(.enter);
      final _ = await tester.pumpAndSettle();

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '',
      );
      expect(find.text('Local Studio'), findsNothing);
      expect(find.text('Connected Studio'), findsNothing);
      expect(find.text('Cloud Studio'), findsOneWidget);
      expect(find.text('No workspaces match your search.'), findsNothing);
      expect(
        find.byKey(const ValueKey('workspace-search-clear')),
        findsNothing,
      );
    });

    testWidgets('search folds accents across workspace sources', (
      tester,
    ) async {
      final acuteE = String.fromCharCode(0x00e9);
      final graveE = String.fromCharCode(0x00e8);
      final combiningAcute = String.fromCharCode(0x0301);
      final precomposedCafe = 'Caf$acuteE';
      final decomposedCafe = 'Cafe$combiningAcute';
      final compatibilityForm = '${String.fromCharCode(0xfb02)}ower Local';
      final extendedCombiningMark = 'a${String.fromCharCode(0x1ab0)}x Local';
      final greekLetters = String.fromCharCodes([
        0x0391,
        0x03b8,
        0x03ae,
        0x03bd,
        0x03b1,
      ]);
      final greekName = '$greekLetters Local';
      final dottedCapitalI = '${String.fromCharCode(0x0130)}stanbul Local';
      final dotlessI = '${String.fromCharCode(0x0131)}stanbul Local';
      final sharpS = 'Stra${String.fromCharCode(0x00df)}e Local';
      final sharpSQuery = 'stra${String.fromCharCode(0x00df)}e';
      final greekQuery = String.fromCharCodes([
        0x03b1,
        0x03b8,
        0x03b7,
        0x03bd,
        0x03b1,
      ]);
      final local = await repository.createWorkspace(
        .new(name: '$precomposedCafe Local', type: .local),
      );
      for (final name in [
        compatibilityForm,
        extendedCombiningMark,
        greekName,
        dottedCapitalI,
        dotlessI,
        sharpS,
      ]) {
        final _ = await repository.createWorkspace(
          .new(name: name, type: .local),
        );
      }
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Other Local', type: .local),
      );
      final _ = await repository.upsertCloudWorkspaceMirror(
        cloudWorkspaceId: 'connected-1',
        cloudAccountId: 'account-1',
        name: '$decomposedCafe Connected',
        serverUrl: 'http://localhost:8080',
      );
      const account = CloudAccountSession(
        serverUrl: 'http://localhost:8080',
        userId: 'account-1',
        email: 'first@example.com',
      );
      final cloudState = CloudWorkspaceViewState(
        workspaces: [
          CloudWorkspaceSummary(
            id: 2,
            name: 'Caf$graveE Cloud',
            role: 'owner',
            revision: 1,
            sequence: 1,
            createdAt: .new(2026),
            updatedAt: .new(2026),
          ),
        ],
        pendingInvites: const [],
      );
      final viewNotifier = ValueNotifier(true);
      addTearDown(viewNotifier.dispose);

      await _pumpAndInit(
        tester,
        _buildScreen(
          workspaceId: local.id,
          accounts: [account],
          connectView: true,
          cloudWorkspaceState: cloudState,
          viewNotifier: viewNotifier,
        ),
      );
      final _ = await tester.pumpAndSettle();

      await tester.enterText(find.byType(AuraInput), '  CAFE  ');
      final _ = await tester.pumpAndSettle();
      expect(find.text('$precomposedCafe Local'), findsNothing);
      expect(find.text('$decomposedCafe Connected'), findsNothing);
      expect(find.text('Caf$graveE Cloud'), findsOneWidget);
      expect(find.text('Other Local'), findsNothing);

      await tester.enterText(find.byType(AuraInput), precomposedCafe);
      final _ = await tester.pumpAndSettle();
      expect(find.text('$decomposedCafe Connected'), findsNothing);
      expect(find.text('Caf$graveE Cloud'), findsOneWidget);

      viewNotifier.value = false;
      final _ = await tester.pumpAndSettle();
      await tester.enterText(find.byType(AuraInput), 'flower');
      final _ = await tester.pumpAndSettle();
      expect(find.text(compatibilityForm), findsOneWidget);

      await tester.enterText(find.byType(AuraInput), 'ax');
      final _ = await tester.pumpAndSettle();
      expect(find.text(extendedCombiningMark), findsOneWidget);

      await tester.enterText(find.byType(AuraInput), greekQuery);
      final _ = await tester.pumpAndSettle();
      expect(find.text(greekName), findsOneWidget);

      await tester.enterText(find.byType(AuraInput), 'istanbul');
      final _ = await tester.pumpAndSettle();
      expect(find.text(dottedCapitalI), findsOneWidget);
      expect(find.text(dotlessI), findsNothing);

      await tester.enterText(find.byType(AuraInput), 'strasse');
      final _ = await tester.pumpAndSettle();
      expect(find.text(sharpS), findsNothing);

      await tester.enterText(find.byType(AuraInput), sharpSQuery);
      final _ = await tester.pumpAndSettle();
      expect(find.text(sharpS), findsOneWidget);
    });

    testWidgets('retry reloads only the failed cloud account', (tester) async {
      const accounts = [
        CloudAccountSession(
          serverUrl: 'http://localhost:8080',
          userId: 'account-1',
          email: 'first@example.com',
        ),
        CloudAccountSession(
          serverUrl: 'http://localhost:8080',
          userId: 'account-2',
          email: 'second@example.com',
        ),
      ];
      CloudWorkspaceViewState state(String name, int id) =>
          CloudWorkspaceViewState(
            workspaces: [
              CloudWorkspaceSummary(
                id: id,
                name: name,
                role: 'owner',
                revision: 1,
                sequence: id,
                createdAt: .new(2026),
                updatedAt: .new(2026),
              ),
            ],
            pendingInvites: const [],
          );
      var firstLoads = 0;
      var secondLoads = 0;

      await _pumpAndInit(
        tester,
        _buildScreen(
          workspaceId: 'ws-1',
          accounts: accounts,
          connectView: true,
          cloudLoaders: {
            cloudAccountKey('http://localhost:8080', 'account-1'): () async {
              firstLoads++;
              if (firstLoads == 1) throw StateError('temporary failure');

              return state('Cloud One', 1);
            },
            cloudAccountKey('http://localhost:8080', 'account-2'): () async {
              secondLoads++;

              return state('Cloud Two', 2);
            },
          },
        ),
      );
      final _ = await tester.pumpAndSettle();
      await tester.enterText(find.byType(AuraInput), 'Cloud');
      final _ = await tester.pumpAndSettle();

      expect(find.text('Failed to load cloud workspaces.'), findsOneWidget);
      expect(find.text('Cloud Two'), findsOneWidget);
      expect(firstLoads, 1);
      expect(secondLoads, 1);

      await tester.tap(
        find.byKey(
          const ValueKey(
            'workspace_cloud_retry_http://localhost:8080_account-1',
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Cloud One'), findsOneWidget);
      expect(find.text('Cloud Two'), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Cloud',
      );
      expect(firstLoads, 2);
      expect(secondLoads, 1);
    });

    testWidgets('confirms before switching workspace from a tile', (
      tester,
    ) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: .local),
      );
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace B', type: .local),
      );
      final selectionRepository = _FakeWorkspaceSelectionRepository();

      await _pumpAndInit(
        tester,
        _buildScreen(
          workspaceId: 'ws-1',
          selectionRepository: selectionRepository,
        ),
      );
      final _ = await tester.pumpAndSettle();

      final _ = await tester.tap(
        find.byKey(const ValueKey<String>('workspace_select_ws-2')),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Switch workspace?'), findsOneWidget);
      expect(selectionRepository.selectedWorkspaceId, isNull);
      expect(router.lastLocation, isNull);

      final _ = await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Switch workspace?'), findsNothing);
      expect(selectionRepository.selectedWorkspaceId, isNull);
      expect(router.lastLocation, isNull);

      final _ = await tester.tap(
        find.byKey(const ValueKey<String>('workspace_select_ws-2')),
      );
      final _ = await tester.pumpAndSettle();
      final _ = await tester.tap(find.text('Confirm'));
      await tester.pump(const Duration(milliseconds: 350));
      final _ = await tester.pumpAndSettle();

      expect(selectionRepository.selectedWorkspaceId, 'ws-2');
      expect(router.lastLocation, '/workspaces/ws-2/more/manage-workspaces');
    });

    testWidgets('shows switch-specific error when selection fails', (
      tester,
    ) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: .local),
      );
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace B', type: .local),
      );
      final selectionRepository = _FakeWorkspaceSelectionRepository()
        ..saveError = .new('selection failed');

      await _pumpAndInit(
        tester,
        _buildScreen(
          workspaceId: 'ws-1',
          selectionRepository: selectionRepository,
        ),
      );
      final _ = await tester.pumpAndSettle();

      final _ = await tester.tap(
        find.byKey(const ValueKey<String>('workspace_select_ws-2')),
      );
      final _ = await tester.pumpAndSettle();
      final _ = await tester.tap(find.text('Confirm'));
      final _ = await tester.pumpAndSettle();

      expect(
        find.text('Failed to switch workspace. Please try again.'),
        findsOneWidget,
      );
      expect(
        find.text('An unexpected error occurred. Please try again.'),
        findsNothing,
      );
      expect(router.lastLocation, isNull);
    });

    testWidgets('marks only the active workspace', (tester) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: .local),
      );
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace B', type: .local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-2'));
      final _ = await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('workspace_select_ws-1')),
          matching: find.text('Active'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('workspace_select_ws-2')),
          matching: find.text('Active'),
        ),
        findsOneWidget,
      );

      final _ = await tester.tap(
        find.byKey(const ValueKey<String>('workspace_select_ws-2')),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Switch workspace?'), findsNothing);
    });

    testWidgets('duplicates a local workspace from its menu', (tester) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: .local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('workspace_menu_ws-1')),
      );
      final _ = await tester.pumpAndSettle();
      expect(find.text('Duplicate Workspace'), findsOneWidget);

      await tester.tap(find.text('Duplicate Workspace'));
      final _ = await tester.pumpAndSettle();

      expect(
        (await repository.getAllWorkspaces()).map(
          (workspace) => workspace.name,
        ),
        contains('Workspace A Copy'),
      );
    });

    testWidgets('confirms before discarding dirty workspace edits', (
      tester,
    ) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: .local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      final _ = await tester.tap(
        find.byKey(const ValueKey<String>('workspace_menu_ws-1')),
      );
      final _ = await tester.pumpAndSettle();
      final _ = await tester.tap(find.text('Edit'));
      final _ = await tester.pumpAndSettle();

      await tester.enterText(_workspaceNameEditor(), 'Workspace B');
      await tester.pump();
      final _ = await tester.tap(
        find.byKey(const ValueKey<String>('workspace_management_back')),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      expect(find.text('Keep editing'), findsOneWidget);

      final _ = await tester.tap(find.text('Keep editing'));
      final _ = await tester.pumpAndSettle();
      expect(_workspaceNameEditor(), findsOneWidget);

      final _ = await tester.tap(
        find.byKey(const ValueKey<String>('workspace_cancel')),
      );
      final _ = await tester.pumpAndSettle();
      final _ = await tester.tap(find.text('Discard'));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsNothing);
      expect(_workspaceNameEditor(), findsNothing);
      expect((await repository.getWorkspaceById('ws-1'))?.name, 'Workspace A');
    });

    testWidgets('saves workspace edits without showing discard confirmation', (
      tester,
    ) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: .local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      final _ = await tester.tap(
        find.byKey(const ValueKey<String>('workspace_menu_ws-1')),
      );
      final _ = await tester.pumpAndSettle();
      final _ = await tester.tap(find.text('Edit'));
      final _ = await tester.pumpAndSettle();

      await tester.enterText(_workspaceNameEditor(), 'Workspace B');
      final _ = await tester.tap(
        find.byKey(const ValueKey<String>('workspace_save')),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Discard unsaved changes?'), findsNothing);
      expect(_workspaceNameEditor(), findsNothing);
      expect((await repository.getWorkspaceById('ws-1'))?.name, 'Workspace B');
    });

    testWidgets('shows sign-in recovery for an expired cloud session', (
      tester,
    ) async {
      await _pumpAndInit(
        tester,
        _buildScreen(
          workspaceId: 'ws-1',
          accounts: const [
            CloudAccountSession(
              serverUrl: 'http://localhost:8080',
              userId: 'account-1',
              email: 'dev@example.com',
            ),
          ],
          connectView: true,
          cloudAuthenticationRequired: true,
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Needs sign in'), findsOneWidget);
      expect(find.text('Session expired. Sign in again.'), findsOneWidget);
      expect(find.text('Sign in again'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>(
            'account_health_http://localhost:8080_account-1',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('keeps expired cloud account selectors unique', (tester) async {
      await _pumpAndInit(
        tester,
        _buildScreen(
          workspaceId: 'ws-1',
          accounts: const [
            CloudAccountSession(
              serverUrl: 'http://localhost:8080',
              userId: 'account-1',
              email: 'first@example.com',
            ),
            CloudAccountSession(
              serverUrl: 'http://localhost:8080',
              userId: 'account-2',
              email: 'second@example.com',
            ),
          ],
          connectView: true,
          cloudAuthenticationRequired: true,
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>(
            'account_health_http://localhost:8080_account-1',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'account_health_http://localhost:8080_account-2',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows routed create action without inline form', (
      tester,
    ) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: .local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Create Workspace'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('workspace_create')),
        findsOneWidget,
      );
      expect(find.byType(AuraInput), findsOneWidget);
      expect(find.byType(AuraPopupMenuButton), findsOneWidget);
    });

    testWidgets('back button is present', (tester) async {
      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('workspace_management_back')),
        findsOneWidget,
      );
    });

    testWidgets('tapping back button does not crash', (tester) async {
      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      final _ = await tester.pumpAndSettle();
    });

    testWidgets('copies the exact workspace ID from the row menu', (
      tester,
    ) async {
      final workspace = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: .local),
      );
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }

          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: workspace.id));
      final _ = await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey<String>('workspace_menu_${workspace.id}')),
      );
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Copy ID'));
      final _ = await tester.pumpAndSettle();

      expect(copiedText, workspace.id);
      expect(find.text('Workspace ID copied'), findsOneWidget);
    });

    testWidgets('sorts workspace names while preserving the active marker', (
      tester,
    ) async {
      final zeta = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Zeta Workspace', type: .local),
      );
      final alpha = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Alpha Workspace', type: .local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: zeta.id));
      final _ = await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text(alpha.name)).dy,
        lessThan(tester.getTopLeft(find.text(zeta.name)).dy),
      );
      expect(
        find.descendant(
          of: find.byKey(ValueKey<String>('workspace_select_${zeta.id}')),
          matching: find.text('Active'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('workspace-sort')));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Name (Z-A)').last);
      final _ = await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text(zeta.name)).dy,
        lessThan(tester.getTopLeft(find.text(alpha.name)).dy),
      );
    });

    testWidgets('aligns select-all with the sort field', (tester) async {
      final workspace = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: .local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: workspace.id));
      final _ = await tester.pumpAndSettle();

      expect(
        tester
            .getRect(find.byKey(const ValueKey('workspace-select-all')))
            .bottom,
        tester.getRect(find.byKey(const ValueKey('workspace-sort'))).bottom,
      );
    });

    testWidgets('selects filtered workspaces and confirms bulk deletion', (
      tester,
    ) async {
      final alpha = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Alpha Workspace', type: .local),
      );
      final beta = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Beta Workspace', type: .local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: beta.id));
      final _ = await tester.pumpAndSettle();
      await tester.enterText(find.byType(AuraInput), 'Alpha');
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workspace-select-all')));
      final _ = await tester.pumpAndSettle();
      await tester.enterText(find.byType(AuraInput), '');
      final _ = await tester.pumpAndSettle();

      expect(
        tester
            .widget<AuraCheckbox>(
              find.byKey(ValueKey('workspace-selection-${alpha.id}')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<AuraCheckbox>(
              find.byKey(ValueKey('workspace-selection-${beta.id}')),
            )
            .value,
        isFalse,
      );

      await tester.tap(find.byKey(const ValueKey('workspace-delete-selected')));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Delete selected local workspaces'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();
      expect(await repository.getWorkspaceById(alpha.id), isNotNull);

      await tester.tap(find.byKey(const ValueKey('workspace-delete-selected')));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      final _ = await tester.pumpAndSettle();

      expect(await repository.getWorkspaceById(alpha.id), isNull);
      expect(await repository.getWorkspaceById(beta.id), isNotNull);
    });

    testWidgets('shows hidden workspace selections before deleting', (
      tester,
    ) async {
      final alpha = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Alpha Workspace', type: .local),
      );
      final beta = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Beta Workspace', type: .local),
      );
      await _pumpAndInit(tester, _buildScreen(workspaceId: beta.id));
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('workspace-select-all')));
      final _ = await tester.pumpAndSettle();
      await tester.enterText(find.byType(AuraInput), 'Alpha');
      final _ = await tester.pumpAndSettle();
      expect(find.textContaining('2 selected'), findsOneWidget);
      expect(find.textContaining('1 hidden by filters'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('workspace-delete-selected')));
      final _ = await tester.pumpAndSettle();
      expect(find.textContaining('2 selected'), findsWidgets);
      expect(find.textContaining('1 hidden by filters'), findsWidgets);
      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is AuraIconButton && widget.tooltip == 'Clear selection',
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(find.textContaining('hidden by filters'), findsNothing);
      await tester.enterText(find.byType(AuraInput), '');
      final _ = await tester.pumpAndSettle();
      for (final workspace in [alpha, beta]) {
        expect(
          tester
              .widget<AuraCheckbox>(
                find.byKey(ValueKey('workspace-selection-${workspace.id}')),
              )
              .value,
          isFalse,
        );
      }
    });

    testWidgets('shows and retries only failed workspace deletions', (
      tester,
    ) async {
      final active = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Home', type: .local),
      );
      final success = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Target Success', type: .local),
      );
      final failedOne = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Target Fail One', type: .local),
      );
      final failedTwo = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Target Fail Two', type: .local),
      );
      final failedThree = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Target Fail Three', type: .local),
      );
      repository.failedDeleteIds.addAll([
        failedOne.id,
        failedTwo.id,
        failedThree.id,
      ]);

      await _pumpAndInit(tester, _buildScreen(workspaceId: active.id));
      final _ = await tester.pumpAndSettle();
      await tester.enterText(find.byType(AuraInput), 'Target');
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workspace-select-all')));
      final _ = await tester.pumpAndSettle();
      await tester.enterText(find.byType(AuraInput), '');
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workspace-delete-selected')));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      final _ = await tester.pumpAndSettle();

      expect(repository.deleteAttempts.toSet(), {
        success.id,
        failedOne.id,
        failedTwo.id,
        failedThree.id,
      });
      final failureDialog = find.byType(AlertDialog);
      expect(
        find.descendant(
          of: failureDialog,
          matching: find.text('Some items could not be deleted'),
        ),
        findsOneWidget,
      );
      expect(find.text('Retry failed'), findsOneWidget);
      for (final name in [
        'Target Fail One',
        'Target Fail Two',
        'Target Fail Three',
      ]) {
        expect(
          find.descendant(of: failureDialog, matching: find.text(name)),
          findsOneWidget,
        );
      }
      expect(await repository.getWorkspaceById(success.id), isNull);

      final beforeFirstRetry = repository.deleteAttempts.length;
      repository.failedDeleteIds
        ..clear()
        ..add(failedTwo.id);
      await tester.tap(find.text('Retry failed'));
      final _ = await tester.pumpAndSettle();
      expect(repository.deleteAttempts.skip(beforeFirstRetry).toSet(), {
        failedOne.id,
        failedTwo.id,
        failedThree.id,
      });
      expect(
        find.descendant(
          of: failureDialog,
          matching: find.text('Target Fail Two'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: failureDialog,
          matching: find.text('Target Fail One'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: failureDialog,
          matching: find.text('Target Fail Three'),
        ),
        findsNothing,
      );

      repository.failedDeleteIds.clear();
      final beforeSecondRetry = repository.deleteAttempts.length;
      await tester.tap(find.text('Retry failed'));
      final _ = await tester.pumpAndSettle();
      expect(repository.deleteAttempts.skip(beforeSecondRetry).toList(), [
        failedTwo.id,
      ]);
      expect(await repository.getWorkspaceById(failedOne.id), isNull);
      expect(await repository.getWorkspaceById(failedTwo.id), isNull);
      expect(await repository.getWorkspaceById(failedThree.id), isNull);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
