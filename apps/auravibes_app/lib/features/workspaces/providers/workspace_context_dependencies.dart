import 'package:auravibes_app/data/repositories/cloud_workspace_context_repository.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_context_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_conversation_context.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_conversation_tools_provider.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_chat_context_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class const WorkspaceContextDependencies(
  final Ref ref,
  final String workspaceId,
) {
  Future<ManageWorkspaceChatContextUsecase> load() async {
    final sessionFuture = ref.watch(
      workspaceSessionForRouteProvider(workspaceId).future,
    );
    final commandFuture = ref.watch(
      workspaceConversationCommandUsecaseProvider(workspaceId).future,
    );
    final session = await sessionFuture;
    final commands = await commandFuture;
    final repository = await _repository(session);

    return _manager(session, repository, commands);
  }

  Future<WorkspaceConversationContextRepository> _repository(
    WorkspaceSession session,
  ) async {
    _mounted();
    final cloud = session.cloud;
    if (cloud != null) {
      return await _cloudRepository(session, cloud.cloudWorkspaceId);
    }

    return LocalWorkspaceContextRepository(
      ref.watch(appDatabaseProvider),
      workspaceId,
    );
  }

  Future<WorkspaceConversationContextRepository> _cloudRepository(
    WorkspaceSession session,
    int cloudWorkspaceId,
  ) async {
    final gateway = await ref.watch(
      cloudWorkspaceStateGatewayProvider(session).future,
    );
    _mounted();
    if (gateway == null) throw const WorkspaceTableException(denied: true);

    return CloudWorkspaceContextRepository(gateway.client, cloudWorkspaceId);
  }

  ManageWorkspaceChatContextUsecase _manager(
    WorkspaceSession session,
    WorkspaceConversationContextRepository repository,
    WorkspaceConversationCommandUsecase commands,
  ) {
    _mounted();

    return ManageWorkspaceChatContextUsecase(
      workspaceId: session.cloud?.cloudWorkspaceId.toString() ?? workspaceId,
      repository: repository,
      commands: commands,
      canAccess: _access(session),
    );
  }

  Future<bool> Function(String) _access(WorkspaceSession session) {
    if (session.cloud != null) return (_) => Future.value(true);
    final conversations = ref.watch(conversationRepositoryProvider);

    return (id) => _localAccess(conversations, id);
  }

  Future<bool> _localAccess(
    ConversationRepository conversations,
    String id,
  ) async =>
      (await conversations.getConversationById(id))?.workspaceId == workspaceId;

  void _mounted() {
    if (!ref.mounted) throw const WorkspaceTableException(denied: true);
  }
}
