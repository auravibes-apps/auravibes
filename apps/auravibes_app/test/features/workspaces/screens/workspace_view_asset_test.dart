import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_assets_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_view_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets(
    'View keeps asset IDs outside generated surface and uses host preview',
    (tester) async {
      var returned = false;
      final data = WorkspaceViewData(
        view: .new(
          id: 'view',
          name: 'Overview',
          tableId: 'table',
          bindings: {'assets': 'assets'},
          columnTypes: {'assets': 'attachment'},
          definition: .fromJson({
            'version': 1,
            'components': [
              {
                'id': 'root',
                'component': 'Table',
                'columns': {'path': '/columns'},
                'rows': {'path': '/rows'},
              },
            ],
          }),
          revision: 1,
        ),
        table: const WorkspaceTable(
          id: 'table',
          name: 'Items',
          labelColumnId: 'label',
          columns: [
            WorkspaceColumn(id: 'label', name: 'Title'),
            WorkspaceColumn(id: 'assets', name: 'Documents', type: .attachment),
          ],
          revision: 1,
          schemaRevision: 1,
          canManage: false,
        ),
        records: [
          const WorkspaceRecord(
            id: 'record',
            tableId: 'table',
            values: {
              'label': 'Notes record',
              'assets': ['asset-secret-id'],
            },
            revision: 1,
          ),
        ],
        needsRepair: false,
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            child: WorkspaceViewScreen(
              workspaceId: 'one',
              viewId: 'view',
              onBack: () => returned = true,
            ),
            overrides: [
              workspaceViewDataProvider(
                'one',
                'view',
              ).overrideWith((ref) async => data),
              workspaceAssetDescriptorProvider(
                'one',
                'asset-secret-id',
              ).overrideWith(
                (ref) async => const WorkspaceAsset(
                  id: 'asset-secret-id',
                  name: 'notes.txt',
                  mimeType: 'text/plain',
                  sizeBytes: 5,
                  checksum: 'unused',
                ),
              ),
            ],
            workspaceId: 'one',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      final _ = await tester.pumpAndSettle();
      expect(find.textContaining('asset-secret-id'), findsNothing);
      await tester.tap(find.text('Notes record'));
      final _ = await tester.pumpAndSettle();
      expect(find.text('notes.txt'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.arrow_back));
      expect(returned, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
