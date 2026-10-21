import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/providers/chatbot_service_provider.dart';
import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selection_providers.dart';
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/services/marionette/marionette_chat_smoke_fixture.dart';
import 'package:auravibes_app/services/marionette/marionette_chat_smoke_service.dart';
import 'package:auravibes_app/services/marionette/marionette_demo_model_identity.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:riverpod/misc.dart';

abstract final class MarionetteChatSmokeProviderOverrides {
  static Override get _chatModelConnectionsOverride =>
      chatModelConnectionsProvider.overrideWith(
        (ref, workspaceId) => chatModelConnections(
          ref,
          workspaceId,
        ).map((connections) => readyConnections(workspaceId, connections)),
      );

  static Override get _workspaceModelSelectionOverride =>
      workspaceModelSelectionByIdProvider.overrideWith((ref, arguments) async {
        final (workspaceId, selectionId) = arguments;
        final selection = await workspaceModelSelectionById(
          ref,
          workspaceId,
          selectionId,
        );

        return readySelection(workspaceId, selectionId, selection);
      });

  static List<Override> create(MarionetteChatSmokeFixture fixture) => [
    _chatbotServiceOverride(fixture),
    _chatModelConnectionsOverride,
    _workspaceModelSelectionOverride,
  ];

  static List<ModelConnectionEntity> readyConnections(
    String workspaceId,
    List<ModelConnectionEntity> connections,
  ) => [
    for (final connection in connections)
      if (MarionetteDemoModelIdentity.isDemoConnection(workspaceId, connection))
        connection.copyWith(hasKey: true)
      else
        connection,
  ];

  static WorkspaceModelSelectionWithConnectionEntity? readySelection(
    String workspaceId,
    String selectionId,
    WorkspaceModelSelectionWithConnectionEntity? selection,
  ) {
    if (selection == null) return null;

    if (!MarionetteDemoModelIdentity.matchesDemoModelSelection(
      workspaceId,
      selectionId,
      selection,
    )) {
      return selection;
    }

    return selection.copyWith(
      modelConnection: selection.modelConnection.copyWith(hasKey: true),
    );
  }

  static Override _chatbotServiceOverride(MarionetteChatSmokeFixture fixture) =>
      chatbotServiceProvider.overrideWith(
        (ref) => MarionetteChatSmokeService(
          serviceConnectionRepository: ref.watch(
            serviceConnectionRepositoryProvider,
          ),
          fixture: fixture,
          oauthCredentialService: ref.watch(oauthCredentialServiceProvider),
        ),
      );
}
