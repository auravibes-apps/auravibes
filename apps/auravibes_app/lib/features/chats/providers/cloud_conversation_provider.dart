import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_conversation_provider.g.dart';

@Riverpod(dependencies: [workspaceSession, cloudWorkspaceStateGateway])
Future<CloudConversationUsecase?> cloudConversationUsecase(Ref ref) async {
  if (ref.watch(workspaceSessionProvider).cloud == null) return null;
  final gateway = await ref.watch(cloudWorkspaceStateGatewayProvider.future);

  return gateway == null
      ? null
      : CloudConversationUsecase(CloudChatGateway(gateway));
}
