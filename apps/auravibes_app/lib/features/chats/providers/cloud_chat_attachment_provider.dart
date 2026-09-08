import 'package:auravibes_app/features/chats/providers/cloud_chat_gateway_provider.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_attachment_adapter.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_chat_attachment_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_chat_attachment_provider.g.dart';

@riverpod
Future<CloudChatAttachmentUsecase?> cloudChatAttachmentUsecase(
  Ref ref,
  String workspaceId,
) async {
  final gateway = await cloudChatGatewayForWorkspace(ref, workspaceId);
  if (gateway == null) return null;

  return CloudChatAttachmentAdapter(gateway: gateway).createUsecase();
}
