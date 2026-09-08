import 'package:auravibes_app/features/chats/providers/cloud_chat_gateway_provider.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_conversation_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_conversation_provider.g.dart';

extension CloudConversationProvider on CloudConversationUsecaseFamily {
  Override overrideWithValue(CloudConversationUsecase? value) =>
      overrideWith((_, _) => value);
}

@riverpod
Future<CloudConversationUsecase?> cloudConversationUsecase(
  Ref ref,
  String workspaceId,
) async {
  final gateway = await cloudChatGatewayForWorkspace(ref, workspaceId);

  return gateway == null ? null : CloudConversationUsecase(gateway);
}
