import 'package:auravibes_app/features/chats/services/cloud_chat_attachment_adapter.dart';
import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/chats/usecases/cloud_chat_attachment_usecase.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([workspaceSession, cloudWorkspaceStateGateway])
final FutureProvider<CloudChatAttachmentUsecase?>
cloudChatAttachmentUsecaseProvider =
    FutureProvider.autoDispose<CloudChatAttachmentUsecase?>(
      (ref) async {
        if (ref.watch(workspaceSessionProvider).cloud == null) return null;
        final gateway = await ref.watch(
          cloudWorkspaceStateGatewayProvider.future,
        );
        if (gateway == null) return null;

        return CloudChatAttachmentAdapter(
          gateway: CloudChatGateway(gateway),
        ).createUsecase();
      },
      dependencies: [
        workspaceSessionProvider,
        cloudWorkspaceStateGatewayProvider,
      ],
    );
