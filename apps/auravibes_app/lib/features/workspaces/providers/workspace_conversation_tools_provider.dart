import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_conversation_tools_provider.g.dart';

@riverpod
WorkspaceConversationToolsUsecase workspaceConversationTools(
  Ref ref,
) => WorkspaceConversationToolsUsecase(
  conversations: ref.watch(conversationRepositoryProvider),
  messages: ref.watch(messageRepositoryProvider),
  commands: (workspaceId) async => WorkspaceConversationCommandUsecase(
    tables: await ref.read(workspaceTableUsecaseProvider(workspaceId).future),
    folders: await ref.read(workspaceFolderUsecaseProvider(workspaceId).future),
    views: await ref.read(workspaceViewUsecaseProvider(workspaceId).future),
  ),
);
