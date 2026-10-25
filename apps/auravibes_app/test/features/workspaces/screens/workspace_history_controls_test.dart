import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_history_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_history_blocked_exception.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_history_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_trash_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_history_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_trash_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_history_panel.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_item_failure.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_record_trash_menu.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_trash_panel.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('Roboto')..addFont(_sdkRoboto())).load();
  });
  testWidgets('authorized purge blocker explains the required repair', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      const RepaintBoundary(
        key: ValueKey('history_capture'),
        child: TestableApp(
          child: Scaffold(
            body: WorkspaceItemFailure(
              error: WorkspaceHistoryBlockedException(['source-record']),
            ),
          ),
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('source-record'), findsOneWidget);
    expect(find.textContaining('Resolve the listed source'), findsOneWidget);
    await _capture(tester, 'blocked-400-2');
    expect(tester.takeException(), isNull);
  });
  for (final width in [400.0, 1200.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'history restore stays usable at width $width and text $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          tester.view.physicalSize = .new(width, 800);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final database = AppDatabase(connection: NativeDatabase.memory());
          addTearDown(database.close);
          final _ = await database
              .into(database.workspaces)
              .insert(
                WorkspacesCompanion.insert(
                  id: const .new('local'),
                  name: 'Local',
                  type: .local,
                ),
              );
          final tables = OrganizeWorkspaceTablesUsecase(
            LocalWorkspaceTableRepository(database, 'local'),
          );
          final table = await tables.create(name: 'Data', labelName: 'Name');
          final first = await tables.createRecord(
            table: table,
            values: {table.labelColumnId: 'Original value'},
          );
          final second = await tables.updateRecord(
            table: table,
            record: first,
            values: {table.labelColumnId: 'Current value'},
          );
          final history = ManageWorkspaceHistoryUsecase(
            LocalWorkspaceHistoryRepository(database, 'local'),
          );
          var restoredCalls = 0;
          final target = WorkspaceTrashTarget(
            kind: .record,
            id: first.id,
            revision: second.revision,
            tableId: table.id,
          );
          await tester.runAsync(
            () => tester.pumpWidget(
              RepaintBoundary(
                key: const ValueKey('history_capture'),
                child: TestableApp(
                  child: Builder(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: .linear(scale)),
                      child: Builder(
                        builder: (context) => WorkspaceRecordTrashMenu(
                          workspaceId: 'local',
                          record: second,
                          onTrashed: () => fail('Unexpected record Trash'),
                          onRestored: () => restoredCalls++,
                        ),
                      ),
                    ),
                  ),
                  overrides: [
                    workspaceHistoryUsecaseProvider('local')
                        .overrideWith((ref) async => history),
                  ],
                  workspaceId: 'local',
                ),
              ),
            ),
          );
          await _settle(tester);
          Finder button(String id) => find.byWidgetPredicate(
            (widget) => widget is AuraButton && widget.identifier == id,
          );
          await tester.tap(
            find.byWidgetPredicate(
              (widget) =>
                  widget is AuraIconButton &&
                  widget.identifier == 'workspace_record_overflow',
            ),
          );
          await _settle(tester);
          await tester.tap(find.text('Revision history'));
          await _settle(tester);
          expect(find.text('Current value'), findsOneWidget);
          await _capture(tester, 'history-$width-$scale');
          await tester.scrollUntilVisible(
            button('workspace_history_restore_1'),
            200,
          );
          expect(find.text('Original value'), findsOneWidget);
          await tester.ensureVisible(button('workspace_history_restore_1'));
          await tester.tap(button('workspace_history_restore_1'));
          final _ = await tester.pump();
          final _ = await tester.pump(const Duration(milliseconds: 400));
          await _capture(tester, 'approval-$width-$scale');
          await tester.ensureVisible(button('workspace_history_cancel'));
          await tester.tap(button('workspace_history_cancel'));
          await _settle(tester);
          expect((await tables.record(table.id, first.id)).revision, 2);
          expect(restoredCalls, 0);
          await tester.tap(button('workspace_history_restore_1'));
          final _ = await tester.pump();
          final _ = await tester.pump(const Duration(milliseconds: 400));
          await tester.ensureVisible(button('workspace_history_confirm'));
          await tester.tap(button('workspace_history_confirm'));
          await _settle(tester);
          expect((await tables.record(table.id, first.id)).revision, 3);
          expect(restoredCalls, 1);
          expect(
            (await tables.record(
              table.id,
              first.id,
            )).values[table.labelColumnId],
            'Original value',
          );
          unawaited(
            WorkspaceHistoryPanel.open(
              tester.element(find.byType(WorkspaceRecordTrashMenu)),
              'local',
              target,
              canRestore: false,
            ),
          );
          await _settle(tester);
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is AuraButton &&
                  (widget.identifier?.startsWith(
                        'workspace_history_restore_',
                      ) ??
                      false),
            ),
            findsNothing,
          );
          expect(find.text('Original value'), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
      testWidgets('permanent deletion requires approval at $width / $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = .new(width, 800);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final database = AppDatabase(connection: NativeDatabase.memory());
        addTearDown(database.close);
        final _ = await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: const .new('local'),
                name: 'Local',
                type: .local,
              ),
            );
        final tables = OrganizeWorkspaceTablesUsecase(
          LocalWorkspaceTableRepository(database, 'local'),
        );
        final table = await tables.create(name: 'Data', labelName: 'Name');
        final record = await tables.createRecord(
          table: table,
          values: {table.labelColumnId: 'Delete me'},
        );
        final trash = ManageWorkspaceTrashUsecase(
          LocalWorkspaceTrashRepository(database, 'local'),
        );
        final history = ManageWorkspaceHistoryUsecase(
          LocalWorkspaceHistoryRepository(database, 'local'),
        );
        final batch = await trash.apply(
          .new(
            kind: .record,
            id: record.id,
            tableId: table.id,
            revision: record.revision,
          ),
          approve: (_) async => true,
        );
        if (batch == null) fail('Expected Trash batch');
        await tester.runAsync(
          () => tester.pumpWidget(
            RepaintBoundary(
              key: const ValueKey('history_capture'),
              child: TestableApp(
                child: Builder(
                  builder: (context) => AuraButton(
                    onPressed: () =>
                        unawaited(WorkspaceTrashPanel.open(context, 'local')),
                    child: const Text('Trash fixture'),
                    identifier: 'open_trash',
                  ),
                ),
                overrides: [
                  workspaceHistoryUsecaseProvider('local')
                      .overrideWith((ref) async => history),
                  workspaceTrashUsecaseProvider('local')
                      .overrideWith((ref) async => trash),
                ],
                workspaceId: 'local',
              ),
            ),
          ),
        );
        Finder button(String id) => find.byWidgetPredicate(
          (widget) => widget is AuraButton && widget.identifier == id,
        );
        await _settle(tester);
        await tester.tap(button('open_trash'));
        await _settle(tester);
        final purge = button('workspace_permanent_delete_${record.id}');
        await tester.scrollUntilVisible(purge, 200);
        await tester.tap(purge);
        final _ = await tester.pump();
        final _ = await tester.pump(const Duration(milliseconds: 400));
        await tester.ensureVisible(button('workspace_history_cancel'));
        await tester.tap(button('workspace_history_cancel'));
        await _settle(tester);
        expect((await trash.list()).single.id, batch.id);
        await tester.tap(purge);
        final _ = await tester.pump();
        final _ = await tester.pump(const Duration(milliseconds: 400));
        await tester.ensureVisible(button('workspace_history_confirm'));
        await tester.tap(button('workspace_history_confirm'));
        await _settle(tester);
        expect(await trash.list(), isEmpty);
        expect(tester.takeException(), isNull);
      });
      testWidgets('retention policy persists at $width / $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = .new(width, 800);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final database = AppDatabase(connection: NativeDatabase.memory());
        addTearDown(database.close);
        final _ = await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: const .new('local'),
                name: 'Local',
                type: .local,
              ),
            );
        final tables = OrganizeWorkspaceTablesUsecase(
          LocalWorkspaceTableRepository(database, 'local'),
        );
        final table = await tables.create(name: 'Data', labelName: 'Name');
        final history = ManageWorkspaceHistoryUsecase(
          LocalWorkspaceHistoryRepository(database, 'local'),
        );
        await tester.runAsync(
          () => tester.pumpWidget(
            RepaintBoundary(
              key: const ValueKey('history_capture'),
              child: TestableApp(
                child: Builder(
                  builder: (context) => AuraButton(
                    onPressed: () => unawaited(
                      WorkspaceHistoryPanel.open(
                        context,
                        'local',
                        .new(
                          kind: .table,
                          id: table.id,
                          revision: table.revision,
                        ),
                      ),
                    ),
                    child: const Text('History fixture'),
                    identifier: 'open_policy',
                  ),
                ),
                overrides: [
                  workspaceHistoryUsecaseProvider('local')
                      .overrideWith((ref) async => history),
                ],
                workspaceId: 'local',
              ),
            ),
          ),
        );
        Finder button(String id) => find.byWidgetPredicate(
          (widget) => widget is AuraButton && widget.identifier == id,
        );
        final settings = find.byWidgetPredicate(
          (widget) =>
              widget is AuraIconButton &&
              widget.identifier == 'workspace_history_retention',
        );
        await _settle(tester);
        await tester.tap(button('open_policy'));
        await _settle(tester);
        await tester.tap(settings);
        await _settle(tester);
        await _capture(tester, 'policy-$width-$scale');
        await tester.enterText(
          find.byKey(const ValueKey('workspace_history_policy_days')),
          '1',
        );
        await tester.ensureVisible(button('workspace_history_policy_save'));
        await tester.tap(button('workspace_history_policy_save'));
        final _ = await tester.pump();
        final _ = await tester.pump(const Duration(milliseconds: 400));
        await tester.ensureVisible(button('workspace_history_cancel'));
        await tester.tap(button('workspace_history_cancel'));
        await _settle(tester);
        expect((await history.policy()).days, isNull);
        await tester.tap(button('workspace_history_policy_save'));
        final _ = await tester.pump();
        final _ = await tester.pump(const Duration(milliseconds: 400));
        await tester.ensureVisible(button('workspace_history_confirm'));
        await tester.tap(button('workspace_history_confirm'));
        await _settle(tester);
        expect((await history.policy()).days, 1);
        await tester.tap(settings);
        await _settle(tester);
        await tester.enterText(
          find.byKey(const ValueKey('workspace_history_policy_days')),
          '',
        );
        await tester.ensureVisible(button('workspace_history_policy_save'));
        await tester.tap(button('workspace_history_policy_save'));
        final _ = await tester.pump();
        final _ = await tester.pump(const Duration(milliseconds: 400));
        await tester.ensureVisible(button('workspace_history_confirm'));
        await tester.tap(button('workspace_history_confirm'));
        await _settle(tester);
        expect((await history.policy()).days, isNull);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  final _ = await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  const destination = String.fromEnvironment('HISTORY_CAPTURE');
  if (destination.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('history_capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory(destination);
    final _ = await directory.create(recursive: true);
    if (data == null) fail('Capture did not produce PNG bytes');
    final _ = await File('${directory.path}/$name.png')
        .writeAsBytes(data.buffer.asUint8List());
    image.dispose();
  });
}

Future<ByteData> _sdkRoboto() async {
  for (
    var directory = File(Platform.resolvedExecutable).parent;
    directory.path != directory.parent.path;
    directory = directory.parent
  ) {
    final font = File('${directory.path}/material_fonts/Roboto-Regular.ttf');
    if (font.existsSync()) {
      return (await font.readAsBytes()).buffer.asByteData();
    }
  }
  throw StateError('Flutter SDK Roboto font unavailable for capture');
}
