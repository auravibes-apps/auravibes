import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('parses model capabilities and eligibility', () {
    final model = ModelCapabilities.fromJson(
      'openai',
      {
        'id': 'gpt-5.5',
        'name': 'GPT-5.5',
        'family': 'gpt-5.5',
        'reasoning': true,
        'tool_call': true,
        'structured_output': true,
        'open_weights': false,
        'cost': {'input': 30, 'cache_read': 15, 'output': 60},
        'limit': {'context': 400000, 'output': 128000},
        'modalities': {
          'input': ['TEXT', 'image'],
          'output': ['TEXT'],
        },
        'experimental': {
          'modes': {
            'fast': {
              'provider': {
                'body': {'service_tier': 'priority'},
              },
            },
          },
        },
      },
      {'openai/gpt-5.5'},
    );

    expect(model.inputModalities, ['text', 'image']);
    expect(model.outputModalities, ['text']);
    expect(model.costInput, 30.0);
    expect(model.supportsReasoning, isTrue);
    expect(model.supportsToolCalls, isTrue);
    expect(model.supportsStructuredOutput, isTrue);
    expect(model.supportsStrictToolSampling, isFalse);
    expect(model.supportsPriorityMode, isTrue);
    expect(model.isTextGenerationModel, isTrue);
    expect(model.isCodexRuntimeModel, isTrue);
    expect(() => model.inputModalities.add('audio'), throwsUnsupportedError);
  });

  test('parses reasoning options and derives legacy toggle', () {
    final model = ModelCapabilities.fromJson('openai', {
      'id': 'gpt-5',
      'name': 'GPT-5',
      'reasoning_options': [
        {'type': 'toggle'},
        {
          'type': 'effort',
          'values': ['low', 'medium', 'high'],
        },
        {'type': 'budget_tokens', 'min': 1024, 'max': 32768},
        {'type': 'future_mode', 'value': 'preserve'},
      ],
      'limit': {'context': 1000, 'output': 100},
      'modalities': {
        'input': ['text'],
        'output': ['text'],
      },
    });

    expect(model.supportsReasoning, isTrue);
    expect(model.reasoningOptions.map((option) => option.type), [
      'toggle',
      'effort',
      'budget_tokens',
      'future_mode',
    ]);
    expect(model.reasoningOptions[1].values, ['low', 'medium', 'high']);
    expect(model.reasoningOptions[2].min, 1024);
    expect(model.reasoningOptions[2].max, 32768);

    final legacy = ModelCapabilities.fromJson('openai', {
      'id': 'legacy',
      'name': 'Legacy',
      'reasoning': true,
      'limit': {'context': 1000, 'output': 100},
      'modalities': {
        'input': ['text'],
        'output': ['text'],
      },
    });
    expect(legacy.reasoningOptions.single.isToggle, isTrue);
  });

  test(
    'ignores malformed reasoning options while preserving unknown types',
    () {
      final model = ModelCapabilities.fromJson('openai', {
        'id': 'gpt',
        'name': 'GPT',
        'reasoning_options': [
          {'type': 'effort'},
          {'type': 'budget_tokens', 'min': 4, 'max': 2},
          {'type': 'future_mode'},
        ],
        'limit': {'context': 1000, 'output': 100},
        'modalities': {
          'input': ['text'],
          'output': ['text'],
        },
      });

      expect(model.reasoningOptions.single.type, 'future_mode');
    },
  );

  test('rejects malformed required catalog fields clearly', () {
    expect(
      () => ModelCapabilities.fromJson('openai', {
        'id': 'gpt-5.5',
        'name': 'GPT-5.5',
        'modalities': {
          'input': ['text'],
          'output': ['text'],
        },
      }),
      throwsFormatException,
    );
    expect(
      () => ModelCapabilities.fromJson('openai', {
        'id': 'gpt-5.5',
        'name': 'GPT-5.5',
        'limit': {'context': '400000', 'output': 128000},
        'modalities': {
          'input': ['text'],
          'output': ['text'],
        },
      }),
      throwsFormatException,
    );
  });

  test('rejects malformed modality values clearly', () {
    expect(
      () => ModelCapabilities.fromJson('openai', {
        'id': 'gpt-5.5',
        'name': 'GPT-5.5',
        'limit': {'context': 400000, 'output': 128000},
        'modalities': {
          'input': ['text', 1],
          'output': ['text'],
        },
      }),
      throwsFormatException,
    );
  });

  test(
    'strict tool support requires a verified provider, model, and tools',
    () {
      for (final testCase in [
        (
          provider: 'openai',
          model: 'gpt-4o-2024-08-06',
          tools: true,
          strict: true,
        ),
        (
          provider: 'openai',
          model: 'gpt-4o-2024-08-06',
          tools: false,
          strict: false,
        ),
        (provider: 'openai', model: 'unknown', tools: true, strict: false),
        (
          provider: 'openrouter',
          model: 'gpt-4o-2024-08-06',
          tools: true,
          strict: false,
        ),
        (
          provider: 'custom',
          model: 'gpt-4o-2024-08-06',
          tools: true,
          strict: false,
        ),
      ]) {
        final model = ModelCapabilities.fromJson(testCase.provider, {
          'id': testCase.model,
          'name': testCase.model,
          'tool_call': testCase.tools,
          'structured_output': true,
          'limit': {'context': 1000, 'output': 100},
          'modalities': {
            'input': ['text'],
            'output': ['text'],
          },
        });
        expect(model.supportsStructuredOutput, isTrue);
        expect(model.supportsStrictToolSampling, testCase.strict);
      }
    },
  );

  test('resolves versioned strict profiles from exact provider tuples', () {
    for (final modelId in [
      'gpt-4o',
      'gpt-4o-2024-08-06',
      'gpt-4o-mini',
      'gpt-4o-mini-2024-07-18',
    ]) {
      expect(
        strictToolSamplingProfile(
          'openai',
          modelId,
          'https://api.openai.com/v1',
        ),
        isNotNull,
      );
    }
    expect(
      strictToolSamplingProfile(
        'openai',
        'gpt-4o',
        'https://api.openai.com/v1/',
      ),
      isNotNull,
    );

    final xai = strictToolSamplingProfile(
      'openai',
      'grok-4.7',
      'https://api.x.ai/v1',
    );
    expect(xai, isNotNull);
    expect(xai!.id, 'xai-grok-4.7-chat-completions-strict');
    expect(xai.version, 1);
    expect(xai.exactMatch, (
      providerId: 'openai',
      modelId: 'grok-4.7',
      baseUrl: 'https://api.x.ai/v1',
    ));
    expect(xai.wireMode, StrictToolSamplingWireMode.implicitStrict);
    expect(xai.schemaLimits.maxPropertiesConstraint, 64);
    expect(xai.schemaLimits.maxStringLength, 2048);
    expect(xai.schemaLimits.maxArrayItems, 256);
    expect(xai.evidenceUrl, contains('docs.x.ai'));
    expect(xai.verificationDate, '2026-09-29');

    expect(verifiedStrictToolSampling('openai', 'gpt-4o'), isTrue);
    expect(verifiedStrictToolSampling('openai', 'grok-4.7'), isFalse);
    for (final testCase in [
      (
        providerId: 'openai',
        modelId: 'grok-4.7',
        baseUrl: 'https://api.proxy.example/v1',
      ),
      (
        providerId: 'openai',
        modelId: 'grok-4.8',
        baseUrl: 'https://api.x.ai/v1',
      ),
      (providerId: 'openai', modelId: 'gpt-4o', baseUrl: 'https://api.x.ai/v1'),
      (
        providerId: 'openai',
        modelId: 'grok-4.7',
        baseUrl: 'https://api.openai.com/v1',
      ),
      (providerId: 'xai', modelId: 'grok-4.7', baseUrl: 'https://api.x.ai/v1'),
    ]) {
      expect(
        strictToolSamplingProfile(
          testCase.providerId,
          testCase.modelId,
          testCase.baseUrl,
        ),
        isNull,
      );
    }
  });

  test('strict profile limits reject constraints outside guarantees', () {
    final limits = strictToolSamplingProfile(
      'openai',
      'grok-4.7',
      'https://api.x.ai/v1',
    )!.schemaLimits;
    for (final schema in [
      {
        'type': 'object',
        'properties': <String, dynamic>{
          'value': {'type': 'string', 'maxLength': 2049},
        },
        'required': ['value'],
        'additionalProperties': false,
      },
      {
        'type': 'object',
        'properties': <String, dynamic>{
          'value': {
            'type': 'array',
            'items': {'type': 'string'},
            'maxItems': 257,
          },
        },
        'required': ['value'],
        'additionalProperties': false,
      },
      {
        'type': 'object',
        'properties': <String, dynamic>{
          'value': {'type': 'string'},
        },
        'required': ['value'],
        'additionalProperties': false,
        'maxProperties': 65,
      },
    ]) {
      expect(
        strictToolSchemaIssue(schema, limits: limits)?.reason,
        ToolSchemaIssueReason.providerLimit,
      );
    }
  });

  test('rejects malformed structured output capability clearly', () {
    expect(
      () => ModelCapabilities.fromJson('openai', {
        'id': 'gpt-5.5',
        'name': 'GPT-5.5',
        'structured_output': 'yes',
        'limit': {'context': 400000, 'output': 128000},
        'modalities': {
          'input': ['text'],
          'output': ['text'],
        },
      }),
      throwsFormatException,
    );
    expect(
      () => ModelCapabilities.fromJson('openai', {
        'id': 'gpt-4o-2024-08-06',
        'name': 'GPT-4o',
        'tool_call': 'yes',
        'limit': {'context': 400000, 'output': 128000},
        'modalities': {
          'input': ['text'],
          'output': ['text'],
        },
      }),
      throwsFormatException,
    );
  });

  test('requires priority mode for Codex runtime eligibility', () {
    final model = ModelCapabilities(
      id: 'gpt-5.5',
      name: 'GPT-5.5',
      limitContext: 400000,
      limitOutput: 128000,
      inputModalities: ['text'],
      outputModalities: ['text'],
    );

    expect(model.isCodexRuntimeModel, isFalse);
    expect(model.supportsStrictToolSampling, isFalse);
  });

  test('Codex eligibility is capability-based', () {
    const cases =
        <
          ({
            String name,
            String id,
            bool canonical,
            bool priority,
            List<String> input,
            List<String> output,
            int outputLimit,
            bool supportsTools,
            bool expected,
          })
        >[
          (
            name: 'priority text model',
            id: 'gpt-5.5',
            canonical: true,
            priority: true,
            input: ['text'],
            output: ['text'],
            outputLimit: 128000,
            supportsTools: false,
            expected: true,
          ),
          (
            name: 'different eligible runtime model',
            id: 'gpt-5.5-spark',
            canonical: false,
            priority: true,
            input: ['text'],
            output: ['text'],
            outputLimit: 128000,
            supportsTools: true,
            expected: true,
          ),
          (
            name: 'priority noncanonical alias',
            id: 'gpt-5.4-alias',
            canonical: false,
            priority: true,
            input: ['text'],
            output: ['text'],
            outputLimit: 128000,
            supportsTools: false,
            expected: true,
          ),
          (
            name: 'non-priority alias',
            id: 'gpt-5.1-codex',
            canonical: false,
            priority: false,
            input: ['text'],
            output: ['text'],
            outputLimit: 128000,
            supportsTools: true,
            expected: false,
          ),
          (
            name: 'missing text input',
            id: 'gpt-5.6-image',
            canonical: false,
            priority: true,
            input: ['image'],
            output: ['text'],
            outputLimit: 128000,
            supportsTools: true,
            expected: false,
          ),
          (
            name: 'no text output',
            id: 'gpt-5.7-embedding',
            canonical: false,
            priority: true,
            input: ['text'],
            output: ['embedding'],
            outputLimit: 128000,
            supportsTools: true,
            expected: false,
          ),
          (
            name: 'zero output limit',
            id: 'gpt-5.8-disabled',
            canonical: false,
            priority: true,
            input: ['text'],
            output: ['text'],
            outputLimit: 0,
            supportsTools: true,
            expected: false,
          ),
        ];

    for (final testCase in cases) {
      final model = ModelCapabilities(
        id: testCase.id,
        name: testCase.id,
        limitContext: 1000,
        limitOutput: testCase.outputLimit,
        inputModalities: testCase.input,
        outputModalities: testCase.output,
        isCanonical: testCase.canonical,
        supportsPriorityMode: testCase.priority,
        supportsToolCalls: testCase.supportsTools,
      );

      expect(
        model.isCodexRuntimeModel,
        testCase.expected,
        reason: testCase.name,
      );
    }
  });
}
