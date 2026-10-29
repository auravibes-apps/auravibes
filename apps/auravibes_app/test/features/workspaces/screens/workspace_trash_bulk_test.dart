import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_revision.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_history_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_trash_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_history_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_panel.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

class _History extends Fake implements WorkspaceHistoryRepository {
  final List<WorkspaceTrashBatch> rows = [
    const WorkspaceTrashBatch(
      id: 'one',
      target: .new(kind: .folder, id: 'one', revision: 1),
      name: 'First',
      affectedCount: 1,
    ),
    const WorkspaceTrashBatch(
      id: 'two',
      target: .new(kind: .folder, id: 'two', revision: 1),
      name: 'Blocked',
      affectedCount: 1,
    ),
    const WorkspaceTrashBatch(
      id: 'three',
      target: .new(kind: .folder, id: 'three', revision: 1),
      name: 'Last',
      affectedCount: 1,
    ),
  ];
  final List<String> calls = [];

  @override
  Future<void> permanentlyDelete(WorkspaceTrashTarget target) async {
    calls.add(target.id);
    if (target.id == 'two') throw const WorkspaceTableException();
    rows.removeWhere((row) => row.target.id == target.id);
  }
}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
    'delete all shown stops at failure and refreshes remaining rows',
    (tester) async {
      final history = _History();
      await tester.runAsync(
        () => tester.pumpWidget(
          TestableApp(
            child: Builder(
              builder: (context) => AuraButton(
                onPressed: () =>
                    unawaited(WorkspaceTrashPanel.open(context, 'local')),
                child: const Text('Open'),
                identifier: 'open_trash',
              ),
            ),
            overrides: [
              workspaceHistoryUsecaseProvider('local').overrideWith(
                (ref) async => ManageWorkspaceHistoryUsecase(history),
              ),
              workspaceTrashProvider('local')
                  .overrideWith((ref) async => List.of(history.rows)),
            ],
            workspaceId: 'local',
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      Finder button(String id) => find.byWidgetPredicate(
        (widget) => widget is AuraButton && widget.identifier == id,
      );
      await tester.tap(button('open_trash'));
      final _ = await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is AuraIconButton &&
              widget.identifier == 'workspace_trash_delete_all',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(history.calls, isEmpty);
      await tester.tap(button('workspace_history_confirm'));
      final _ = await tester.pumpAndSettle();
      expect(history.calls, ['one', 'two']);
      expect(find.text('First'), findsNothing);
      expect(find.text('Blocked'), findsOneWidget);
      expect(find.text('Last'), findsOneWidget);
      expect(find.byType(WorkspaceTrashPanel), findsOneWidget);
      expect(find.byType(WorkspaceItemFailure), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
