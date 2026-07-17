import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_turn_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([workspaceSession, cloudWorkspaceStateGateway])
final FutureProvider<CloudTurnUsecase?> cloudTurnUsecaseProvider =
    FutureProvider.autoDispose<CloudTurnUsecase?>(
      (ref) async {
        if (ref.watch(workspaceSessionProvider).cloud == null) return null;
        final gateway = await ref.watch(
          cloudWorkspaceStateGatewayProvider.future,
        );

        return gateway == null
            ? null
            : CloudTurnUsecase(CloudChatGateway(gateway));
      },
      dependencies: [
        workspaceSessionProvider,
        cloudWorkspaceStateGatewayProvider,
      ],
    );
