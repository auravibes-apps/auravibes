// Required: Existing test and UI helpers keep compact return flow.

import 'dart:async';

import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_management_screen.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _FakeGoRouter implements GoRouter {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final List<WorkspaceEntity> _workspaces = [];
  final _controller = StreamController<List<WorkspaceEntity>>.broadcast();
  var _nextId = 1;
  Exception? deleteError;

  void _emit() => _controller.add(List.unmodifiable(_workspaces));

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
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    _workspaces.add(entity);
    _emit();

    return entity;
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
      updatedAt: DateTime(2026),
    );
    _workspaces[index] = updated;
    _emit();

    return updated;
  }

  @override
  Future<bool> deleteWorkspace(String id) async {
    final error = deleteError;
    if (error != null) throw error;

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
      type: WorkspaceType.remote,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
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
  }) async => true;

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
}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkspaceManagementScreen', () {
    var repository = _FakeWorkspaceRepository();
    var router = _FakeGoRouter();

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
      bool cloudAuthenticationRequired = false,
    }) {
      final useRepo = repo ?? repository;

      return EasyLocalization(
        child: Builder(
          builder: (context) {
            final overrides = [
              cloudAccountsProvider.overrideWith((ref) async => accounts),
              routerProvider.overrideWithValue(router),
              workspaceRepositoryProvider.overrideWithValue(useRepo),
              currentRouteWorkspaceIdProvider.overrideWithValue(workspaceId),
            ];
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
            final account = accounts.firstOrNull;
            if (cloudAuthenticationRequired && account != null) {
              overrides.add(
                cloudWorkspaceStateProvider(account.userId).overrideWith(
                  (ref) async =>
                      const CloudWorkspaceViewState.authenticationRequired(),
                ),
              );
            }

            return ProviderScope(
              overrides: overrides.cast(),
              child: MaterialApp(
                home: WorkspaceManagementScreen(workspaceId: workspaceId),
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

    testWidgets('renders loading initially', (tester) async {
      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows loading when stream has no cached data', (tester) async {
      await _pumpAndInit(
        tester,
        _buildScreen(workspaceId: 'ws-1', loading: true),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
        const WorkspaceToCreate(name: 'Workspace A', type: WorkspaceType.local),
      );
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace B', type: WorkspaceType.local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Workspace A'), findsOneWidget);
      expect(find.text('Workspace B'), findsOneWidget);
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
          cloudAuthenticationRequired: true,
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Needs sign in'), findsOneWidget);
      expect(find.text('Session expired. Sign in again.'), findsOneWidget);
      expect(find.text('Sign in again'), findsOneWidget);
    });

    testWidgets('shows routed create action without inline form', (
      tester,
    ) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: WorkspaceType.local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Create Workspace'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(AuraPopupMenuButton), findsOneWidget);
    });

    testWidgets('back button is present', (tester) async {
      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('tapping back button does not crash', (tester) async {
      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      final _ = await tester.pumpAndSettle();
    });
  });
}
