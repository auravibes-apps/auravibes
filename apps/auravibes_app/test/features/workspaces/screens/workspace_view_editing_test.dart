import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_view_screen.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_creation.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

const _table = WorkspaceTable(
  id: 'table',
  name: 'Items',
  labelColumnId: 'label',
  columns: [WorkspaceColumn(id: 'label', name: 'Title')],
  revision: 1,
  schemaRevision: 1,
);
void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets(
    'editing pins the original revision and keeps draft after refresh and conflict',
    (tester) async {
      final views = _Views(conflict: true);
      var revision = 1;
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            workspaceId: 'one',
            child: WorkspaceViewScreen(
              workspaceId: 'one',
              viewId: 'view',
              onBack: () => fail('Unexpected close'),
            ),
            overrides: [
              workspaceViewDataProvider(
                'one',
                'view',
              ).overrideWith((ref) async => _data(revision)),
              workspaceViewUsecaseProvider('one')
                  .overrideWith((ref) async => views),
            ],
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text(LocaleKeys.workspace_views_edit.tr()));
      final _ = await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Keep this draft');
      await tester.pump(const Duration(seconds: 11));
      revision = 2;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WorkspaceViewScreen)),
        listen: false,
      );
      container.invalidate(workspaceViewDataProvider('one', 'view'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('Keep this draft'), findsOneWidget);
      await tester.tap(_button('workspace_view_save'));
      final _ = await tester.pumpAndSettle();
      expect(views.saved?.revision, 1);
      expect(find.text('Keep this draft'), findsOneWidget);
      expect(find.text(LocaleKeys.cloud_errors_conflict.tr()), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'View creation browses source folders and creates in the current folder',
    (tester) async {
      final views = _Views(conflict: false);
      String? opened;
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            workspaceId: 'one',
            child: Scaffold(
              body: SingleChildScrollView(
                child: WorkspaceViewCreation(
                  workspaceId: 'one',
                  parentId: 'current',
                  onOpenView: (id) => opened = id,
                ),
              ),
            ),
            overrides: [
              workspaceViewUsecaseProvider('one')
                  .overrideWith((ref) async => views),
              workspaceFoldersProvider('one', null).overrideWith(
                (ref) async => [
                  const WorkspaceFolder(
                    id: 'source',
                    name: 'Source folder',
                    revision: 1,
                  ),
                ],
              ),
              workspaceFoldersProvider(
                'one',
                'source',
              ).overrideWith((ref) async => []),
              workspaceTablesProvider(
                'one',
                null,
              ).overrideWith((ref) async => []),
              workspaceTablesProvider(
                'one',
                'source',
              ).overrideWith((ref) async => [_table]),
            ],
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      final _ = await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Overview');
      await tester.tap(find.text('Source folder'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(find.text('Items'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(_button('workspace_view_create'));
      final _ = await tester.pumpAndSettle();
      expect(opened, views.saved?.id);
      expect(views.saved?.name, 'Overview');
      expect(views.saved?.parentId, 'current');
      expect(views.saved?.bindings.values.single, 'label');
      expect(views.requestId, views.saved?.id);
    },
  );
}

Finder _button(String id) => find.byWidgetPredicate(
  (widget) => widget is AuraButton && widget.identifier == id,
);
WorkspaceViewData _data(int revision) => WorkspaceViewData(
  view: WorkspaceView(
    id: 'view',
    name: 'Overview',
    tableId: 'table',
    bindings: const {'field0': 'label'},
    columnTypes: const {'label': 'text'},
    definition: A2uiSavedDefinition.fromJson({
      'version': 1,
      'components': [
        {'id': 'root', 'component': 'Text', 'text': 'Preview'},
      ],
    }),
    revision: revision,
  ),
  table: _table,
  records: const [
    WorkspaceRecord(
      id: 'record',
      tableId: 'table',
      values: {'label': 'Value'},
      revision: 1,
    ),
  ],
  needsRepair: false,
);

class _Views extends Fake implements ManageWorkspaceViewsUsecase {
  _Views({required this.conflict});
  final bool conflict;
  WorkspaceView? saved;
  String? requestId;
  @override
  Future<WorkspaceView> save(WorkspaceView view, {String? requestId}) async {
    saved = view;
    this.requestId = requestId;
    if (conflict) throw const WorkspaceTableException(conflict: true);
    return view.withRevision(view.revision + 1);
  }
}
