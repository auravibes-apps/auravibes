import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/features/chats/notifiers/new_chat_state.dart';
import 'package:auravibes_app/features/chats/widgets/chat_readiness_summary.dart';
import 'package:auravibes_app/features/models/providers/chat_model_connections_provider.dart';
import 'package:auravibes_app/features/models/providers/workspace_model_selections_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  final scenarios = [
    (
      connections: <ModelConnectionEntity>[],
      models: false,
      selected: null,
      text: 'Connect an AI provider to start chatting.',
    ),
    (
      connections: [_connection(false)],
      models: false,
      selected: null,
      text:
          'Connection saved. Authorization needs attention. '
          'Complete sign-in in Connections, then retry.',
    ),
    (
      connections: [_connection(true)],
      models: false,
      selected: null,
      text:
          'Connection saved, but no models are available. '
          'Review the connection and refresh its models.',
    ),
    (
      connections: [_connection(true)],
      models: true,
      selected: null,
      text: 'Models are available. Choose a model to start chatting.',
    ),
    (
      connections: [_connection(true)],
      models: true,
      selected: 'missing',
      text: 'The selected model is unavailable. Choose another model.',
    ),
    (
      connections: [_connection(true)],
      models: true,
      selected: 'model',
      text: 'Model selected. Remote access is checked when you send a message.',
    ),
  ];
  testWidgets('summarizes all chat readiness states', (tester) async {
    for (var index = 0; index < scenarios.length; index++) {
      final scenario = scenarios[index];
      await tester.runAsync(
        () => tester.pumpWidget(
          TestableApp(
            child: const Scaffold(
              body: ChatReadinessSummary(workspaceId: 'ws'),
            ),
            overrides: [
              chatModelConnectionsProvider('ws')
                  .overrideWith((ref) => Stream.value(scenario.connections)),
              listModelsGroupedByProviderProvider(workspaceId: 'ws')
                  .overrideWith(
                    (ref) => Stream.value(
                      scenario.models
                          ? {
                              'connection': [_model()],
                            }
                          : {},
                    ),
                  ),
              newChatProvider('ws')
                  .overrideWithValue(.new(modelId: scenario.selected)),
            ],
            key: ValueKey<int>(index),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(find.text(scenario.text), findsOneWidget, reason: scenario.text);
      expect(find.text('Ready to chat'), findsNothing, reason: scenario.text);
    }
  });
  testWidgets('catalog failure offers retry without claiming access', (
    tester,
  ) async {
    var attempts = 0;
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: const Scaffold(body: ChatReadinessSummary(workspaceId: 'ws')),
          overrides: [
            chatModelConnectionsProvider('ws')
                .overrideWith((ref) => Stream.value([_connection(true)])),
            listModelsGroupedByProviderProvider(workspaceId: 'ws')
                .overrideWith((ref) {
                  attempts++;

                  return attempts == 1
                      ? Stream.error(StateError('unavailable'))
                      : Stream.value({
                          'connection': [_model()],
                        });
                }),
          ],
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();
    expect(
      find.text(
        'Could not load AI configuration. Check the connection or retry.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    final _ = await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(
      find.text('Models are available. Choose a model to start chatting.'),
      findsOneWidget,
    );
  });
}

ModelConnectionEntity _connection(bool authorized) => ModelConnectionEntity(
  id: 'connection',
  name: 'Provider',
  modelId: 'openai',
  createdAt: .new(2026),
  updatedAt: .new(2026),
  workspaceId: 'ws',
  hasKey: authorized,
  authMode: .oauth2,
);
WorkspaceModelSelectionWithConnectionEntity _model() =>
    WorkspaceModelSelectionWithConnectionEntity(
      workspaceModelSelection: .new(
        id: 'model',
        modelId: 'test',
        modelConnectionId: 'connection',
        createdAt: .new(2026),
        updatedAt: .new(2026),
      ),
      modelConnection: _connection(true),
      modelsProvider: const .new(id: 'openai', name: 'OpenAI', type: .openai),
    );
