import 'package:auravibes_app/data/repositories/local_workspace_context_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_command_dependencies.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_conversation_tools_provider.g.dart';

@riverpod
WorkspaceConversationToolsUsecase workspaceConversationTools(Ref ref) {
  final database = ref.watch(appDatabaseProvider);

  return WorkspaceConversationToolsUsecase(
    conversations: ref.watch(conversationRepositoryProvider),
    context: (id) => LocalWorkspaceContextRepository(database, id),
    commands: (id) =>
        ref.read(workspaceConversationCommandUsecaseProvider(id).future),
    receipts: .new(database),
  );
}

@riverpod
Future<WorkspaceConversationCommandUsecase> workspaceConversationCommandUsecase(
  Ref ref,
  String workspaceId,
) => WorkspaceCommandDependencies(ref, workspaceId).load();
