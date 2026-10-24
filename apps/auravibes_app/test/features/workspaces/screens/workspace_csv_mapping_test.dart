import 'dart:async';

import 'package:auravibes_app/features/workspaces/models/workspace_csv_input.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_csv_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_csv_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_csv_dialog.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_csv_mapping.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  for (final width in [400.0, 1200.0]) {
    testWidgets('CSV mapping uses explicit stable columns at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = .new(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var selected = <int, String>{};
      await tester.pumpWidget(
        TestableApp(
          child: HookBuilder(
            builder: (context) {
              final mapping = useState<Map<int, String>>({});
              selected = mapping.value;

              return ListView(
                children: [
                  WorkspaceCsvMapping(
                    input: const WorkspaceCsvInput(
                      headers: ['CSV title', 'CSV other'],
                      rows: [
                        ['First', 'Other'],
                      ],
                    ),
                    table: const WorkspaceTable(
                      id: 'table',
                      name: 'Items',
                      labelColumnId: 'label',
                      columns: [
                        WorkspaceColumn(id: 'label', name: 'Title'),
                        WorkspaceColumn(id: 'other', name: 'Other'),
                      ],
                      revision: 1,
                      schemaRevision: 1,
                    ),
                    mapping: mapping.value,
                    onChanged: (next) => mapping.value = next,
                    enabled: true,
                  ),
                ],
              );
            },
          ),
        ),
      );
      await _flush(tester);
      await tester.tap(find.byKey(const ValueKey('workspace_csv_mapping_0')));
      await _flush(tester);
      await tester.tap(find.text('Title'));
      await _flush(tester);
      expect(selected, {0: 'label'});
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'CSV dialog keeps controls reachable at width $width and text scale 2',
      (tester) async {
        tester.view.physicalSize = .new(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          TestableApp(
            child: const MediaQuery(
              data: .new(textScaler: .linear(2)),
              child: WorkspaceCsvDialog(
                workspaceId: 'csv',
                table: _table,
                importing: true,
              ),
            ),
            overrides: [
              workspaceCsvUsecaseProvider('csv').overrideWith(
                (ref) async => const WorkspaceCsvUsecase(_NoWrites()),
              ),
            ],
          ),
        );
        await _flush(tester);
        expect(find.text('Choose CSV'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
        await tester.tap(find.text('CSV format'));
        await _flush(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Choose CSV').hitTestable(), findsOneWidget);
      },
    );
  }
  testWidgets('CSV picker cancellation writes nothing', (tester) async {
    final pending = Completer<WorkspaceCsvInput?>();
    await tester.pumpWidget(
      TestableApp(
        child: const WorkspaceCsvDialog(
          workspaceId: 'csv',
          table: _table,
          importing: true,
        ),
        overrides: [
          workspaceCsvUsecaseProvider('csv')
              .overrideWith((ref) async => _PendingChoice(pending.future)),
        ],
      ),
    );
    await _flush(tester);
    await tester.tap(find.text('Choose CSV'));
    await tester.pump();
    expect(
      find.byWidgetPredicate((widget) => widget is PopScope && !widget.canPop),
      findsOneWidget,
    );
    pending.complete(null);
    await _flush(tester);
    expect(
      find.byWidgetPredicate((widget) => widget is PopScope && !widget.canPop),
      findsNothing,
    );
    expect(find.text('Choose CSV'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _flush(WidgetTester tester) async {
  for (var index = 0; index < 5; index++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  final _ = await tester.pumpAndSettle();
}

const _table = WorkspaceTable(
  id: 'items',
  name: 'Items',
  labelColumnId: 'label',
  columns: [WorkspaceColumn(id: 'label', name: 'Title')],
  revision: 1,
  schemaRevision: 1,
);

class const _NoWrites() implements WorkspaceCsvRepository {
  @override
  Future<WorkspaceTable> table(String id) =>
      throw StateError('No data read before file choice');
  @override
  Future<WorkspaceRecordPage> query(String id, WorkspaceRecordQuery query) =>
      throw StateError('No export before explicit action');
  @override
  Future<void> write(
    WorkspaceCsvPreview preview, {
    required bool previewOnly,
  }) => throw StateError('No import before validated explicit action');
}

class _PendingChoice extends WorkspaceCsvUsecase {
  new(this.pending) : super(const _NoWrites());
  final Future<WorkspaceCsvInput?> pending;
  @override
  Future<WorkspaceCsvInput?> pick() => pending;
}
