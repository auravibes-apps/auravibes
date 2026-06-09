// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: no-object-declaration
// Required: Test fakes override noSuchMethod with Object return values.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.

import 'dart:async';

import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/domain/enums/workspace_type.dart';
import 'package:auravibes_app/domain/repositories/workspace_repository.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_management_screen.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _FakeGoRouter implements GoRouter {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final List<WorkspaceEntity> _workspaces = [];
  final _controller = StreamController<List<WorkspaceEntity>>.broadcast();
  var _nextId = 1;

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
    }) {
      final useRepo = repo ?? repository;

      return EasyLocalization(
        child: Builder(
          builder: (context) {
            final overrides = [
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

    testWidgets('shows create form when create button tapped', (
      tester,
    ) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: WorkspaceType.local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      final _ = await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows validation error for short name', (tester) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: WorkspaceType.local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      final _ = await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'AB');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      final _ = await tester.pumpAndSettle();

      expect(
        find.text('Workspace name must be at least 3 characters'),
        findsOneWidget,
      );
    });

    testWidgets('shows validation error for long name', (tester) async {
      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.text('Create Workspace'));
      final _ = await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'A' * 21);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      final _ = await tester.pumpAndSettle();

      expect(
        find.text('Workspace name must be at most 20 characters'),
        findsOneWidget,
      );
    });

    testWidgets('tapping edit shows edit form', (tester) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: WorkspaceType.local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      final _ = await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('tapping check saves workspace and exits edit', (
      tester,
    ) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: WorkspaceType.local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      final _ = await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'New Name');
      await tester.tap(find.byIcon(Icons.check));
      final _ = await tester.pumpAndSettle();

      expect(find.text('New Name'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('tapping close cancels edit and exits edit', (tester) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: WorkspaceType.local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      final _ = await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'New Name');
      await tester.tap(find.byIcon(Icons.close));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Workspace A'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('submitting edit via keyboard saves', (tester) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: WorkspaceType.local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      final _ = await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Keyboard Name');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      final _ = await tester.pumpAndSettle();

      expect(find.text('Keyboard Name'), findsOneWidget);
    });

    testWidgets('delete confirmation dialog shown', (tester) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: WorkspaceType.local),
      );
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace B', type: WorkspaceType.local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-2'));
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete).first);
      final _ = await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('cancel delete keeps workspace', (tester) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace A', type: WorkspaceType.local),
      );
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'Workspace B', type: WorkspaceType.local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-2'));
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete).first);
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Workspace A'), findsOneWidget);
    });

    testWidgets('back button is present', (tester) async {
      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('cancel create form returns to list', (tester) async {
      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.text('Create Workspace'));
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      final _ = await tester.pumpAndSettle();

      expect(find.text('Create Workspace'), findsOneWidget);
    });

    testWidgets('confirm delete removes workspace', (tester) async {
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'KeepMe', type: WorkspaceType.local),
      );
      final _ = await repository.createWorkspace(
        const WorkspaceToCreate(name: 'ToDelete', type: WorkspaceType.local),
      );

      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete).last);
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      final _ = await tester.pumpAndSettle();

      expect(find.text('ToDelete'), findsNothing);
      expect(find.text('KeepMe'), findsOneWidget);
    });

    testWidgets('tapping back button does not crash', (tester) async {
      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      final _ = await tester.pumpAndSettle();
    });

    testWidgets('creates workspace with valid name through form', (
      tester,
    ) async {
      await _pumpAndInit(tester, _buildScreen(workspaceId: 'ws-1'));
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.text('Create Workspace'));
      final _ = await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'New Workspace');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      final _ = await tester.pumpAndSettle();

      expect(find.text('New Workspace'), findsOneWidget);
    });
  });
}
