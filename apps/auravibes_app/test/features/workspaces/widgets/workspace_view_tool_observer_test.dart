import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/providers/message_id_list.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_view.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_open_view_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_record_query_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_views_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/query_workspace_records_usecase.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_view_tool_observer.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Views extends Mock implements ManageWorkspaceViewsUsecase;

class _ViewData extends Mock implements WorkspaceViewData {
  new([WorkspaceView? view])
    : _view = view ?? WorkspaceView.connectedDraft(name: 'Overview');
  final WorkspaceView _view;
  @override
  WorkspaceView get view => _view;
}

class _Tables extends Mock implements OrganizeWorkspaceTablesUsecase;

class _Queries extends Mock implements QueryWorkspaceRecordsUsecase;

class _Table extends Mock implements WorkspaceTable;

MessageEntity _message(List<MessageToolCallEntity> calls) => MessageEntity(
  id: 'message',
  conversationId: 'chat',
  content: '',
  messageType: .toolCall,
  isUser: false,
  status: .sent,
  createdAt: .new(2026),
  updatedAt: .new(2026),
  metadata: .new(toolCalls: calls),
);

MessageToolCallEntity _call(
  String id,
  String view, {
  String action = 'createView',
  String? name,
}) {
  final toolName =
      name ??
      switch (action) {
        'saveView' => workspaceSaveViewToolName,
        'createTable' => workspaceCreateTableToolName,
        'renameTable' => workspaceRenameTableToolName,
        'saveColumn' => workspaceSaveColumnToolName,
        'createRecord' => workspaceAddRowToolName,
        'updateRecord' => workspaceUpdateRecordToolName,
        _ => workspaceCreateViewToolName,
      };

  return MessageToolCallEntity(
    id: id,
    name: toolName,
    argumentsRaw: jsonEncode(const {}),
    responseRaw: jsonEncode({'id': view, 'kind': 'view'}),
    resultStatus: .success,
  );
}

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  testWidgets(
    'opens only new successful authorized views once, not history or failures',
    (tester) async {
      final stream = StreamController<List<MessageEntity>>();
      addTearDown(stream.close);
      final workspace = ValueNotifier('ws');
      addTearDown(workspace.dispose);
      final views = _Views();
      final tables = _Tables();
      var queryLoads = 0;
      var directoryLoads = 0;
      when(() => tables.table(any())).thenAnswer((_) async => _Table());
      when(() => tables.table('denied-table'))
          .thenThrow(const WorkspaceTableException(denied: true));
      when(() => views.open('stale')).thenThrow(StateError('transient'));
      when(() => views.open('allowed')).thenAnswer((_) async => _ViewData());
      when(() => views.open('denied'))
          .thenThrow(const WorkspaceTableException(denied: true));
      var retryCount = 0;
      when(() => views.open('retry')).thenAnswer((_) async {
        retryCount++;
        if (retryCount == 1) throw StateError('transient');

        return _ViewData();
      });
      final container = ProviderContainer(
        overrides: [
          chatMessagesProvider(
            'ws',
            'chat',
          ).overrideWith((ref) => stream.stream),
          chatMessagesProvider(
            'other',
            'chat',
          ).overrideWith((ref) => const Stream.empty()),
          workspaceViewUsecaseProvider('ws').overrideWith((ref) async => views),
          workspaceTableUsecaseProvider('ws')
              .overrideWith((ref) async => tables),
          workspaceTablesProvider('ws', null).overrideWith((ref) async {
            directoryLoads++;

            return [];
          }),
          workspaceRecordQueryUsecaseProvider('ws').overrideWith((ref) async {
            queryLoads++;

            return _Queries();
          }),
        ],
      );
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: EasyLocalization(
              child: Builder(
                builder: (context) => MaterialApp(
                  home: Scaffold(
                    body: ValueListenableBuilder<String>(
                      valueListenable: workspace,
                      builder: (_, id, _) => WorkspaceViewToolObserver(
                        workspaceId: id,
                        conversationId: 'chat',
                        child: const SizedBox(),
                      ),
                    ),
                  ),
                  locale: context.locale,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                ),
              ),
              supportedLocales: const [Locale('en')],
              path: 'assets/i18n',
              startLocale: const Locale('en'),
            ),
          ),
        );
      });
      final _ = await tester.pumpAndSettle();
      final querySubscription = container.listen(
        workspaceRecordQueryUsecaseProvider('ws'),
        (_, next) {
          final _ = next;
        },
      );
      addTearDown(querySubscription.close);
      await tester.pump();
      final provider = workspaceOpenViewProvider('ws', 'chat');
      final directoryProvider = workspaceTablesProvider('ws', null);
      final subscription = container.listen(provider, (_, next) {
        final _ = next;
      });
      addTearDown(subscription.close);
      final directorySubscription = container.listen(directoryProvider, (
        _,
        next,
      ) {
        final _ = next;
      });
      addTearDown(directorySubscription.close);
      final _ = await container.read(directoryProvider.future);
      expect(directoryLoads, 1);
      stream.add([
        _message([_call('old', 'allowed')]),
      ]);
      await tester.pump();
      expect(container.read(provider), isNull);
      stream.add([
        _message([
          _call('old', 'allowed'),
          _call('new', 'allowed', name: workspaceCreateViewToolName),
        ]),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(provider)?.id, 'allowed');
      verify(() => views.open('allowed')).called(1);
      container.read(provider.notifier).close();
      stream.add([
        _message([
          _call('old', 'allowed'),
          _call('new', 'allowed'),
          _call(
            'bad',
            'denied',
            action: 'saveView',
            name: workspaceSaveViewToolName,
          ),
        ]),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(provider), isNull);
      verify(() => views.open('denied')).called(1);
      expect(find.byType(SnackBarAction), findsNothing);
      final never = verifyNever(() => views.open('allowed'));
      expect(never, isNotNull);
      stream.add([
        _message([_call('retry-call', 'retry')]),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(provider), isNull);
      expect(retryCount, 1);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SnackBarAction), findsOneWidget);
      await tester.tap(find.byType(SnackBarAction));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(provider)?.id, 'retry');
      expect(retryCount, 2);
      for (final action in [
        'createTable',
        'renameTable',
        'saveColumn',
        'createRecord',
        'updateRecord',
      ]) {
        final record = action == 'createRecord' || action == 'updateRecord';
        final call = _call('table-$action', 'unused', action: action).copyWith(
          responseRaw: jsonEncode(
            record
                ? {'kind': 'record', 'id': 'row', 'tableId': 'table'}
                : {'kind': 'table', 'id': 'table'},
          ),
        );
        stream.add([
          _message([call]),
        ]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        if (action == 'createTable') {
          final _ = await container.read(directoryProvider.future);
          expect(directoryLoads, 2);
        }
        expect(container.read(provider)?.id, 'table');
        expect(container.read(provider)?.kind, 'table');
        container.read(provider.notifier).close();
      }
      verify(() => tables.table('table')).called(5);

      final schemaEdit = _call(
        'schema-edit-after-close',
        'unused',
        name: workspaceSaveColumnToolName,
      ).copyWith(responseRaw: jsonEncode({'kind': 'table', 'id': 'table'}));
      stream.add([
        _message([schemaEdit]),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(provider)?.id, 'table');
      expect(container.read(provider)?.kind, 'table');
      verify(() => tables.table('table')).called(1);
      container.read(provider.notifier).close();

      // A repeated update for the same tool call must not reopen a tab the
      // user has closed. A later successful edit has a new call ID and does.
      stream.add([
        _message([schemaEdit]),
      ]);
      await tester.pump();
      expect(container.read(provider), isNull);
      final contentEdit =
          _call(
            'content-edit-after-close',
            'unused',
            name: workspaceUpdateRecordToolName,
          ).copyWith(
            responseRaw: jsonEncode({
              'kind': 'record',
              'id': 'row',
              'tableId': 'table',
            }),
          );
      stream.add([
        _message([contentEdit]),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(provider)?.id, 'table');
      expect(container.read(provider)?.kind, 'table');
      verify(() => tables.table('table')).called(1);
      container.read(provider.notifier).close();
      stream.add([
        _message([contentEdit]),
      ]);
      await tester.pump();
      expect(container.read(provider), isNull);

      expect(queryLoads, greaterThan(1));
      final cloud = _call('cloud', 'unused', name: workspaceAddRowToolName)
          .copyWith(
            argumentsRaw: '{}',
            responseRaw: jsonEncode({
              'kind': 'record',
              'id': 'row',
              'tableId': 'table',
            }),
          );
      stream.add([
        _message([cloud]),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(provider)?.id, 'table');
      container.read(provider.notifier).close();
      verify(() => tables.table('table')).called(1);
      final denied = _call('denied-table-call', 'unused', action: 'createTable')
          .copyWith(
            responseRaw: jsonEncode({'kind': 'table', 'id': 'denied-table'}),
          );
      final failed = _call('failed-table-call', 'unused', action: 'createTable')
          .copyWith(
            responseRaw: jsonEncode({'kind': 'table', 'id': 'table'}),
            resultStatus: .executionError,
          );
      stream.add([
        _message([denied, failed]),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(provider), isNull);
      verify(() => tables.table('denied-table')).called(1);
      final _ = verifyNever(() => tables.table('table'));
      stream.add([
        _message([_call('stale-call', 'stale')]),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SnackBarAction), findsOneWidget);
      workspace.value = 'other';
      await tester.pump();
      await tester.tap(find.byType(SnackBarAction));
      await tester.pump();
      verify(() => views.open('stale')).called(1);
    },
  );
  testWidgets('folder creation refreshes its parent without opening a tab', (
    tester,
  ) async {
    final stream = StreamController<List<MessageEntity>>();
    addTearDown(stream.close);
    var rootLoads = 0;
    var nestedLoads = 0;
    final container = ProviderContainer(
      overrides: [
        chatMessagesProvider('ws', 'chat').overrideWith((ref) => stream.stream),
        workspaceFoldersProvider('ws', null).overrideWith((ref) async {
          rootLoads++;

          return [];
        }),
        workspaceFoldersProvider('ws', 'parent').overrideWith((ref) async {
          nestedLoads++;

          return [];
        }),
      ],
    );
    addTearDown(container.dispose);
    final root = workspaceFoldersProvider('ws', null);
    final nested = workspaceFoldersProvider('ws', 'parent');
    final rootSubscription = container.listen(root, (_, next) {
      final _ = next;
    });
    final nestedSubscription = container.listen(nested, (_, next) {
      final _ = next;
    });
    addTearDown(rootSubscription.close);
    addTearDown(nestedSubscription.close);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: WorkspaceViewToolObserver(
            workspaceId: 'ws',
            conversationId: 'chat',
            child: SizedBox(),
          ),
        ),
      ),
    );
    final _ = await container.read(root.future);
    final _ = await container.read(nested.future);
    stream.add([_message([])]);
    await tester.pump();
    MessageToolCallEntity folder(String id, String? parent) =>
        MessageToolCallEntity(
          id: id,
          name: workspaceCreateFolderToolName,
          argumentsRaw: jsonEncode({'parentId': parent, 'name': 'New'}),
          responseRaw: jsonEncode({'id': id, 'kind': 'folder'}),
          resultStatus: .success,
        );
    stream.add([
      _message([folder('root-folder', null)]),
    ]);
    await tester.pump();
    final _ = await container.read(root.future);
    expect(rootLoads, 2);
    expect(nestedLoads, 1);
    expect(container.read(workspaceOpenViewProvider('ws', 'chat')), isNull);
    stream.add([
      _message([folder('nested-folder', 'parent')]),
    ]);
    await tester.pump();
    final _ = await container.read(nested.future);
    expect(rootLoads, 2);
    expect(nestedLoads, 2);
    expect(container.read(workspaceOpenViewProvider('ws', 'chat')), isNull);
    stream.add([
      _message([
        folder('failed-folder', null).copyWith(resultStatus: .executionError),
      ]),
    ]);
    await tester.pump();
    expect(rootLoads, 2);
    expect(nestedLoads, 2);
    expect(container.read(workspaceOpenViewProvider('ws', 'chat')), isNull);
    final renamed = folder('renamed', 'parent').copyWith(
      name: workspaceRenameFolderToolName,
      responseRaw: jsonEncode({
        'id': 'nested-folder',
        'kind': 'folder',
        'parentId': 'parent',
      }),
    );
    stream.add([
      _message([renamed]),
    ]);
    await tester.pump();
    final _ = await container.read(nested.future);
    expect(nestedLoads, 3);
    stream.add([
      _message([
        renamed.copyWith(
          id: 'unknown-parent',
          responseRaw: jsonEncode({'id': 'nested-folder', 'kind': 'folder'}),
        ),
      ]),
    ]);
    await tester.pump();
    final _ = await container.read(root.future);
    final _ = await container.read(nested.future);
    expect(rootLoads, 3);
    expect(nestedLoads, 4);
    expect(container.read(workspaceOpenViewProvider('ws', 'chat')), isNull);
  });
  testWidgets('table and view edits refresh their actual parent directory', (
    tester,
  ) async {
    final stream = StreamController<List<MessageEntity>>();
    addTearDown(stream.close);
    final tables = _Tables();
    final table = _Table();
    when(() => table.parentId).thenReturn('parent');
    when(() => tables.table('table')).thenAnswer((_) async => table);
    final views = _Views();
    when(() => views.open('view')).thenAnswer(
      (_) async => _ViewData(.connectedDraft(name: 'View', parentId: 'parent')),
    );
    var tablesLoaded = 0;
    var viewsLoaded = 0;
    final container = ProviderContainer(
      overrides: [
        chatMessagesProvider('ws', 'chat').overrideWith((ref) => stream.stream),
        workspaceTableUsecaseProvider('ws').overrideWith((ref) async => tables),
        workspaceViewUsecaseProvider('ws').overrideWith((ref) async => views),
        workspaceTablesProvider('ws', 'parent').overrideWith((ref) async {
          tablesLoaded++;

          return [];
        }),
        workspaceViewsProvider('ws', 'parent').overrideWith((ref) async {
          viewsLoaded++;

          return [];
        }),
      ],
    );
    addTearDown(container.dispose);
    final tableProvider = workspaceTablesProvider('ws', 'parent');
    final viewProvider = workspaceViewsProvider('ws', 'parent');
    final openProvider = workspaceOpenViewProvider('ws', 'chat');
    final openSubscription = container.listen(openProvider, (_, next) {
      final _ = next;
    });
    addTearDown(openSubscription.close);
    final tableSubscription = container.listen(tableProvider, (_, next) {
      final _ = next;
    });
    final viewSubscription = container.listen(viewProvider, (_, next) {
      final _ = next;
    });
    addTearDown(tableSubscription.close);
    addTearDown(viewSubscription.close);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: WorkspaceViewToolObserver(
            workspaceId: 'ws',
            conversationId: 'chat',
            child: SizedBox(),
          ),
        ),
      ),
    );
    final _ = await container.read(tableProvider.future);
    final _ = await container.read(viewProvider.future);
    stream.add([_message([])]);
    await tester.pump();
    final rename = _call(
      'rename',
      'unused',
      action: 'renameTable',
    ).copyWith(responseRaw: jsonEncode({'kind': 'table', 'id': 'table'}));
    stream.add([
      _message([rename]),
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final _ = await container.read(tableProvider.future);
    expect(tablesLoaded, 2);
    expect(viewsLoaded, 1);
    for (final action in ['createView', 'saveView']) {
      stream.add([
        _message([_call(action, 'view', action: action)]),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final _ = await container.read(viewProvider.future);
    }
    expect(viewsLoaded, 3);
    stream.add([
      _message([rename.copyWith(id: 'failed', resultStatus: .executionError)]),
    ]);
    await tester.pump();
    expect(tablesLoaded, 2);
    expect(viewsLoaded, 3);

    final delayedTable = Completer<WorkspaceTable>();
    when(() => tables.table('slow')).thenAnswer((_) => delayedTable.future);
    final slowRename = rename.copyWith(
      id: 'slow-rename',
      responseRaw: jsonEncode({'kind': 'table', 'id': 'slow'}),
    );
    stream.add([
      _message([slowRename]),
    ]);
    await tester.pump();
    stream.add([
      _message([_call('latest-view', 'view')]),
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(workspaceOpenViewProvider('ws', 'chat'))?.id, 'view');
    delayedTable.complete(table);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final _ = await container.read(tableProvider.future);
    expect(tablesLoaded, 3);
    expect(container.read(workspaceOpenViewProvider('ws', 'chat'))?.id, 'view');
  });
  for (final kind in ['table', 'view']) {
    for (final boundary in ['provider', 'item']) {
      for (final changed in ['workspace', 'conversation']) {
        for (final fails in [false, true]) {
          testWidgets(
            '$kind $boundary stops after $changed changes (fails: $fails)',
            (tester) async {
              final stream = StreamController<List<MessageEntity>>();
              addTearDown(stream.close);
              final ids = ValueNotifier((
                workspace: 'ws',
                conversation: 'chat',
              ));
              addTearDown(ids.dispose);
              final tables = _Tables();
              final views = _Views();
              final table = _Table();
              when(() => table.parentId).thenReturn(null);
              final tableProvider = Completer<OrganizeWorkspaceTablesUsecase>();
              final viewProvider = Completer<ManageWorkspaceViewsUsecase>();
              final tableResult = Completer<WorkspaceTable>();
              final viewResult = Completer<WorkspaceViewData>();
              when(() => tables.table('target'))
                  .thenAnswer((_) => tableResult.future);
              when(() => views.open('target'))
                  .thenAnswer((_) => viewResult.future);
              final container = ProviderContainer(
                overrides: [
                  chatMessagesProvider(
                    'ws',
                    'chat',
                  ).overrideWith((ref) => stream.stream),
                  chatMessagesProvider(
                    'other',
                    'chat',
                  ).overrideWith((ref) => const Stream.empty()),
                  chatMessagesProvider(
                    'ws',
                    'other',
                  ).overrideWith((ref) => const Stream.empty()),
                  workspaceTableUsecaseProvider('ws')
                      .overrideWith((ref) => tableProvider.future),
                  workspaceViewUsecaseProvider('ws')
                      .overrideWith((ref) => viewProvider.future),
                ],
              );
              addTearDown(container.dispose);
              if (boundary == 'item') {
                tableProvider.complete(tables);
                viewProvider.complete(views);
              }
              await tester.pumpWidget(
                UncontrolledProviderScope(
                  container: container,
                  child: MaterialApp(
                    home: ValueListenableBuilder(
                      valueListenable: ids,
                      builder: (_, value, _) => WorkspaceViewToolObserver(
                        workspaceId: value.workspace,
                        conversationId: value.conversation,
                        child: const SizedBox(),
                      ),
                    ),
                  ),
                ),
              );
              stream.add([_message([])]);
              await tester.pump();
              final call = kind == 'table'
                  ? _call('call', 'target', action: 'renameTable').copyWith(
                      responseRaw: jsonEncode({
                        'kind': 'table',
                        'id': 'target',
                      }),
                    )
                  : _call('call', 'target');
              stream.add([
                _message([call]),
              ]);
              await tester.pump();
              if (boundary == 'item') {
                if (kind == 'table') {
                  verify(() => tables.table('target')).called(1);
                } else {
                  verify(() => views.open('target')).called(1);
                }
              }
              ids.value = changed == 'workspace'
                  ? (workspace: 'other', conversation: 'chat')
                  : (workspace: 'ws', conversation: 'other');
              await tester.pump();
              if (boundary == 'provider') {
                if (fails && kind == 'table') {
                  tableProvider.completeError(StateError('late failure'));
                } else {
                  tableProvider.complete(tables);
                }
                if (fails && kind == 'view') {
                  viewProvider.completeError(StateError('late failure'));
                } else {
                  viewProvider.complete(views);
                }
              } else {
                if (fails && kind == 'table') {
                  tableResult.completeError(StateError('late failure'));
                } else {
                  tableResult.complete(table);
                }
                if (fails && kind == 'view') {
                  viewResult.completeError(StateError('late failure'));
                } else {
                  viewResult.complete(_ViewData());
                }
              }
              await tester.pump();
              await tester.pump();
              expect(
                container.read(workspaceOpenViewProvider('ws', 'chat')),
                isNull,
              );
              if (boundary == 'provider') {
                final _ = verifyNever(() => tables.table(any()));
                final _ = verifyNever(() => views.open(any()));
              }
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
