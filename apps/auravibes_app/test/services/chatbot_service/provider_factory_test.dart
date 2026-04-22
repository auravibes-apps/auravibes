import 'package:auravibes_app/domain/entities/api_model_provider.dart';
import 'package:auravibes_app/domain/entities/model_connection_entities.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entities.dart';
import 'package:auravibes_app/services/chatbot_service/provider_factory.dart';
import 'package:dartantic_ai/dartantic_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProviderFactory', () {
    const factory = ProviderFactory();

    WorkspaceModelSelectionWithConnectionEntity makeConfig({
      ModelProvidersType? type,
      String modelId = 'gpt-4o',
      String? connectionUrl,
      String? providerUrl,
    }) {
      return WorkspaceModelSelectionWithConnectionEntity(
        workspaceModelSelection: WorkspaceModelSelectionEntity(
          id: 'ws1',
          modelId: modelId,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          modelConnectionId: 'mc1',
        ),
        modelConnection: ModelConnectionEntity(
          id: 'mc1',
          name: 'Test',
          key: 'encrypted-key',
          modelId: modelId,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          workspaceId: 'w1',
          url: connectionUrl,
        ),
        modelsProvider: ApiModelProviderEntity(
          id: 'p1',
          name: 'TestProvider',
          type: type,
          url: providerUrl,
        ),
      );
    }

    test('creates ChatModel for openai provider', () {
      final config = makeConfig(type: ModelProvidersType.openai);
      final chatModel = factory(config, apiKey: 'sk-test');

      expect(chatModel, isA<ChatModel>());
      expect(chatModel.name, 'gpt-4o');
    });

    test('creates ChatModel for anthropic provider', () {
      final config = makeConfig(
        type: ModelProvidersType.anthropic,
        modelId: 'claude-sonnet-4-0',
      );
      final chatModel = factory(config, apiKey: 'sk-ant-test');

      expect(chatModel, isA<ChatModel>());
      expect(chatModel.name, 'claude-sonnet-4-0');
    });

    test('creates custom ChatModel when connection has custom baseUrl', () {
      final config = makeConfig(
        type: ModelProvidersType.openai,
        connectionUrl: 'https://custom.example.com/v1',
        providerUrl: 'https://api.openai.com/v1',
      );
      final chatModel = factory(config, apiKey: 'sk-test');

      expect(chatModel, isA<ChatModel>());
    });

    test('throws when type is null and no baseUrl', () {
      final config = makeConfig();

      expect(
        () => factory(config, apiKey: 'sk-test'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('creates custom ChatModel when type is null but baseUrl exists', () {
      final config = makeConfig(
        connectionUrl: 'https://custom.example.com/v1',
      );
      final chatModel = factory(config, apiKey: 'sk-test');

      expect(chatModel, isA<ChatModel>());
    });

    test('passes tools to ChatModel', () {
      final config = makeConfig(type: ModelProvidersType.openai);
      final tools = [
        Tool<Map<String, dynamic>>(
          name: 'test_tool',
          description: 'A test tool',
          onCall: (_) async => 'ok',
        ),
      ];

      final chatModel = factory(config, apiKey: 'sk-test', tools: tools);

      expect(chatModel, isA<ChatModel>());
    });
  });
}
