import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_connector_write_journal.dart';
import 'package:auravibes_app/data/repositories/local_workspace_view_repository.dart';
import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/features/service_connections/usecases/run_connector_tool_usecase.dart';
import 'package:auravibes_app/features/service_connections/usecases/sync_connector_tool_permissions_usecase.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_items_screen.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_view_screen.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_connected_editor.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final width in [400.0, 1200.0]) {
    testWidgets(
      'Directory creates live View; revoke and disconnect clear source $width',
      (tester) async {
        tester.view.physicalSize = .new(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final database = AppDatabase(connection: NativeDatabase.memory());
        addTearDown(database.close);
        final permissions = SyncConnectorToolPermissionsUsecase(database);
        final connector = connectorDefinitions.singleWhere(
          (value) => value.identifier == 'brave',
        );
        final toolId = connectorToolId(
          connector,
          connector.tools.firstWhere((tool) => tool.slug == 'web_search'),
        );
        var requests = 0;
        var liveValue = 'Authorized live source';
        final repository = ServiceConnectionRepository(database, .new(.new()));
        final run = RunConnectorToolUsecase(
          repository,
          .new(() => repository),
          .new(const ResolveConnectorRequestTemplate(), (_) {
            requests++;

            return .fromFuture(
              .value(
                .new(
                  statusCode: 200,
                  body: liveValue,
                  headers: {},
                  elapsed: .zero,
                ),
              ),
            );
          }),
          null,
          permissions,
          journalForWorkspace: (id) => LocalConnectorWriteJournal(database, id),
        );
        await tester.runAsync(() async {
          final _ = await database
              .into(database.workspaces)
              .insert(
                WorkspacesCompanion.insert(
                  id: const .new('one'),
                  name: 'One',
                  type: .local,
                ),
              );
          final _ = await repository.createConnectorConnection((
            workspaceId: 'one',
            connectorId: 'brave',
            name: 'Connected source account',
            apiKey: 'synthetic-view-key',
          ));
          await permissions.call(workspaceId: 'one');
          final _ = await database.workspaceToolsDao.setWorkspaceToolEnabled(
            'one',
            toolId,
            isEnabled: true,
          );
          await tester.pumpWidget(
            TestableApp(
              child: const WorkspaceItemsScreen(workspaceId: 'one'),
              overrides: [
                appDatabaseProvider.overrideWithValue(database),
                serviceConnectionRepositoryProvider.overrideWithValue(
                  repository,
                ),
                runConnectorToolUsecaseProvider.overrideWithValue(run),
              ],
              workspaceId: 'one',
            ),
          );
        });
        Future<void> flush() async {
          await tester.pump();
          await tester.runAsync(() async {
            final _ = await tester.pumpAndSettle();
          });
        }

        await flush();
        await tester.tap(find.byKey(const ValueKey('directory_create')));
        await flush();
        await tester.tap(find.text('View'));
        await flush();
        await tester.enterText(
          find.byWidgetPredicate(
            (widget) =>
                widget is AuraInput &&
                widget.identifier == 'workspace_view_name',
          ),
          'Connected report',
        );
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is AuraButton &&
                widget.identifier == 'workspace_view_connected_create',
          ),
        );
        await flush();
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is AuraDropdownSelector<String> &&
                widget.identifier == 'workspace_connected_tool',
          ),
        );
        await flush();
        await tester.tap(find.text('Brave Search: Web search').last);
        await flush();
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is AuraDropdownSelector<String> &&
                widget.identifier == 'workspace_connected_connection',
          ),
        );
        await flush();
        await tester.tap(find.textContaining('Connected source account').last);
        await flush();
        final input = find
            .byWidgetPredicate(
              (widget) =>
                  widget is AuraInput &&
                  widget.identifier == 'workspace_connected_input_query',
            )
            .first;
        await tester.enterText(input, 'example');
        final save = find.byWidgetPredicate(
          (widget) =>
              widget is AuraButton &&
              widget.identifier == 'workspace_connected_save',
        );
        await tester.scrollUntilVisible(
          save,
          120,
          scrollable: find
              .ancestor(
                of: find.byType(WorkspaceConnectedEditor),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await flush();
        await tester.runAsync(() => tester.tap(save));
        await flush();
        final failures = tester
            .widgetList<WorkspaceItemFailure>(find.byType(WorkspaceItemFailure))
            .map((value) => value.error.runtimeType.toString())
            .toList();
        expect(failures, isEmpty, reason: 'Connected source save failed');
        expect(find.byType(WorkspaceViewScreen), findsOneWidget);
        expect(find.text('Authorized live source'), findsOneWidget);
        expect(requests, greaterThan(0));
        final beforeRevocation = requests;
        await tester.runAsync(() async {
          final views = await LocalWorkspaceViewRepository(
            database,
            'one',
          ).list();
          expect(views.single.isConnectedOnly, true);
          expect(views.single.connected?.inputs, {'query': 'example'});
          final _ = await database.workspaceToolsDao.setWorkspaceToolEnabled(
            'one',
            toolId,
            isEnabled: false,
          );
        });
        await flush();
        expect(find.text('Authorized live source'), findsNothing);
        expect(find.textContaining('Access denied'), findsOneWidget);
        expect(requests, beforeRevocation);
        liveValue = 'Fresh live source';
        await tester.runAsync(() async {
          final _ = await database.workspaceToolsDao.setWorkspaceToolEnabled(
            'one',
            toolId,
            isEnabled: true,
          );
        });
        await flush();
        expect(find.text('Authorized live source'), findsNothing);
        expect(find.text('Fresh live source'), findsOneWidget);
        expect(requests, greaterThan(beforeRevocation));
        final beforeDisconnect = requests;
        await tester.runAsync(() async {
          final views = await LocalWorkspaceViewRepository(
            database,
            'one',
          ).list();
          final id = views.single.connected?.connectionId;
          if (id == null) fail('Saved source must retain selected Connection');
          expect(id, startsWith('service:'));
          await repository.deleteConnectorConnection(
            id.replaceFirst('service:', ''),
            workspaceId: 'one',
          );
        });
        await flush();
        expect(find.text('Authorized live source'), findsNothing);
        expect(find.textContaining('Connection unavailable'), findsOneWidget);
        expect(find.text('Fresh live source'), findsNothing);
        expect(requests, beforeDisconnect);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
