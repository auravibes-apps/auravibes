import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/services/marionette/marionette_development_state.dart';

abstract final class MarionetteDemoModelIdentity {
  static bool isDemoConnection(
    String workspaceId,
    ModelConnectionEntity connection,
  ) =>
      workspaceId == MarionetteDevelopmentState.demoWorkspaceId &&
      connection.workspaceId == MarionetteDevelopmentState.demoWorkspaceId &&
      connection.id == MarionetteDevelopmentState.demoConnectionId &&
      connection.modelId == MarionetteDevelopmentState.demoServiceId;

  static bool matchesDemoModelSelection(
    String workspaceId,
    String selectionId,
    WorkspaceModelSelectionWithConnectionEntity? selection,
  ) {
    if (selection == null ||
        workspaceId != MarionetteDevelopmentState.demoWorkspaceId) {
      return false;
    }

    return _matchesDemoSelectionIds(selectionId, selection) &&
        isDemoConnection(workspaceId, selection.modelConnection);
  }

  static bool _matchesDemoSelectionIds(
    String selectionId,
    WorkspaceModelSelectionWithConnectionEntity selection,
  ) =>
      selectionId == MarionetteDevelopmentState.demoModelSelectionId &&
      selection.workspaceModelSelection.id ==
          MarionetteDevelopmentState.demoModelSelectionId &&
      selection.workspaceModelSelection.modelId ==
          MarionetteDevelopmentState.demoModelId &&
      selection.workspaceModelSelection.modelConnectionId ==
          MarionetteDevelopmentState.demoConnectionId;
}
