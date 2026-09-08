import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_turn_provider.g.dart';

@riverpod
Future<CloudTurnUsecase?> cloudTurnUsecase(Ref ref, String workspaceId) async {
  final session = await ref.watch(
    workspaceSessionForRouteProvider(workspaceId).future,
  );
  if (session.cloud == null) return null;
  final gateway = await ref.watch(
    cloudWorkspaceStateGatewayProvider(session).future,
  );

  return gateway == null ? null : CloudTurnUsecase(CloudChatGateway(gateway));
}
