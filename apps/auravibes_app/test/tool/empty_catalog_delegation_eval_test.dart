import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart';

import 'empty_catalog_delegation_eval.dart';

void main() {
  group('empty catalog delegation eval', () {
    test('parses provider and model cases', () {
      expect(
        parseEmptyCatalogEvalCases([
          'openai:gpt-4o-mini',
          'anthropic:claude-sonnet-4-5',
          'openrouter:openai/gpt-4o-mini',
        ]),
        [
          (provider: 'openai', model: 'gpt-4o-mini'),
          (provider: 'anthropic', model: 'claude-sonnet-4-5'),
          (provider: 'openrouter', model: 'openai/gpt-4o-mini'),
        ],
      );
    });

    test('rejects malformed and unsupported provider cases', () {
      expect(
        () => parseEmptyCatalogEvalCases(['openai']),
        throwsFormatException,
      );
      expect(
        () => parseEmptyCatalogEvalCases(['google:gemini-2.5-pro']),
        throwsFormatException,
      );
    });

    test(
      'lists empty catalog, runs generic child, and verifies result',
      () async {
        final turns = <({List<ChatMessage> history, List<ToolSpec> tools})>[];
        ({String title, String prompt, String? agentId})? childRequest;
        final result = await runEmptyCatalogDelegationEval(
          provider: 'openai',
          model: 'gpt-4o-mini',
          generate: (history, tools) async {
            turns.add((history: history, tools: tools));

            return switch (turns.length) {
              1 => _modelToolCall(
                ref: 'list-1',
                name: listAgentsToolName,
                input: const {},
              ),
              2 => _modelToolCall(
                ref: 'run-1',
                name: runSubAgentToolName,
                input: const {
                  'title': 'Find answer',
                  'prompt': 'Return the eval marker.',
                  'agentId': null,
                },
              ),
              _ => ChatMessage.model('AURAVIBES_EVAL_CHILD_RESULT'),
            };
          },
          runStubChild: ({required title, required prompt, required agentId}) {
            childRequest = (title: title, prompt: prompt, agentId: agentId);

            return Future.value('AURAVIBES_EVAL_CHILD_RESULT');
          },
        );

        expect(result.passed, isTrue);
        expect(result.provider, 'openai');
        expect(result.model, 'gpt-4o-mini');
        expect(childRequest, (
          title: 'Find answer',
          prompt: 'Return the eval marker.',
          agentId: null,
        ));
        expect(turns, hasLength(3));
        final firstTurn =
            turns.firstOrNull ?? (throw StateError('No first model turn.'));
        expect(firstTurn.tools.map((tool) => tool.name), [
          listAgentsToolName,
          runSubAgentToolName,
        ]);
        final userMessage =
            firstTurn.history.firstOrNull ??
            (throw StateError('Model request has no user message.'));
        expect(userMessage.role, ChatMessageRole.user);
        expect(userMessage.content, contains('delegate'));
        expect(
          (turns.elementAt(1).history.last.parts.single as ToolResponsePart)
              .toolResponse
              .output,
          contains('"agents":[]'),
        );
        expect(
          (turns.elementAt(2).history.last.parts.single as ToolResponsePart)
              .toolResponse
              .output,
          contains('AURAVIBES_EVAL_CHILD_RESULT'),
        );

        final runSpec = firstTurn.tools.last;
        final schema = runSpec.inputJsonSchema;
        final rawProperties = schema['properties'];
        if (rawProperties is! Map<String, Object?>) {
          fail('run_sub_agent has no object properties.');
        }
        final agentIdSchema = rawProperties['agentId'];
        if (agentIdSchema is! Map<String, Object?>) {
          fail('run_sub_agent has no agentId property.');
        }
        expect(schema['required'], ['title', 'prompt', 'agentId']);
        expect(agentIdSchema['type'], ['string', 'null']);
      },
    );

    test('fails when model refuses after empty catalog result', () async {
      var turn = 0;
      final result = await runEmptyCatalogDelegationEval(
        provider: 'anthropic',
        model: 'claude-sonnet-4-5',
        generate: (_, _) async {
          turn++;
          if (turn == 1) {
            return _modelToolCall(
              ref: 'list-1',
              name: listAgentsToolName,
              input: const {},
            );
          }

          return ChatMessage.model('No agents are configured.');
        },
        runStubChild: ({required title, required prompt, required agentId}) =>
            Future.value('AURAVIBES_EVAL_CHILD_RESULT'),
      );

      expect(result.passed, isFalse);
      expect(result.failureReason, contains('did not call run_sub_agent'));
    });

    test('fails when generic request omits required null agentId', () async {
      var turn = 0;
      var childStarted = false;
      final result = await runEmptyCatalogDelegationEval(
        provider: 'openrouter',
        model: 'openai/gpt-4o-mini',
        generate: (_, _) async {
          turn++;
          if (turn == 1) {
            return _modelToolCall(
              ref: 'list-1',
              name: listAgentsToolName,
              input: const {},
            );
          }

          return _modelToolCall(
            ref: 'run-1',
            name: runSubAgentToolName,
            input: const {'title': 'Find answer', 'prompt': 'Do it.'},
          );
        },
        runStubChild: ({required title, required prompt, required agentId}) {
          childStarted = true;

          return Future.value('AURAVIBES_EVAL_CHILD_RESULT');
        },
      );

      expect(result.passed, isFalse);
      expect(result.failureReason, contains('agentId: null'));
      expect(childStarted, isFalse);
    });

    test(
      'fails when the final answer does not include the child result',
      () async {
        var turn = 0;
        final result = await runEmptyCatalogDelegationEval(
          provider: 'openai',
          model: 'gpt-4o-mini',
          generate: (_, _) async {
            turn++;
            if (turn == 1) {
              return _modelToolCall(
                ref: 'list-1',
                name: listAgentsToolName,
                input: const {},
              );
            }
            if (turn == 2) {
              return _modelToolCall(
                ref: 'run-1',
                name: runSubAgentToolName,
                input: const {
                  'title': 'Find answer',
                  'prompt': 'Do it.',
                  'agentId': null,
                },
              );
            }

            return ChatMessage.model('The child result was unavailable.');
          },
          runStubChild: ({required title, required prompt, required agentId}) =>
              Future.value('AURAVIBES_EVAL_CHILD_RESULT'),
        );

        expect(result.passed, isFalse);
        expect(
          result.failureReason,
          contains('did not include the child result'),
        );
      },
    );
  });
}

ChatMessage _modelToolCall({
  required String ref,
  required String name,
  required Map<String, dynamic> input,
}) => ChatMessage.model(
  '',
  parts: [
    ToolRequestPart(
      toolRequest: .new(ref: ref, name: name, input: input),
    ),
  ],
);
