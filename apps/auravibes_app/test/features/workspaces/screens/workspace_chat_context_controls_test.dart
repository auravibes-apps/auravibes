import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_context_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_record_query_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_conversation_context_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_chat_context_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/query_workspace_records_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_chat_context_toolbar.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_context_record_picker.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:drift/native.dart';
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
    'record selection survives pages and search in a short viewport',
    (tester) async {
      tester.view.physicalSize = const Size(400, 450);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('one'),
              name: 'One',
              type: .local,
            ),
          );
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'one'),
      );
      final table = await tables.create(name: 'Rows', labelName: 'Title');
      for (var index = 0; index < 51; index++) {
        final _ = await tables.createRecord(
          table: table,
          values: {table.labelColumnId: 'Record $index'},
        );
      }
      final queryRepository = LocalWorkspaceRecordQueryRepository(
        database,
        'one',
      );
      final firstPage = await queryRepository.query(
        table.id,
        const WorkspaceRecordQuery(),
      );
      final first = firstPage.records.first;
      List<String>? result;
      await tester.pumpWidget(
        TestableApp(
          child: MediaQuery(
            data: const MediaQueryData(
              size: .new(400, 450),
              textScaler: .linear(2),
              viewInsets: .only(bottom: 180),
            ),
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => unawaited(() async {
                    result = await showDialog<List<String>>(
                      context: context,
                      builder: (_) => MediaQuery(
                        data: const MediaQueryData(
                          size: .new(400, 450),
                          textScaler: .linear(2),
                          viewInsets: .only(bottom: 180),
                        ),
                        child: WorkspaceContextRecordPicker(
                          workspaceId: 'one',
                          table: table,
                        ),
                      ),
                    );
                  }()),
                  child: const Text('Choose'),
                ),
              ),
            ),
          ),
          overrides: [
            workspaceRecordQueryUsecaseProvider('one').overrideWith(
              (ref) async => QueryWorkspaceRecordsUsecase(queryRepository),
            ),
          ],
          workspaceId: 'one',
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('Choose'));
      await _settle(tester);
      final row = find.widgetWithText(
        CheckboxListTile,
        '${first.values[table.labelColumnId]}',
      );
      await tester.scrollUntilVisible(
        row,
        100,
        scrollable: find
            .descendant(
              of: find.byType(WorkspaceContextRecordPicker),
              matching: find.byType(Scrollable),
            )
            .last,
      );
      await tester.ensureVisible(
        find.text('${first.values[table.labelColumnId]}'),
      );
      await tester.tap(find.text('${first.values[table.labelColumnId]}'));
      await _settle(tester);
      await tester.ensureVisible(find.text('Next page'));
      await tester.tap(find.text('Next page'));
      await _settle(tester);
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(
        find.byType(TextField),
        '${first.values[table.labelColumnId]}',
      );
      await _settle(tester);
      await tester.scrollUntilVisible(
        row,
        100,
        scrollable: find
            .descendant(
              of: find.byType(WorkspaceContextRecordPicker),
              matching: find.byType(Scrollable),
            )
            .last,
      );
      expect(tester.widget<CheckboxListTile>(row).value, isTrue);
      await tester.ensureVisible(find.text('Share with AI'));
      await tester.tap(find.text('Share with AI'));
      await _settle(tester);
      expect(result, [first.id]);
      expect(tester.takeException(), isNull);
    },
  );
  for (final mode in ConversationToolAccessMode.values) {
    testWidgets(
      'explicit context consent, cancel and revoke remain separate in $mode',
      (tester) async {
        tester.view.physicalSize = const Size(400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final database = AppDatabase(connection: NativeDatabase.memory());
        addTearDown(database.close);
        final _ = await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: const .new('one'),
                name: 'One',
                type: .local,
              ),
            );
        final conversations = ConversationRepository(database);
        final conversation = await conversations.createConversation(
          .new(title: 'Chat', workspaceId: 'one', toolAccessMode: mode),
        );
        final tables = OrganizeWorkspaceTablesUsecase(
          LocalWorkspaceTableRepository(database, 'one'),
        );
        var table = await tables.create(
          name: 'Selected item',
          labelName: 'Title',
        );
        final target = await tables.create(
          name: 'Linked item',
          labelName: 'Title',
        );
        final linked = await tables.createRecord(
          table: target,
          values: {target.labelColumnId: 'Hidden linked value'},
        );
        table = await tables.saveColumn(
          table: table,
          column: .new(
            id: '',
            name: 'Related',
            type: .reference,
            targetTableId: target.id,
          ),
        );
        final reference = table.columns.singleWhere(
          (column) => column.type == .reference,
        );
        final first = await tables.createRecord(
          table: table,
          values: {table.labelColumnId: 'Duplicate', reference.id: linked.id},
        );
        final _ = await tables.createRecord(
          table: table,
          values: {table.labelColumnId: 'Private unselected'},
        );
        final repository = LocalWorkspaceContextRepository(database, 'one');
        final consent = ManageWorkspaceChatContextUsecase(
          workspaceId: 'one',
          repository: repository,
          commands: .new(tables: tables),
          canAccess: (id) async => id == conversation.id,
        );
        final sent = <ChatDraft>[];
        await tester.pumpWidget(
          TestableApp(
            child: Scaffold(
              body: WorkspaceChatContextToolbar(
                workspaceId: 'one',
                conversationId: conversation.id,
                item: .new(id: table.id, kind: 'table'),
                onClose: () => fail('Unexpected close'),
              ),
            ),
            overrides: [
              workspaceTableUsecaseProvider('one')
                  .overrideWith((ref) async => tables),
              workspaceRecordQueryUsecaseProvider('one').overrideWith(
                (ref) async => QueryWorkspaceRecordsUsecase(
                  LocalWorkspaceRecordQueryRepository(database, 'one'),
                ),
              ),
              workspaceConversationContextUsecaseProvider('one')
                  .overrideWith((ref) async => consent),
              sendMessageUsecaseProvider('one').overrideWithValue(
                SendMessageUsecase.cloud((_, draft) {
                  sent.add(draft);

                  return Future.value();
                }),
              ),
            ],
            workspaceId: 'one',
          ),
        );
        await _settle(tester);
        expect((await repository.read(conversation.id)).selection, isNull);
        await tester.tap(find.byType(AuraPopupMenuButton));
        await _settle(tester);
        await tester.tap(find.text('Share with AI'));
        await _settle(tester);
        expect(find.byType(WorkspaceContextRecordPicker), findsOneWidget);
        expect(
          tester
              .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
              .every((widget) => widget.value == false),
          isTrue,
        );
        await tester.tap(find.text('Cancel'));
        await _settle(tester);
        expect((await repository.read(conversation.id)).selection, isNull);
        expect(sent, isEmpty);
        await tester.tap(find.byType(AuraPopupMenuButton));
        await _settle(tester);
        await tester.tap(find.text('Share with AI'));
        await _settle(tester);
        await tester.tap(find.widgetWithText(CheckboxListTile, 'Duplicate'));
        await _settle(tester);
        await tester.tap(find.text('Share with AI'));
        await _settle(tester);
        expect((await repository.read(conversation.id)).selection?.recordIds, [
          first.id,
        ]);
        expect(sent, hasLength(1));
        expect(
          sent.single.metadataJson,
          contains('workspaceContextSelectionProof'),
        );
        expect(sent.single.text, isNot(contains('Private unselected')));
        await tester.tap(find.byType(AuraPopupMenuButton));
        await _settle(tester);
        await tester.tap(find.text('Inspect shared context'));
        await _settle(tester);
        expect(find.text('Duplicate'), findsOneWidget);
        expect(find.text('Private unselected'), findsNothing);
        expect(find.text('Hidden linked value'), findsNothing);
        expect(find.text(linked.id), findsNothing);
        expect(
          find.text(
            'Links outside this chat’s shared context stay hidden. Edit links in Directory.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Close'));
        await _settle(tester);
        await tester.tap(find.byType(AuraPopupMenuButton));
        await _settle(tester);
        await tester.tap(find.text('Stop sharing with AI'));
        await _settle(tester);
        expect((await repository.read(conversation.id)).selection, isNull);
        expect(sent, hasLength(2));
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  final _ = await tester.pumpAndSettle();
}
