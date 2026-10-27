import 'dart:async';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_conversation_context_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_conversation_tools_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('one-shot context read survives async dependency resolution', () async {
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
    final chat = await conversations.createConversation(
      const .new(title: 'Test', workspaceId: 'one'),
    );
    final session = Completer<WorkspaceSession>();
    final container = ProviderContainer(
      overrides: [
        workspaceSessionForRouteProvider.overrideWith((_, _) => session.future),
        workspaceConversationCommandUsecaseProvider.overrideWith(
          (_, _) async => WorkspaceConversationCommandUsecase(
            tables: .new(
              LocalWorkspaceTableRepository(database, 'one'),
            ),
          ),
        ),
        appDatabaseProvider.overrideWith((_) => database),
        conversationRepositoryProvider.overrideWith((_) => conversations),
      ],
    );
    addTearDown(container.dispose);
    final pending = container.read(
      workspaceConversationContextUsecaseProvider('one').future,
    );
    await container.pump();
    session.complete(
      const WorkspaceSession(LocalWorkspaceRef(localWorkspaceId: 'one')),
    );
    final manager = await pending;
    final selection = WorkspaceContextSelection(
      workspaceId: 'one',
      conversationId: chat.id,
      itemId: '',
      kind: 'directory',
    );
    final _ = await manager.save(chat.id, 'share-root', selection);
    expect((await manager.read(chat.id)).selection?.kind, 'directory');
  });
}
