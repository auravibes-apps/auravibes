import 'package:auravibes_app/features/browser/screens/sidebar_directory.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_folder.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets(
    'directory enters folders and opens items without granting access',
    (tester) async {
      WorkspaceChatItem? opened;
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            workspaceId: 'one',
            child: SidebarDirectory(
              workspaceId: 'one',
              onOpen: (item, name) => opened = item,
            ),
            overrides: [
              workspaceFoldersProvider.overrideWith(
                (ref, arguments) async => [
                  const WorkspaceFolder(
                    id: 'folder',
                    name: 'Folder',
                    revision: 1,
                  ),
                ],
              ),
              workspaceTablesProvider.overrideWith(
                (ref, arguments) async => arguments.$2 == null
                    ? <WorkspaceTable>[]
                    : [
                        const WorkspaceTable(
                          id: 'table',
                          name: 'Contacts',
                          labelColumnId: 'name',
                          columns: [],
                          revision: 1,
                          schemaRevision: 1,
                        ),
                      ],
              ),
              workspaceViewsProvider.overrideWith(
                (ref, arguments) async => arguments.$2 == null
                    ? []
                    : [WorkspaceView.connectedDraft(name: 'Overview')],
              ),
              workspaceFilesProvider.overrideWith(
                (ref, arguments) async => arguments.$2 == null
                    ? []
                    : [
                        const WorkspaceFile(
                          id: 'file',
                          name: 'Notes',
                          assetId: 'asset',
                          revision: 1,
                        ),
                      ],
              ),
            ],
          ),
        );
      });
      final _ = await tester.pumpAndSettle();
      expect(find.text('Folder'), findsOneWidget);
      await tester.tap(find.text('Folder'));
      final _ = await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(opened, isNull);
      await tester.tap(find.text('Contacts'));
      expect(opened?.id, 'table');
      expect(opened?.kind, 'table');
      await tester.tap(find.text('Notes'));
      expect(opened?.id, 'file');
      expect(opened?.kind, 'file');
      await tester.tap(find.text('Overview'));
      expect(opened?.kind, 'view');
    },
  );
}
