import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/screens/workspace_table_screen.dart';
import 'package:auravibes_app/widgets/responsive_sliding_drawer_controller.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets('table editor and unsaved record survive shell breakpoints', (
    tester,
  ) async {
    final controller = ResponsiveSlidingDrawerController();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ResponsiveSlidingDrawer(
            drawer: const SizedBox.shrink(),
            body: WorkspaceTableScreen(
              workspaceId: 'one',
              tableId: 'table',
              onBack: () => fail('Unexpected back'),
            ),
            isDarkMode: false,
            controller: controller,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const table = WorkspaceTable(
      id: 'table',
      name: 'Notes',
      labelColumnId: 'label',
      columns: [WorkspaceColumn(id: 'label', name: 'Title')],
      revision: 1,
      schemaRevision: 1,
    );
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: Router.withConfig(config: router),
          overrides: [
            workspaceTableProvider(
              'one',
              'table',
            ).overrideWith((ref) async => table),
            workspaceRecordQueryProvider.overrideWith(
              (ref, arguments) async =>
                  const WorkspaceRecordPage(records: [], hasMore: false),
            ),
          ],
          workspaceId: 'one',
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraIconButton &&
            widget.identifier == 'workspace_record_create',
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Title'));
    final _ = await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraInput &&
            widget.identifier == 'workspace_record_value',
      ),
      'Unsaved record',
    );
    for (final width in [400.0, 1200.0]) {
      tester.view.physicalSize = .new(width, 900);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Unsaved record'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AuraButton &&
              widget.identifier == 'workspace_record_save',
        ),
        findsOneWidget,
      );
    }
    await tester.tap(find.text('Notes'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.byType(AuraPopupMenuButton));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Table settings'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraButton &&
            widget.identifier == 'workspace_column_create',
      ),
    );
    final _ = await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is AuraInput && widget.identifier == 'workspace_column_name',
      ),
      'Unsaved column',
    );
    for (final width in [400.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 900);
      final _ = await tester.pumpAndSettle();
      expect(find.text('Unsaved column'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AuraButton &&
              widget.identifier == 'workspace_column_save',
        ),
        findsOneWidget,
      );
    }
  });
}
