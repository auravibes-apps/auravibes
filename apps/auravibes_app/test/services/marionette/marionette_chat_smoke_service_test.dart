import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/services/chatbot/chatbot_service.dart';
import 'package:auravibes_app/services/marionette/marionette_chat_smoke_fixture.dart';
import 'package:auravibes_app/services/marionette/marionette_chat_smoke_service.dart';
import 'package:auravibes_app/services/marionette/marionette_development_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ServiceConnectionRepository extends Mock
    implements ServiceConnectionRepository;

class _WorkspaceModelSelection extends Mock
    implements WorkspaceModelSelectionEntity;

class _ModelConnection extends Mock implements ModelConnectionEntity;

class _ModelSelectionWithConnection extends Mock
    implements WorkspaceModelSelectionWithConnectionEntity;

void main() {
  test('serves the demo model through the fixture response stream', () async {
    final fixture = MarionetteChatSmokeFixture();
    final service = _service(fixture);

    final response = await service.sendMessage(_demoModel(), const []).toList();

    expect(response.single.output.text, 'Marionette demo response.');
  });

  test('uses a local fallback title for the demo model', () async {
    final service = _service(.new());

    expect(
      await service.streamTitle(_demoModel(), 'Marionette smoke prompt').last,
      ChatbotService.generateFallbackTitle('Marionette smoke prompt'),
    );
  });
}

MarionetteChatSmokeService _service(MarionetteChatSmokeFixture fixture) =>
    MarionetteChatSmokeService(
      serviceConnectionRepository: _ServiceConnectionRepository(),
      fixture: fixture,
    );

_ModelSelectionWithConnection _demoModel() {
  final selection = _WorkspaceModelSelection();
  when(() => selection.id)
      .thenReturn(MarionetteDevelopmentState.demoModelSelectionId);
  when(() => selection.modelId)
      .thenReturn(MarionetteDevelopmentState.demoModelId);
  when(() => selection.modelConnectionId)
      .thenReturn(MarionetteDevelopmentState.demoConnectionId);
  final connection = _ModelConnection();
  when(() => connection.id)
      .thenReturn(MarionetteDevelopmentState.demoConnectionId);
  when(() => connection.modelId)
      .thenReturn(MarionetteDevelopmentState.demoServiceId);
  when(() => connection.workspaceId)
      .thenReturn(MarionetteDevelopmentState.demoWorkspaceId);
  final model = _ModelSelectionWithConnection();
  when(() => model.workspaceModelSelection).thenReturn(selection);
  when(() => model.modelConnection).thenReturn(connection);

  return model;
}
