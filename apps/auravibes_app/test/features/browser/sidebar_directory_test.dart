import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_context_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_folder_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_conversation_context_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_chat_context_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_folders_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/organize_workspace_tables_usecase.dart';
import 'package:drift/native.dart';
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
    'sharing the current directory requires consent and uses its path',
    (tester) async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('one'),
              name: 'One',
              type: .local,
            ),
          );
      final chat = await ConversationRepository(database)
          .createConversation(.new(title: 'Chat', workspaceId: 'one'));
      final folders = OrganizeWorkspaceFoldersUsecase(
        LocalWorkspaceFolderRepository(database, 'one'),
      );
      final folder = await folders.create(name: 'Folder');
      final tables = OrganizeWorkspaceTablesUsecase(
        LocalWorkspaceTableRepository(database, 'one'),
      );
      final repository = LocalWorkspaceContextRepository(database, 'one');
      final consent = ManageWorkspaceChatContextUsecase(
        workspaceId: 'one',
        repository: repository,
        commands: .new(tables: tables, folders: folders),
        canAccess: (id) async => id == chat.id,
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(
          TestableApp(
            workspaceId: 'one',
            child: SidebarDirectory(
              workspaceId: 'one',
              conversationId: chat.id,
              onClose: () {},
              onOpen: (_, _) {},
            ),
            overrides: [
              workspaceFoldersProvider.overrideWith(
                (ref, args) => folders.list(parentId: args.$2),
              ),
              workspaceTablesProvider.overrideWith((ref, args) async => []),
              workspaceViewsProvider.overrideWith((ref, args) async => []),
              workspaceFilesProvider.overrideWith((ref, args) async => []),
              workspaceConversationContextUsecaseProvider('one')
                  .overrideWith((ref) async => consent),
              sendMessageUsecaseProvider('one')
                  .overrideWithValue(SendMessageUsecase.cloud((_, _) async {})),
            ],
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pumpAndSettle();
      expect((await repository.read(chat.id)).selection, isNull);
      await tester.tap(find.text('Share with AI').first);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Allow AI to create folders and tables at the Directory root? Existing items and records are not shared. This replaces the current shared context.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect((await repository.read(chat.id)).selection, isNull);
      await tester.tap(find.text('Share with AI').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.widgetWithText(TextButton, 'Share with AI'),
        ),
      );
      await tester.pumpAndSettle();
      expect((await repository.read(chat.id)).selection?.kind, 'directory');
      await tester.tap(find.text('Folder'));
      await tester.pumpAndSettle();
      expect((await repository.read(chat.id)).selection?.kind, 'directory');
      await tester.tap(find.text('Share with AI').first);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Allow AI to read or rename this folder and create folders and tables inside it? Existing items and records are not shared. This replaces the current shared context.',
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.widgetWithText(TextButton, 'Share with AI'),
        ),
      );
      await tester.pumpAndSettle();
      final selection = (await repository.read(chat.id)).selection;
      expect(selection?.kind, 'folder');
      expect(selection?.itemId, folder.id);
      expect(selection?.parentId, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

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
              conversationId: 'chat',
              onClose: () {},
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
