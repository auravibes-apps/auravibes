// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/domain/entities/model_providers_type.dart';
import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/domain/entities/workspace_model_selection_entity.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/chatbot_service/provider_factory.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:auravibes_app/services/secret_key_manager.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:collection/collection.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart' as genkit;

void main() {
  group('ChatbotService', () {
    test('can be constructed with required dependencies', () {
      expect(
        () => ChatbotService(
          encryptionService: _FakeEncryptionService(),
        ),
        returnsNormally,
      );
    });

    test('exposes injected encryption dependency', () {
      final encryption = _FakeEncryptionService();

      final service = ChatbotService(
        encryptionService: encryption,
      );

      expect(service.encryptionService, same(encryption));
    });

    test('accepts optional providerFactory', () {
      expect(
        () => ChatbotService(
          encryptionService: _FakeEncryptionService(),
        ),
        returnsNormally,
      );
    });

    test('streams chunks and final metadata from Genkit', () async {
      genkit.ModelRequest? capturedRequest;
      final providerFactory = _FakeProviderFactory(
        chunks: [
          genkit.ModelResponseChunk(
            role: genkit.Role.model,
            content: [
              genkit.TextPart(text: 'Hello'),
              genkit.ReasoningPart(reasoning: 'Thought'),
            ],
          ),
        ],
        response: genkit.ModelResponse(
          message: genkit.Message(
            role: genkit.Role.model,
            content: [
              genkit.ToolRequestPart(
                toolRequest: genkit.ToolRequest(
                  ref: 'tool-1',
                  name: 'lookup_weather',
                  input: const {'city': 'Medellin'},
                ),
              ),
            ],
            metadata: const {'continuation': 'signature'},
          ),
          finishReason: genkit.FinishReason.stop,
          usage: genkit.GenerationUsage(
            inputTokens: 12,
            outputTokens: 8,
            totalTokens: 20,
          ),
        ),
        onRequest: (request) => capturedRequest = request,
      );
      final service = _createService(providerFactory: providerFactory);

      final results = await service
          .sendMessage(
            _makeConfig(),
            [
              ChatMessage.system('system prompt'),
              ChatMessage.user('hello'),
              ChatMessage.model(
                'ignored',
                parts: [genkit.TextPart(text: 'model part')],
              ),
              ChatMessage(
                role: ChatMessageRole.tool,
                parts: [
                  genkit.ToolResponsePart(
                    toolResponse: genkit.ToolResponse(
                      ref: 'tool-0',
                      name: 'lookup_weather',
                      output: 'sunny',
                    ),
                  ),
                ],
              ),
            ],
            tools: const [
              ToolSpec(
                name: 'lookup_weather',
                description: 'Looks up weather',
                inputJsonSchema: {
                  'type': 'object',
                  'properties': {
                    'city': {'type': 'string'},
                  },
                },
              ),
            ],
          )
          .toList();

      expect(results, hasLength(2));
      expect(results.firstOrNull?.output.text, 'Hello');
      expect(results.last.finishReason, FinishReason.toolCalls);
      expect(results.last.entityTools.single.id, 'tool-1');
      expect(results.last.entityPromptTokens, 12);
      expect(results.last.entityCompletionTokens, 8);
      expect(results.last.entityTotalTokens, 20);
      expect(results.last.entityModelMetadata, {'continuation': 'signature'});

      expect(capturedRequest?.tools?.single.name, 'lookup_weather');
      expect(capturedRequest?.messages.map((message) => message.role.value), [
        'system',
        'user',
        'model',
        'tool',
      ]);
      expect(capturedRequest?.messages[2].text, 'model part');
    });

    test('encodes unsafe tool refs before sending provider messages', () async {
      genkit.ModelRequest? capturedRequest;
      final providerFactory = _FakeProviderFactory(
        onRequest: (request) => capturedRequest = request,
      );
      final service = _createService(providerFactory: providerFactory);

      final _ = await service.sendMessage(
        _makeConfig(type: ModelProvidersType.anthropic),
        [
          ChatMessage(
            role: ChatMessageRole.tool,
            parts: [
              genkit.ToolResponsePart(
                toolResponse: genkit.ToolResponse(
                  ref: 'skill_context:example',
                  name: 'skill_context',
                  output: '<skill />',
                ),
              ),
            ],
          ),
          ChatMessage.model(
            '',
            parts: [
              genkit.ToolRequestPart(
                toolRequest: genkit.ToolRequest(
                  ref: 'tool:1',
                  name: 'lookup_weather',
                  input: const {'city': 'Medellin'},
                ),
              ),
            ],
          ),
          ChatMessage(
            role: ChatMessageRole.tool,
            parts: [
              genkit.ToolResponsePart(
                toolResponse: genkit.ToolResponse(
                  ref: 'tool:1',
                  name: 'lookup_weather',
                  output: 'sunny',
                ),
              ),
            ],
          ),
        ],
      ).toList();

      final skillContextResult =
          capturedRequest?.messages.firstOrNull?.content.single
                  .toJson()['toolResponse']
              as Map<String, Object?>?;
      final replayedRequest =
          capturedRequest?.messages[1].content.single.toJson()['toolRequest']
              as Map<String, Object?>?;
      final replayedResult =
          capturedRequest?.messages[2].content.single.toJson()['toolResponse']
              as Map<String, Object?>?;
      final refs = [
        skillContextResult?['ref'],
        replayedRequest?['ref'],
        replayedResult?['ref'],
      ];

      expect(refs, [
        'skill_context_x3a_example',
        'tool_x3a_1',
        'tool_x3a_1',
      ]);
      expect(refs, everyElement(matches(RegExp(r'^[a-zA-Z0-9_-]+$'))));
    });

    test(
      'passes thinking config for reasoning-capable anthropic chats',
      () async {
        genkit.ModelRequest? capturedRequest;
        final providerFactory = _FakeProviderFactory(
          onRequest: (request) => capturedRequest = request,
        );
        final service = _createService(providerFactory: providerFactory);

        final chunks = await service.sendMessage(
          _makeConfig(
            type: ModelProvidersType.anthropic,
            supportsReasoning: true,
          ),
          [ChatMessage.user('hello')],
        ).toList();
        expect(chunks, isNotEmpty);

        expect(capturedRequest?.config, {
          'thinking': {'type': 'enabled', 'budgetTokens': 1024},
        });
      },
    );

    test(
      'does not infer thinking config from anthropic model ids',
      () async {
        genkit.ModelRequest? capturedRequest;
        final providerFactory = _FakeProviderFactory(
          onRequest: (request) => capturedRequest = request,
        );
        final service = _createService(providerFactory: providerFactory);

        final chunks = await service.sendMessage(
          _makeConfig(
            type: ModelProvidersType.anthropic,
            modelId: 'claude-sonnet-4-5',
          ),
          [ChatMessage.user('hello')],
        ).toList();
        expect(chunks, isNotEmpty);

        expect(capturedRequest?.config, isNull);
      },
    );

    test('maps non-tool finish reasons from Genkit final response', () async {
      final service = _createService(
        providerFactory: _FakeProviderFactory(
          response: _modelResponse(genkit.FinishReason.length),
        ),
      );

      final results = await service.sendMessage(_makeConfig(), []).toList();

      expect(results.single.finishReason, FinishReason.length);
    });

    test('maps interrupted finish reason distinctly', () async {
      final service = _createService(
        providerFactory: _FakeProviderFactory(
          response: _modelResponse(genkit.FinishReason.interrupted),
        ),
      );

      final results = await service.sendMessage(_makeConfig(), []).toList();

      expect(results.single.finishReason, FinishReason.interrupted);
    });

    test('maps unknown finish reason to other', () async {
      final service = _createService(
        providerFactory: _FakeProviderFactory(
          response: _modelResponse(genkit.FinishReason.blocked),
        ),
      );

      final results = await service.sendMessage(_makeConfig(), []).toList();

      expect(results.single.finishReason, FinishReason.other);
    });

    test('maps custom finish reason to other', () async {
      final service = _createService(
        providerFactory: _FakeProviderFactory(
          response: genkit.ModelResponse(
            message: genkit.Message(role: genkit.Role.model, content: const []),
            finishReason: genkit.FinishReason(''),
          ),
        ),
      );

      final results = await service.sendMessage(_makeConfig(), []).toList();

      expect(results.single.finishReason, FinishReason.other);
    });
  });

  group('ChatbotService.generateFallbackTitle', () {
    test('returns first 4 words of short message', () {
      final title = ChatbotService.generateFallbackTitle(
        'Hello world this is a test',
      );

      expect(title, 'Hello world this is');
    });

    test('returns all words when message has 4 or fewer words', () {
      expect(
        ChatbotService.generateFallbackTitle('Hello world'),
        'Hello world',
      );
      expect(
        ChatbotService.generateFallbackTitle('one two three four'),
        'one two three four',
      );
    });

    test('returns single word for single word message', () {
      expect(ChatbotService.generateFallbackTitle('Hello'), 'Hello');
    });

    test('returns empty string for empty message', () {
      expect(ChatbotService.generateFallbackTitle(''), '');
    });

    test('truncates long title to 30 characters with ellipsis', () {
      const longMessage =
          'Extraordinarily lengthy complicated sophisticated expressions';
      final title = ChatbotService.generateFallbackTitle(longMessage);

      expect(title.length, 30);
      expect(title.endsWith('...'), isTrue);
    });

    test('handles multiple spaces between words', () {
      final title = ChatbotService.generateFallbackTitle(
        'Hello   world   test   words   here',
      );

      expect(title, 'Hello world test words');
    });

    test('handles leading and trailing spaces', () {
      final title = ChatbotService.generateFallbackTitle('  Hello world  ');

      expect(title, 'Hello world');
    });

    test('returns short title unchanged when under 30 chars', () {
      const message = 'Hi there friend';
      final title = ChatbotService.generateFallbackTitle(message);

      expect(title, message);
      expect(title.length, lessThanOrEqualTo(30));
    });

    test('exactly at boundary does not truncate', () {
      final words = List.generate(4, (i) => 'a' * 6).join(' ');
      final title = ChatbotService.generateFallbackTitle(words);

      expect(title, words);
      expect(title.endsWith('...'), isFalse);
    });

    test('handles tab and newline separated words', () {
      final title = ChatbotService.generateFallbackTitle(
        'word1\tword2\nword3\tword4 word5',
      );
      expect(title, 'word1 word2 word3 word4');
    });

    test('handles very long single word', () {
      final longWord = 'a' * 100;
      final title = ChatbotService.generateFallbackTitle(longWord);
      expect(title.length, 30);
      expect(title.endsWith('...'), isTrue);
    });
  });

  group('ChatbotService.streamTitle processing', () {
    test('streams processed title from Genkit chunks', () async {
      final service = _createService(
        providerFactory: _FakeProviderFactory(
          chunks: [
            genkit.ModelResponseChunk(
              content: [genkit.TextPart(text: 'Title: Deep')],
            ),
            genkit.ModelResponseChunk(
              content: [genkit.TextPart(text: ' Focus')],
            ),
          ],
          response: _modelResponse(genkit.FinishReason.stop),
        ),
      );

      final titles = await service.streamTitle(_makeConfig(), 'hello').toList();

      expect(titles.last, 'Deep Focus');
    });

    test('falls back when title generation throws', () async {
      final service = _createService(
        providerFactory: _FakeProviderFactory(throwsOnGenerate: true),
      );

      final titles = await service
          .streamTitle(_makeConfig(), 'hello world from failure')
          .toList();

      expect(titles, ['hello world from failure']);
    });

    test('strips double quotes from title', () {
      final stripped = _stripQuotes('"My Title"');
      expect(stripped, 'My Title');
    });

    test('strips single quotes from title', () {
      final quote = String.fromCharCode(39);
      final stripped = _stripQuotes('${quote}My Title$quote');
      expect(stripped, 'My Title');
    });

    test('does not strip mismatched quote characters', () {
      const mixedA = '"My Title\u0027';
      const mixedB = '\u0027My Title"';
      expect(_stripQuotes(mixedA), mixedA);
      expect(_stripQuotes(mixedB), mixedB);
    });

    test('strips Title: prefix', () {
      final stripped = _stripPrefixes('Title: My Conversation');
      expect(stripped, 'My Conversation');
    });

    test('strips Conversation: prefix', () {
      final stripped = _stripPrefixes('Conversation: My Topic');
      expect(stripped, 'My Topic');
    });

    test('truncates title over 50 chars', () {
      final longTitle = 'a' * 60;
      final processed = _processTitle(longTitle);
      expect(processed.length, 50);
      expect(processed.endsWith('...'), isTrue);
    });

    test('returns title unchanged when under 50 chars', () {
      const title = 'Short Title';
      final processed = _processTitle(title);
      expect(processed, title);
    });

    test('returns fallback for empty processed title', () {
      final fallback = ChatbotService.generateFallbackTitle('test message');
      expect(fallback, isNotEmpty);
    });
  });
}

String _stripQuotes(String title) {
  var processed = title.trim();
  // Mirror service helper: prefer-single-quotes forces escape here.
  // ignore: avoid_escaping_inner_quotes
  for (final quote in const ['"', '\'']) {
    if (processed.length > 1 &&
        processed.startsWith(quote) &&
        processed.endsWith(quote)) {
      processed = processed.withoutEdgeCharacters();
    }
  }

  return processed;
}

String _stripPrefixes(String title) {
  var processed = title.trim();
  if (processed.startsWith('Title:')) {
    processed = processed.replaceFirst('Title:', '').trim();
  }
  if (processed.startsWith('Conversation:')) {
    processed = processed.replaceFirst('Conversation:', '').trim();
  }

  return processed;
}

String _processTitle(String title) {
  var processed = title.trim();
  // Mirror service helper: prefer-single-quotes forces escape here.
  // ignore: avoid_escaping_inner_quotes
  for (final quote in const ['"', '\'']) {
    if (processed.length > 1 &&
        processed.startsWith(quote) &&
        processed.endsWith(quote)) {
      processed = processed.withoutEdgeCharacters();
    }
  }
  if (processed.startsWith('Title:')) {
    processed = processed.replaceFirst('Title:', '').trim();
  }
  if (processed.startsWith('Conversation:')) {
    processed = processed.replaceFirst('Conversation:', '').trim();
  }

  return processed.truncateCharacters(50);
}

ChatbotService _createService({ProviderFactory? providerFactory}) {
  return ChatbotService(
    encryptionService: _FakeEncryptionService(),
    providerFactory: providerFactory,
  );
}

WorkspaceModelSelectionWithConnectionEntity _makeConfig({
  ModelProvidersType type = ModelProvidersType.openai,
  String modelId = 'model',
  bool supportsReasoning = false,
}) {
  return WorkspaceModelSelectionWithConnectionEntity(
    workspaceModelSelection: WorkspaceModelSelectionEntity(
      id: 'selection-1',
      modelId: modelId,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      modelConnectionId: 'connection-1',
      supportsReasoning: supportsReasoning,
    ),
    modelConnection: ModelConnectionEntity(
      id: 'connection-1',
      name: 'Test Connection',
      key: 'encrypted-key',
      modelId: modelId,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      workspaceId: 'workspace-1',
    ),
    modelsProvider: ApiModelProviderEntity(
      id: 'provider-1',
      name: 'Test Provider',
      type: type,
    ),
  );
}

genkit.ModelResponse _modelResponse(genkit.FinishReason finishReason) {
  return genkit.ModelResponse(
    message: genkit.Message(role: genkit.Role.model, content: const []),
    finishReason: finishReason,
  );
}

class _FakeProviderFactory extends ProviderFactory {
  _FakeProviderFactory({
    this.chunks = const [],
    genkit.ModelResponse? response,
    this.onRequest,
    this.throwsOnGenerate = false,
  }) : response = response ?? _modelResponse(genkit.FinishReason.stop),
       super(encryptionService: _FakeEncryptionService());

  final List<genkit.ModelResponseChunk> chunks;
  final genkit.ModelResponse response;
  final void Function(genkit.ModelRequest request)? onRequest;
  final bool throwsOnGenerate;

  @override
  Future<genkit.Genkit> createGenkit(
    WorkspaceModelSelectionWithConnectionEntity config, {
    String? sessionId,
  }) async {
    return genkit.Genkit(isDevEnv: false)..defineModel(
      name: 'test/model',
      fn: (input, context) async {
        onRequest?.call(input);
        if (throwsOnGenerate) {
          throw Exception('failed');
        }
        chunks.forEach(context.sendChunk);

        return response;
      },
    );
  }

  @override
  genkit.ModelRef<Object?> getModelReference(
    WorkspaceModelSelectionWithConnectionEntity config,
  ) {
    return genkit.modelRef<Object?>('test/model');
  }
}

class _FakeEncryptionService extends EncryptionService {
  _FakeEncryptionService() : super(_FakeSecretKeyManager());

  @override
  Future<String> decrypt(String _) async => 'test-api-key';
}

class _FakeSecretKeyManager extends SecretKeyManager {
  _FakeSecretKeyManager() : super();

  @override
  Future<SecretKey> getOrCreateSecretKey() async {
    return SecretKey(List<int>.generate(32, (i) => i));
  }
}
