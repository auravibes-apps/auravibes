import 'package:auravibes_engine/src/context_window.dart';
import 'package:auravibes_engine/src/model_capabilities.dart';
import 'package:auravibes_engine/src/tool_calls.dart';
import 'package:auravibes_engine/src/transcript_context.dart';
import 'package:test/test.dart';

void main() {
  test('calculates latest cumulative usage and model limit', () {
    final usage = calculateContextWindowUsage(
      context: _context([_message(tokens: 20), _message(tokens: 80)]),
      model: _model(100),
    );
    expect(usage.usedTokens, 80);
    expect(usage.remainingTokens, 20);
    expect(usage.usagePercentage, 80);
    expect(usage.overflowTokens, 0);
    expect(usage.limitValidity, AgentContextLimitValidity.known);
  });

  test('fallback includes text, tool arguments, and tool results', () {
    final usage = calculateContextWindowUsage(
      context: _context([
        _message(
          textCharacters: 1,
          toolCalls: [
            const AgentTranscriptToolCallSnapshot(
              id: 'tool',
              lifecycle: AgentToolCallLifecycle.success,
              argumentCharacterCount: 6,
              resultCharacterCount: 6,
            ),
          ],
        ),
      ]),
      contextLimit: 10,
    );
    expect(usage.usedTokens, 4);
    expect(usage.remainingTokens, 6);
    expect(usage.usagePercentage, 40);
  });

  test('types unknown, invalid, and overflow limits', () {
    final context = _context([_message(tokens: 11)]);
    final unknown = calculateContextWindowUsage(context: context);
    final invalid = calculateContextWindowUsage(
      context: context,
      contextLimit: 0,
    );
    final overflow = calculateContextWindowUsage(
      context: context,
      contextLimit: 10,
    );
    expect(unknown.limitValidity, AgentContextLimitValidity.unknown);
    expect(unknown.remainingTokens, isNull);
    expect(invalid.limitValidity, AgentContextLimitValidity.invalid);
    expect(invalid.remainingTokens, -11);
    expect(invalid.usagePercentage, 0);
    expect(overflow.remainingTokens, -1);
    expect(overflow.overflowTokens, 1);
    expect(overflow.usagePercentage, closeTo(110, 0.000001));
  });

  test('blocks in-flight messages and model tool calls', () {
    expect(
      isContextSafeForCompaction(
        _context([_message(status: AgentTranscriptStatus.sending)]),
      ),
      isFalse,
    );
    expect(
      isContextSafeForCompaction(
        _context([
          _message(
            role: AgentTranscriptRole.model,
            toolCalls: [_pendingToolCall],
          ),
        ]),
      ),
      isFalse,
    );
    expect(
      isContextSafeForCompaction(
        _context([
          _message(toolCalls: [_pendingToolCall]),
        ]),
      ),
      isTrue,
    );
  });

  test('evaluates thresholds and exact default formula', () {
    final evaluation = evaluateContextCompaction(
      context: _context([_message(tokens: 70)]),
      contextLimit: 100,
      usagePercentageThreshold: 80,
      remainingTokenThreshold: 30,
    );
    expect(evaluation.meetsUsageThreshold, isFalse);
    expect(evaluation.meetsRemainingThreshold, isTrue);
    expect(evaluation.shouldCompact, isTrue);
    expect(
      defaultRemainingTokenThreshold(maxOutputTokens: 4096),
      2000,
    );
    expect(
      defaultRemainingTokenThreshold(
        maxOutputTokens: 4096,
        contextLimit: 10000,
      ),
      4096,
    );
    expect(
      defaultRemainingTokenThreshold(
        maxOutputTokens: 4096,
        contextLimit: 50000,
      ),
      10000,
    );
    expect(
      defaultRemainingTokenThreshold(
        maxOutputTokens: 4096,
        contextLimit: 128000,
      ),
      15000,
    );
  });
}

const _pendingToolCall = AgentTranscriptToolCallSnapshot(
  id: 'tool',
  lifecycle: AgentToolCallLifecycle.pending,
  argumentCharacterCount: 0,
  resultCharacterCount: 0,
);

AgentContextSnapshot _context(List<AgentTranscriptMessageSnapshot> messages) =>
    AgentContextSnapshot(messages);

AgentTranscriptMessageSnapshot _message({
  int? tokens,
  int textCharacters = 0,
  AgentTranscriptRole role = AgentTranscriptRole.user,
  AgentTranscriptStatus status = AgentTranscriptStatus.sent,
  List<AgentTranscriptToolCallSnapshot> toolCalls = const [],
}) => AgentTranscriptMessageSnapshot(
  id: 'message',
  role: role,
  kind: AgentTranscriptKind.text,
  status: status,
  textCharacterCount: textCharacters,
  toolCalls: toolCalls,
  latestCumulativeTokenCount: tokens,
  isCompactionSummary: false,
  compactedThroughMessageId: null,
  excludedMessageIds: const [],
);

ModelCapabilities _model(int contextLimit) => ModelCapabilities(
  id: 'model',
  name: 'Model',
  limitContext: contextLimit,
  limitOutput: 10,
  inputModalities: const ['text'],
  outputModalities: const ['text'],
);
