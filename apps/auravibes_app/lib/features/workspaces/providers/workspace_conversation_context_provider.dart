import 'package:auravibes_app/data/repositories/cloud_workspace_context_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_context_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_conversation_context.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_folders_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_tables_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_views_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_conversation_context_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_conversation_context_provider.g.dart';

@riverpod
Future<ManageWorkspaceConversationContextUsecase>
workspaceConversationContextUsecase(Ref ref, String workspaceId) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  final commands = WorkspaceConversationCommandUsecase(
    tables: await ref.watch(workspaceTableUsecaseProvider(workspaceId).future),
    folders: await ref.watch(
      workspaceFolderUsecaseProvider(workspaceId).future,
    ),
    views: await ref.watch(workspaceViewUsecaseProvider(workspaceId).future),
  );
  if (!ref.mounted) throw const WorkspaceTableException(denied: true);
  final cloud = session.cloud;
  final WorkspaceConversationContextRepository repository;
  if (cloud == null) {
    repository = LocalWorkspaceContextRepository(
      ref.watch(appDatabaseProvider),
      workspaceId,
    );
  } else {
    final gateway = await ref.watch(
      cloudWorkspaceStateGatewayProvider(session).future,
    );
    if (!ref.mounted || gateway == null)
      throw const WorkspaceTableException(denied: true);
    repository = CloudWorkspaceContextRepository(
      gateway.client,
      cloud.cloudWorkspaceId,
    );
  }
  final conversations = ref.watch(conversationRepositoryProvider);
  return ManageWorkspaceConversationContextUsecase(
    workspaceId: cloud == null ? workspaceId : '${cloud.cloudWorkspaceId}',
    repository: repository,
    commands: commands,
    canAccess: (id) async =>
        cloud != null ||
        (await conversations.getConversationById(id))?.workspaceId ==
            workspaceId,
  );
}

@riverpod
Future<WorkspaceConversationContext> workspaceConversationContext(
  Ref ref,
  String workspaceId,
  String conversationId,
) async => (await ref.watch(
  workspaceConversationContextUsecaseProvider(workspaceId).future,
)).read(conversationId);
