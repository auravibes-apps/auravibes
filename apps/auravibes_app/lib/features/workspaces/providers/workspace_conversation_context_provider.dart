import 'package:auravibes_app/features/workspaces/models/workspace_conversation_context.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_context_dependencies.dart';
import 'package:auravibes_app/features/workspaces/usecases/manage_workspace_chat_context_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_conversation_context_provider.g.dart';

@riverpod
Future<ManageWorkspaceChatContextUsecase> workspaceConversationContextUsecase(
  Ref ref,
  String workspaceId,
) async {
  final link = ref.keepAlive();
  try {
    return await WorkspaceContextDependencies(ref, workspaceId).load();
  } finally {
    link.close();
  }
}

@riverpod
Future<WorkspaceConversationContext> workspaceConversationContext(
  Ref ref,
  String workspaceId,
  String conversationId,
) async => await (await ref.watch(
  workspaceConversationContextUsecaseProvider(workspaceId).future,
)).read(conversationId);
