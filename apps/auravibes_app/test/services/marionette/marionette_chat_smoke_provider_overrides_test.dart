import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/services/marionette/marionette_chat_smoke_provider_overrides.dart';
import 'package:auravibes_app/services/marionette/marionette_development_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('marks only the seeded demo connection ready in its demo workspace', () {
    final updated = MarionetteChatSmokeProviderOverrides.readyConnections(
      MarionetteDevelopmentState.demoWorkspaceId,
      [_connection(), _connection(id: 'another-connection')],
    );

    expect(updated.map((connection) => connection.hasKey), [true, false]);
    expect(
      MarionetteChatSmokeProviderOverrides.readyConnections(
        'another-workspace',
        [_connection()],
      ).single.hasKey,
      isFalse,
    );
  });

  test('marks only the seeded demo model selection ready', () {
    final selection = _selection();
    final updated = MarionetteChatSmokeProviderOverrides.readySelection(
      MarionetteDevelopmentState.demoWorkspaceId,
      MarionetteDevelopmentState.demoModelSelectionId,
      selection,
    );

    expect(updated?.modelConnection.hasKey, isTrue);
    expect(selection.modelConnection.hasKey, isFalse);
    expect(
      MarionetteChatSmokeProviderOverrides.readySelection(
        'another-workspace',
        MarionetteDevelopmentState.demoModelSelectionId,
        selection,
      )?.modelConnection.hasKey,
      isFalse,
    );
    expect(
      MarionetteChatSmokeProviderOverrides.readySelection(
        MarionetteDevelopmentState.demoWorkspaceId,
        'another-selection',
        selection,
      )?.modelConnection.hasKey,
      isFalse,
    );
  });
}

ModelConnectionEntity _connection({String? id}) => ModelConnectionEntity(
  id: id ?? MarionetteDevelopmentState.demoConnectionId,
  name: 'Marionette Demo Provider',
  modelId: MarionetteDevelopmentState.demoServiceId,
  createdAt: .utc(2026),
  updatedAt: .utc(2026),
  workspaceId: MarionetteDevelopmentState.demoWorkspaceId,
  hasKey: false,
);

WorkspaceModelSelectionWithConnectionEntity _selection() {
  final modelConnection = _connection();
  final selection = WorkspaceModelSelectionEntity(
    id: MarionetteDevelopmentState.demoModelSelectionId,
    modelId: MarionetteDevelopmentState.demoModelId,
    createdAt: .utc(2026),
    updatedAt: .utc(2026),
    modelConnectionId: MarionetteDevelopmentState.demoConnectionId,
  );

  return WorkspaceModelSelectionWithConnectionEntity(
    workspaceModelSelection: selection,
    modelConnection: modelConnection,
    modelsProvider: const ApiModelProviderEntity(
      id: MarionetteDevelopmentState.demoServiceId,
      name: 'Marionette Demo Provider',
      type: null,
    ),
  );
}
