// ignore_for_file: type=lint, type=warning
import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/genkit.dart';
import 'package:test/test.dart';

void main() {
  test('OpenRouter builds and parses chat completions', () async {
    final codec = ChatCompletionsCodec(
      errorLabel: 'OpenRouter',
      customize: (modelName, config) {
        final options = OpenRouterOptions.fromJson(config);
        return (
          model: modelName,
          extraBody: {
            ...options.toSamplingBody(),
            if (options.reasoningEnabled == false ||
                options.reasoningEffort != null ||
                options.reasoningMaxTokens != null)
              'reasoning': {
                if (options.reasoningEnabled == false) 'enabled': false,
                'effort': ?options.reasoningEffort,
                'max_tokens': ?options.reasoningMaxTokens,
              },
          },
        );
      },
    );
    final body = codec.buildRequestBody(
      modelName: 'model',
      request: ModelRequest(
        messages: [
          Message(
            role: Role.user,
            content: [TextPart(text: 'Hi')],
          ),
        ],
        config: OpenRouterOptions(reasoningMaxTokens: 10).toJson(),
      ),
      stream: false,
    );
    final response = await codec.complete(
      (_) async => _response({
        'choices': [
          {
            'finish_reason': 'stop',
            'message': {'role': 'assistant', 'content': 'Answer.'},
          },
        ],
      }),
      body,
    );

    expect(body['reasoning'], {'max_tokens': 10});
    expect(body['messages'], [
      {'role': 'user', 'content': 'Hi'},
    ]);
    expect(response.message?.text, 'Answer.');
  });

  test('OpenRouter maps effort and disabled reasoning options', () {
    final codec = ChatCompletionsCodec(
      errorLabel: 'OpenRouter',
      customize: (modelName, config) {
        final options = OpenRouterOptions.fromJson(config);
        return (
          model: modelName,
          extraBody: {
            if (options.reasoningEnabled == false ||
                options.reasoningEffort != null ||
                options.reasoningMaxTokens != null)
              'reasoning': {
                if (options.reasoningEnabled == false) 'enabled': false,
                'effort': ?options.reasoningEffort,
                'max_tokens': ?options.reasoningMaxTokens,
              },
          },
        );
      },
    );

    final effortBody = codec.buildRequestBody(
      modelName: 'model',
      request: ModelRequest(
        messages: const [],
        config: OpenRouterOptions(reasoningEffort: 'high').toJson(),
      ),
      stream: false,
    );
    final disabledBody = codec.buildRequestBody(
      modelName: 'model',
      request: ModelRequest(
        messages: const [],
        config: OpenRouterOptions(reasoningEnabled: false).toJson(),
      ),
      stream: false,
    );

    expect(effortBody['reasoning'], {'effort': 'high'});
    expect(disabledBody['reasoning'], {'enabled': false});
  });

  test('OpenAI-compatible codec maps version and thinking options', () {
    final codec = ChatCompletionsCodec(
      errorLabel: 'OpenAI-compatible',
      customize: (modelName, config) {
        final options = OpenAICompatReasoningOptions.fromJson(config);
        return (
          model: options.version ?? modelName,
          extraBody: {
            ...options.toSamplingBody(),
            if (options.reasoningType != null)
              'thinking': {'type': options.reasoningType},
          },
        );
      },
    );
    final body = codec.buildRequestBody(
      modelName: 'alias',
      request: ModelRequest(
        messages: const [],
        config: OpenAICompatReasoningOptions(
          version: 'model-version',
          reasoningType: 'enabled',
        ).toJson(),
      ),
      stream: false,
    );

    expect(body['model'], 'model-version');
    expect(body['thinking'], {'type': 'enabled'});
  });

  test('OpenAI-compatible codec maps reasoning effort', () {
    const codec = ChatCompletionsCodec(
      errorLabel: 'OpenAI-compatible',
      customize: _openAiCompatReasoningCustomize,
    );
    final body = codec.buildRequestBody(
      modelName: 'model',
      request: ModelRequest(
        messages: const [],
        config: OpenAICompatReasoningOptions(reasoningEffort: 'high').toJson(),
      ),
      stream: false,
    );
    final disabledBody = codec.buildRequestBody(
      modelName: 'model',
      request: ModelRequest(
        messages: const [],
        config: OpenAICompatReasoningOptions(reasoningEffort: 'none').toJson(),
      ),
      stream: false,
    );

    expect(body['reasoning_effort'], 'high');
    expect(body.containsKey('reasoning'), isFalse);
    expect(disabledBody['reasoning_effort'], 'none');
  });

  test('OpenAI-compatible options retain tool sampling policy', () {
    final openRouter = OpenRouterOptions.fromJson(
      OpenRouterOptions(toolSamplingPolicy: ToolSamplingPolicy.prefer).toJson(),
    );
    final reasoning = OpenAICompatReasoningOptions.fromJson(
      OpenAICompatReasoningOptions(
        toolSamplingPolicy: ToolSamplingPolicy.require,
      ).toJson(),
    );

    expect(openRouter.toolSamplingPolicy, ToolSamplingPolicy.prefer);
    expect(reasoning.toolSamplingPolicy, ToolSamplingPolicy.require);
    expect(const OpenAICompatChatOptions().toJson(), isEmpty);
  });

  group('strict tool sampling', () {
    test('reports per-tool decisions without schema or argument values', () {
      final codec = _toolSamplingCodec(providerSupportsStrict: true);
      final result = codec.evaluateTools(
        tools: [
          _toolDefinition(),
          ToolDefinition(
            name: 'fallback',
            description: 'token=sk-secret-value',
            inputSchema: {
              'type': 'object',
              'description': 'password=hidden',
              'properties': {
                'value': {'type': 'string'},
              },
              'required': <String>[],
              'additionalProperties': false,
            },
          ),
        ],
        policy: ToolSamplingPolicy.prefer,
        modelSupportsStrict: true,
      );

      expect(result.decisions.map((decision) => decision.outcome), [
        ToolSamplingOutcome.strict,
        ToolSamplingOutcome.ordinary,
      ]);
      expect(
        result.decisions.last.reason,
        ToolSamplingValidationReason.incompatibleSchema,
      );
      expect(result.decisions.last.schemaPath, r'$.required');
      final diagnostics = jsonEncode([
        for (final decision in result.decisions) decision.toDiagnostic(),
      ]);
      expect(diagnostics, isNot(contains('sk-secret-value')));
      expect(diagnostics, isNot(contains('password=hidden')));
      expect(result.definitions!.first['function']['strict'], isTrue);
      expect(
        (result.definitions!.last['function'] as Map).containsKey('strict'),
        isFalse,
      );
    });

    test('reports provider and model fallbacks separately', () {
      for (final testCase in [
        (
          provider: false,
          model: true,
          reason: ToolSamplingValidationReason.unsupportedProvider,
        ),
        (
          provider: true,
          model: false,
          reason: ToolSamplingValidationReason.unsupportedModel,
        ),
      ]) {
        final result =
            _toolSamplingCodec(providerSupportsStrict: testCase.provider)
                .evaluateTools(
                  tools: [_toolDefinition()],
                  policy: ToolSamplingPolicy.require,
                  modelSupportsStrict: testCase.model,
                );
        expect(result.decisions.single.reason, testCase.reason);
        expect(
          result.requireStrict,
          throwsA(
            isA<ToolSamplingValidationException>().having(
              (error) => error.reason,
              'reason',
              testCase.reason,
            ),
          ),
        );
      }
    });

    test('keeps the default request body unchanged', () {
      final body = _buildToolBody(
        codec: _toolSamplingCodec(providerSupportsStrict: true),
        modelSupportsStrict: true,
      );

      expect(body['tools'], [
        {
          'type': 'function',
          'function': {
            'name': 'create_profile',
            'description': 'Create a profile.',
            'parameters': _strictToolSchema,
          },
        },
      ]);
    });

    test('prefer and require emit strict mode for compatible schemas', () {
      for (final policy in [
        ToolSamplingPolicy.prefer,
        ToolSamplingPolicy.require,
      ]) {
        final body = _buildToolBody(
          codec: _toolSamplingCodec(providerSupportsStrict: true),
          modelSupportsStrict: true,
          policy: policy,
        );

        expect(body['tools'], [
          {
            'type': 'function',
            'function': {
              'name': 'create_profile',
              'description': 'Create a profile.',
              'parameters': _strictToolSchema,
              'strict': true,
            },
          },
        ]);
      }
    });

    test(
      'xAI profile uses implicit strict wire mode and preflights limits',
      () {
        final profile = strictToolSamplingProfile(
          'openai',
          'grok-4.7',
          'https://api.x.ai/v1',
        )!;
        final codec = _toolSamplingCodec(
          providerSupportsStrict: false,
          profile: profile,
        );
        final body = _buildToolBody(
          codec: codec,
          modelSupportsStrict: true,
          policy: ToolSamplingPolicy.require,
        );
        final function = _singleFunction(body);

        expect(function.containsKey('strict'), isFalse);
        expect(function['parameters'], _strictToolSchema);
        expect(
          () => _buildToolBody(
            codec: codec,
            modelSupportsStrict: true,
            policy: ToolSamplingPolicy.require,
            tools: [
              _toolDefinition(
                schema: {
                  'type': 'object',
                  'properties': {
                    'value': {'type': 'string', 'maxLength': 2049},
                  },
                  'required': ['value'],
                  'additionalProperties': false,
                },
              ),
            ],
          ),
          throwsA(
            isA<ToolSamplingValidationException>().having(
              (error) => error.schemaReason,
              'schemaReason',
              ToolSchemaIssueReason.providerLimit,
            ),
          ),
        );
      },
    );

    test('prefer falls back when provider or model lacks support', () {
      for (final testCase in [
        (provider: false, model: true),
        (provider: true, model: false),
      ]) {
        final body = _buildToolBody(
          codec: _toolSamplingCodec(providerSupportsStrict: testCase.provider),
          modelSupportsStrict: testCase.model,
          policy: ToolSamplingPolicy.prefer,
        );
        final function = _singleFunction(body);

        expect(function.containsKey('strict'), isFalse);
        expect(function['parameters'], _strictToolSchema);
      }
    });

    test('prefer falls back only for incompatible schemas', () {
      final body = _buildToolBody(
        codec: _toolSamplingCodec(providerSupportsStrict: true),
        modelSupportsStrict: true,
        policy: ToolSamplingPolicy.prefer,
        tools: [
          _toolDefinition(),
          _toolDefinition(name: 'invalid', schema: _optionalFieldSchema),
        ],
      );
      final tools = body['tools']! as List<dynamic>;
      final valid =
          (tools.first as Map<String, dynamic>)['function']!
              as Map<String, dynamic>;
      final invalid =
          (tools.last as Map<String, dynamic>)['function']!
              as Map<String, dynamic>;

      expect(valid['strict'], isTrue);
      expect(invalid.containsKey('strict'), isFalse);
    });

    test('require rejects unsupported providers before transport', () {
      expect(
        () => _buildToolBody(
          codec: _toolSamplingCodec(providerSupportsStrict: false),
          modelSupportsStrict: true,
          policy: ToolSamplingPolicy.require,
        ),
        throwsA(
          isA<ToolSamplingValidationException>().having(
            (error) => error.reason,
            'reason',
            ToolSamplingValidationReason.unsupportedProvider,
          ),
        ),
      );
    });

    test('require rejects unsupported models before transport', () {
      expect(
        () => _buildToolBody(
          codec: _toolSamplingCodec(providerSupportsStrict: true),
          modelSupportsStrict: false,
          policy: ToolSamplingPolicy.require,
        ),
        throwsA(
          isA<ToolSamplingValidationException>().having(
            (error) => error.reason,
            'reason',
            ToolSamplingValidationReason.unsupportedModel,
          ),
        ),
      );
    });

    test('require rejects malformed and non-strict optional schemas', () {
      for (final schema in <Map<String, dynamic>>[
        _optionalFieldSchema,
        const {
          'type': 'object',
          'properties': {'value': 'not-a-schema'},
          'required': ['value'],
          'additionalProperties': false,
        },
        const {
          'type': 'object',
          'properties': {
            'items': {'type': 'array'},
          },
          'required': ['items'],
          'additionalProperties': false,
        },
      ]) {
        expect(
          () => _buildToolBody(
            codec: _toolSamplingCodec(providerSupportsStrict: true),
            modelSupportsStrict: true,
            policy: ToolSamplingPolicy.require,
            tools: [_toolDefinition(schema: schema)],
          ),
          throwsA(
            isA<ToolSamplingValidationException>()
                .having(
                  (error) => error.reason,
                  'reason',
                  ToolSamplingValidationReason.incompatibleSchema,
                )
                .having(
                  (error) => error.toolName,
                  'toolName',
                  'create_profile',
                ),
          ),
        );
      }
    });
  });

  test('provider codecs encode shared audio data input', () {
    final request = ModelRequest(
      messages: [
        Message(
          role: Role.user,
          content: [
            MediaPart(
              media: Media(
                contentType: 'audio/mp3',
                url: 'data:audio/mp3;base64,aGk=',
              ),
            ),
          ],
        ),
      ],
    );
    final chatCodec = ChatCompletionsCodec(
      errorLabel: 'Provider',
      customize: (modelName, config) => (model: modelName, extraBody: {}),
    );

    final chatBody = chatCodec.buildRequestBody(
      modelName: 'model',
      request: request,
      stream: false,
    );
    final codexBody = const OpenAICodexCodec().buildRequestBody(
      modelName: 'model',
      request: request,
      stream: false,
    );

    const audio = {
      'type': 'input_audio',
      'input_audio': {'data': 'aGk=', 'format': 'mp3'},
    };
    expect(chatBody['messages'], [
      {
        'role': 'user',
        'content': [audio],
      },
    ]);
    expect(codexBody['input'], [
      {
        'role': 'user',
        'content': [audio],
      },
    ]);
  });

  test('Codex builds and streams responses', () async {
    const codec = OpenAICodexCodec();
    final body = codec.buildRequestBody(
      modelName: 'gpt-5.5',
      request: ModelRequest(
        messages: [
          Message(
            role: Role.user,
            content: [TextPart(text: 'Hi')],
          ),
        ],
      ),
      stream: true,
    );
    final chunks = <ModelResponseChunk>[];
    final response = await codec.stream(
      (_) async => ProviderTransportResponse(
        statusCode: 200,
        body: Stream.fromIterable([
          utf8.encode(
            'data: {"type":"response.output_text.delta","delta":"Hi"}\n',
          ),
          utf8.encode('data: {"type":"response.completed"}\n'),
        ]),
      ),
      body,
      chunks.add,
    );

    expect(body['store'], false);
    expect(chunks.single.text, 'Hi');
    expect(response.message?.text, 'Hi');
  });

  test('OpenAI-compatible reasoning body maps effort and disable', () {
    expect(
      OpenAICompatReasoningOptions(reasoningEffort: 'high').toReasoningBody(),
      {'reasoning_effort': 'high'},
    );
    expect(OpenAICompatReasoningOptions().toReasoningBody(enabled: false), {
      'reasoning_effort': 'none',
    });
    expect(OpenAICompatReasoningOptions().toReasoningBody(), isEmpty);
  });

  test('Codex maps explicit effort, disable, and provider defaults', () {
    const codec = OpenAICodexCodec();
    final body = codec.buildRequestBody(
      modelName: 'gpt-5.5',
      request: ModelRequest(messages: const []),
      stream: false,
      reasoningConfiguration: const ReasoningConfiguration(effort: 'high'),
    );
    final disabledBody = codec.buildRequestBody(
      modelName: 'gpt-5.5',
      request: ModelRequest(messages: const []),
      stream: false,
      reasoningConfiguration: const ReasoningConfiguration(enabled: false),
    );
    final defaultBody = codec.buildRequestBody(
      modelName: 'gpt-5.5',
      request: ModelRequest(messages: const []),
      stream: false,
    );

    expect(body['reasoning'], {'effort': 'high'});
    expect(disabledBody['reasoning'], {'effort': 'none'});
    expect(defaultBody.containsKey('reasoning'), isFalse);
  });

  test('Codex retains streamed tool calls', () async {
    const codec = OpenAICodexCodec();
    final response = await codec.stream(
      (_) async => ProviderTransportResponse(
        statusCode: 200,
        body: Stream.value(
          utf8.encode(
            'data: {"type":"response.output_item.done","item": '
            '{"type":"function_call","call_id":"call-1",'
            '"name":"search","arguments":"{\\"query\\":\\"dart\\"}"}}\n',
          ),
        ),
      ),
      const {},
      (_) {},
    );

    final tool = response.message!.content.single.toolRequest!;
    expect(tool.ref, 'call-1');
    expect(tool.name, 'search');
    expect(tool.input, {'query': 'dart'});
  });

  test('Codex streams text present only in the completed response', () async {
    const codec = OpenAICodexCodec();
    final chunks = <ModelResponseChunk>[];
    final response = await codec.stream(
      (_) async => ProviderTransportResponse(
        statusCode: 200,
        body: Stream.fromIterable([
          utf8.encode(
            'data: {"type":"response.output_text.delta",'
            '"delta":"create"}\n',
          ),
          utf8.encode(
            'data: {"type":"response.completed","response":{'
            '"status":"completed","output_text":"create update"}}\n',
          ),
        ]),
      ),
      const {},
      chunks.add,
    );

    expect(chunks.map((chunk) => chunk.text), ['create', ' update']);
    expect(response.message?.text, 'create update');
  });

  test('Codex recovers authoritative text from done events', () async {
    const codec = OpenAICodexCodec();
    final chunks = <ModelResponseChunk>[];
    final response = await codec.stream(
      (_) async => ProviderTransportResponse(
        statusCode: 200,
        body: Stream.fromIterable([
          utf8.encode(
            'data: {"type":"response.output_text.delta",'
            '"delta":"create"}\n',
          ),
          utf8.encode(
            'data: {"type":"response.output_text.done",'
            '"text":"create update"}\n',
          ),
          utf8.encode(
            'data: {"type":"response.incomplete","response":{'
            '"status":"incomplete"}}\n',
          ),
        ]),
      ),
      const {},
      chunks.add,
    );

    expect(chunks.map((chunk) => chunk.text), ['create', ' update']);
    expect(response.message?.text, 'create update');
    expect(response.finishReason, FinishReason.length);
  });

  test('Codex surfaces streamed failures', () async {
    const codec = OpenAICodexCodec();

    await expectLater(
      codec.stream(
        (_) async => ProviderTransportResponse(
          statusCode: 200,
          body: Stream.value(
            utf8.encode(
              'data: {"type":"response.failed","error":{"message":"no"}}\n',
            ),
          ),
        ),
        const {},
        (_) {},
      ),
      throwsA(isA<GenkitException>()),
    );
  });

  test('streaming provider failures preserve safe provider details', () async {
    const secret = 'provider-secret-value';
    final providerMessage =
        'Model rejected request: api_key=$secret '
        'Authorization: Bearer $secret '
        '{"api_key":"$secret"} ${'x' * 600}';
    final codec = ChatCompletionsCodec(
      errorLabel: 'Provider',
      customize: (modelName, config) => (model: modelName, extraBody: {}),
    );

    try {
      await codec.stream(
        (_) async => _response({
          'error': {'message': providerMessage},
        }, statusCode: 404),
        const {},
        (_) {},
      );
      fail('Expected provider request to fail');
    } on GenkitException catch (error) {
      expect(error.status, StatusCode.notFound);
      expect(error.message, 'Provider API request failed (HTTP 404).');
      expect(error.details, contains('Model rejected request'));
      expect(error.details, contains('[REDACTED]'));
      expect(error.details!.length, lessThanOrEqualTo(500));
      expect(error.toString(), isNot(contains(secret)));
    }
  });

  test(
    'streaming provider failures handle empty and malformed bodies',
    () async {
      final codec = ChatCompletionsCodec(
        errorLabel: 'Provider',
        customize: (modelName, config) => (model: modelName, extraBody: {}),
      );

      for (final body in ['', '{not-json']) {
        try {
          await codec.stream(
            (_) async => ProviderTransportResponse(
              statusCode: 502,
              body: Stream.value(utf8.encode(body)),
            ),
            const {},
            (_) {},
          );
          fail('Expected provider request to fail');
        } on GenkitException catch (error) {
          expect(error.message, 'Provider API request failed (HTTP 502).');
          expect(error.status, StatusCode.unknown);
          expect(error.details, isNull);
        }
      }
    },
  );

  test('provider failures do not expose response bodies', () async {
    const secret = 'provider-secret-value';
    final codec = ChatCompletionsCodec(
      errorLabel: 'Provider',
      customize: (modelName, config) => (model: modelName, extraBody: {}),
    );

    try {
      await codec.complete(
        (_) async => _response({'error': secret}, statusCode: 500),
        const {},
      );
      fail('Expected provider request to fail');
    } on GenkitException catch (error) {
      expect(error.toString(), isNot(contains(secret)));
    }

    try {
      const codex = OpenAICodexCodec();
      await codex.complete(
        (_) async => _response({'error': secret}, statusCode: 500),
        const {},
      );
      fail('Expected Codex request to fail');
    } on GenkitException catch (error) {
      expect(error.toString(), isNot(contains(secret)));
    }
  });

  test('provider codec rejects an oversized declared response', () async {
    final codec = _testCodec();

    await expectLater(
      codec.complete(
        (_) async => ProviderTransportResponse(
          statusCode: 200,
          contentLength: 4 * 1024 * 1024 + 1,
          body: const Stream.empty(),
        ),
        const {},
      ),
      throwsA(
        isA<GenkitException>().having(
          (error) => error.status,
          'status',
          StatusCode.resourceExhausted,
        ),
      ),
    );
  });

  test('provider codec rejects a streamed response above the byte limit', () {
    final codec = _testCodec();

    expectLater(
      codec.stream(
        (_) async => ProviderTransportResponse(
          statusCode: 200,
          body: Stream.fromIterable([
            List<int>.filled(4 * 1024 * 1024, 0),
            const [0],
          ]),
        ),
        const {},
        (_) {},
      ),
      throwsA(isA<GenkitException>()),
    );
  });

  test('provider codec stops reading after the done event', () async {
    final codec = _testCodec();
    var readAfterDone = false;
    final response = await codec.stream(
      (_) async => ProviderTransportResponse(
        statusCode: 200,
        body: (() async* {
          yield utf8.encode(
            'data: {"choices":[{"delta":{"content":"ok"},'
            '"finish_reason":"stop"}]}\n',
          );
          yield utf8.encode('data: [DONE]\n');
          readAfterDone = true;
          yield utf8.encode('data: invalid\n');
        })(),
      ),
      const {},
      (_) {},
    );

    expect(response.message?.text, 'ok');
    expect(readAfterDone, isFalse);
  });

  test(
    'Codex retryability requires an exact structured server error',
    () async {
      const codec = OpenAICodexCodec();

      try {
        await codec.complete(
          (_) async => _response({
            'error': {'type': 'server_error', 'message': 'temporary'},
          }, statusCode: 500),
          const {},
        );
        fail('Expected provider request to fail');
      } on GenkitException catch (error) {
        expect(error.details, 'server_error');
        expect(isRetryableCodexError(error), isTrue);
      }

      try {
        await codec.complete(
          (_) async => _response({
            'error': {
              'type': 'invalid_request_error',
              'message': 'bad request',
            },
          }, statusCode: 500),
          const {},
        );
        fail('Expected provider request to fail');
      } on GenkitException catch (error) {
        expect(error.details, isNull);
        expect(isRetryableCodexError(error), isFalse);
      }
    },
  );
}

({String model, Map<String, dynamic> extraBody})
_openAiCompatReasoningCustomize(
  String modelName,
  Map<String, dynamic>? config,
) {
  final options = OpenAICompatReasoningOptions.fromJson(config);

  return (
    model: options.version ?? modelName,
    extraBody: options.toReasoningBody(),
  );
}

ChatCompletionsCodec _testCodec() => ChatCompletionsCodec(
  errorLabel: 'Provider',
  customize: (modelName, config) => (model: modelName, extraBody: {}),
);

ChatCompletionsCodec _toolSamplingCodec({
  required bool providerSupportsStrict,
  StrictToolSamplingProfile? profile,
}) => ChatCompletionsCodec(
  errorLabel: 'Provider',
  supportsStrictToolSampling: providerSupportsStrict,
  strictToolSamplingProfile: profile,
  customize: (modelName, config) => (model: modelName, extraBody: {}),
);

Map<String, dynamic> _buildToolBody({
  required ChatCompletionsCodec codec,
  required bool modelSupportsStrict,
  ToolSamplingPolicy policy = ToolSamplingPolicy.off,
  List<ToolDefinition>? tools,
}) => codec.buildRequestBody(
  modelName: 'model',
  request: ModelRequest(
    messages: const [],
    config: OpenAICompatChatOptions(toolSamplingPolicy: policy).toJson(),
    tools: tools ?? [_toolDefinition()],
  ),
  stream: false,
  modelCapabilities: _modelCapabilities(
    supportsStrictToolSampling: modelSupportsStrict,
  ),
);

Map<String, dynamic> _singleFunction(Map<String, dynamic> body) {
  final tools = body['tools']! as List<dynamic>;
  return (tools.single as Map<String, dynamic>)['function']!
      as Map<String, dynamic>;
}

ToolDefinition _toolDefinition({
  String name = 'create_profile',
  Map<String, dynamic> schema = _strictToolSchema,
}) => ToolDefinition(
  name: name,
  description: 'Create a profile.',
  inputSchema: schema,
);

ModelCapabilities _modelCapabilities({
  required bool supportsStrictToolSampling,
}) => ModelCapabilities(
  id: 'model',
  name: 'Model',
  limitContext: 128000,
  limitOutput: 4096,
  inputModalities: const ['text'],
  outputModalities: const ['text'],
  supportsStrictToolSampling: supportsStrictToolSampling,
);

const _strictToolSchema = <String, dynamic>{
  'type': 'object',
  'properties': {
    'profile': {
      'type': 'object',
      'properties': {
        'name': {'type': 'string'},
        'nickname': {
          'type': ['string', 'null'],
        },
      },
      'required': ['name', 'nickname'],
      'additionalProperties': false,
    },
    'labels': {
      'type': 'array',
      'items': {
        'type': 'object',
        'properties': {
          'value': {'type': 'string'},
        },
        'required': ['value'],
        'additionalProperties': false,
      },
    },
  },
  'required': ['profile', 'labels'],
  'additionalProperties': false,
};

const _optionalFieldSchema = <String, dynamic>{
  'type': 'object',
  'properties': {
    'requiredValue': {'type': 'string'},
    'optionalValue': {'type': 'string'},
  },
  'required': ['requiredValue'],
  'additionalProperties': false,
};

ProviderTransportResponse _response(
  Map<String, Object?> body, {
  int statusCode = 200,
}) {
  return ProviderTransportResponse(
    statusCode: statusCode,
    body: Stream.value(utf8.encode(jsonEncode(body))),
  );
}
