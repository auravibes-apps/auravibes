import 'package:auravibes_app/features/chats/providers/cloud_chat_gateway_provider.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_turn_provider.g.dart';

@riverpod
Future<CloudTurnUsecase?> cloudTurnUsecase(Ref ref, String workspaceId) async {
  final gateway = await cloudChatGatewayForWorkspace(ref, workspaceId);

  return gateway == null ? null : CloudTurnUsecase(gateway);
}
