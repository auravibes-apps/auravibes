import 'dart:convert';
import 'dart:io';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_engine/src/agent_service.dart';
import 'package:auravibes_engine/src/agent_stream_service.dart';
import 'package:genkit/plugin.dart' show GenkitException;

import 'fake_cancellation_effects.dart';

enum _ReplayEventType { chunk, response, cancel, failure, toolResult }

enum _ReplayFailureCategory { rateLimit, unknown }

/// One versioned, provider-neutral scripted orchestration run.
class AgentRunReplayFixture({
  required final String scenario,
  required final List<_ReplayEvent> _events,
  required final AgentRunReplayExpectation expected,
}) {
  factory fromJson(Object? value, {required String sourceName}) {
    final root = _asStringMap(value, 'Fixture "$sourceName"');
    final scenarioValue = root['scenario'];
    final scenario = scenarioValue is String && scenarioValue.isNotEmpty
        ? scenarioValue
        : sourceName;
    final label = 'Fixture "$scenario"';

    if (root['schemaVersion'] is! int || root['schemaVersion'] != 1) {
      throw FormatException('$label has unsupported schemaVersion');
    }
    _checkKeys(root, const {
      'schemaVersion',
      'scenario',
      'events',
      'expected',
    }, label);
    if (scenarioValue is! String || scenarioValue.trim().isEmpty) {
      throw FormatException('$label requires a non-empty scenario');
    }

    final rawEvents = root['events'];
    if (rawEvents is! List || rawEvents.isEmpty) {
      throw FormatException('$label requires a non-empty events list');
    }

    final eventIds = <String>{};
    final toolCallIds = <String>{};
    final events = <_ReplayEvent>[];
    for (var index = 0; index < rawEvents.length; index++) {
      final rawEvent = rawEvents[index];
      final rawMap = rawEvent is Map ? rawEvent : null;
      final eventId = rawMap?['id'] is String ? rawMap!['id'] as String : null;
      final eventLabel = _eventLabel(scenario, index, eventId);
      try {
        final event = _ReplayEvent.fromJson(rawEvent, eventLabel);
        if (!eventIds.add(event.id)) {
          throw FormatException('duplicate event id "${event.id}"');
        }
        for (final call in event.toolCalls) {
          if (!toolCallIds.add(call.id)) {
            throw FormatException('duplicate tool call id "${call.id}"');
          }
        }
        events.add(event);
      } on FormatException catch (error) {
        throw FormatException('$eventLabel: ${error.message}');
      }
    }

    _validateEventOrder(scenario, events);
    final expected = AgentRunReplayExpectation.fromJson(
      root['expected'],
      label,
      events
          .where((event) => event.type == _ReplayEventType.toolResult)
          .map((event) => event.callId!)
          .toList(),
    );

    return AgentRunReplayFixture(
      scenario: scenario,
      events: List<_ReplayEvent>.unmodifiable(events),
      expected: expected,
    );
  }

  static void _validateEventOrder(String scenario, List<_ReplayEvent> events) {
    var responseOpen = false;
    var chunksInResponse = 0;
    var cancelled = false;
    final responseToolCalls = <String>[];
    final toolResultsToConsume = <String>[];

    for (var index = 0; index < events.length; index++) {
      final event = events[index];
      final label = _eventLabel(scenario, index, event.id);
      if (cancelled) {
        throw FormatException('$label follows a terminal cancellation event');
      }
      if (toolResultsToConsume.isNotEmpty &&
          event.type != _ReplayEventType.toolResult) {
        throw FormatException(
          '$label appears before tool result "${toolResultsToConsume.first}"',
        );
      }

      switch (event.type) {
        case _ReplayEventType.chunk:
          responseOpen = true;
          chunksInResponse++;
          responseToolCalls.addAll(event.toolCalls.map((call) => call.id));
        case _ReplayEventType.response:
          if (!responseOpen || chunksInResponse == 0) {
            throw FormatException('$label closes no provider response');
          }
          responseOpen = false;
          chunksInResponse = 0;
          toolResultsToConsume.addAll(responseToolCalls);
          responseToolCalls.clear();
        case _ReplayEventType.cancel:
          if (!responseOpen || chunksInResponse == 0) {
            throw FormatException('$label cancels no active provider response');
          }
          responseOpen = false;
          responseToolCalls.clear();
          cancelled = true;
          if (index != events.length - 1) {
            throw FormatException('$label must be the final fixture event');
          }
        case _ReplayEventType.failure:
          if (responseOpen) {
            throw FormatException(
              '$label must occur between provider responses '
              'in this fixture format',
            );
          }
        case _ReplayEventType.toolResult:
          if (responseOpen || toolResultsToConsume.isEmpty) {
            throw FormatException('$label has no preceding tool request');
          }
          final expectedCallId = toolResultsToConsume.removeAt(0);
          if (event.callId != expectedCallId) {
            throw FormatException(
              '$label resolves "${event.callId}"; '
              'expected "$expectedCallId"',
            );
          }
      }
    }

    if (responseOpen) {
      final last = events.last;
      throw FormatException(
        '${_eventLabel(scenario, events.length - 1, last.id)} leaves '
        'a provider response open',
      );
    }
    if (toolResultsToConsume.isNotEmpty) {
      throw FormatException(
        'Fixture "$scenario" is missing tool result '
        '"${toolResultsToConsume.first}"',
      );
    }
  }
}

/// Expected externally visible lifecycle and side-effect state for a fixture.
class AgentRunReplayExpectation({
  required final String? decision,
  required final String? errorType,
  required final List<String> eventOrder,
  required final List<Map<String, Object?>> assistantMessages,
  required final List<Map<String, Object?>> streamedOutput,
  required final List<Map<String, Object?>> toolDispatches,
  required final Map<String, Object?> toolResults,
  required final Map<String, int> toolSideEffectCounts,
  required final List<String> sentUserMessageIds,
  required final List<String> erroredUserMessageIds,
  required final List<String> retryEvents,
}) {
  factory fromJson(
    Object? value,
    String label,
    List<String> executedToolCallIds,
  ) {
    final json = _asStringMap(value, '$label.expected');
    _checkKeys(json, const {
      'decision',
      'errorType',
      'eventOrder',
      'assistantMessages',
      'streamedOutput',
      'toolDispatches',
      'toolResults',
      'toolSideEffectCounts',
      'sentUserMessageIds',
      'erroredUserMessageIds',
      'retryEvents',
    }, '$label.expected');

    final decision = json['decision'];
    if (decision != null &&
        (decision is! String ||
            !AgentIterationDecision.values.any(
              (item) => item.name == decision,
            ))) {
      throw FormatException('$label.expected.decision is invalid');
    }
    final errorType = json['errorType'];
    if (errorType != null && (errorType is! String || errorType.isEmpty)) {
      throw FormatException('$label.expected.errorType is invalid');
    }
    if ((decision == null) != (errorType != null)) {
      throw FormatException(
        '$label.expected must declare either a decision or an errorType',
      );
    }

    final assistantMessages = _readMapList(
      json['assistantMessages'],
      '$label.expected.assistantMessages',
    );
    for (var index = 0; index < assistantMessages.length; index++) {
      final item = assistantMessages[index];
      _checkKeys(item, const {
        'id',
        'text',
        'status',
      }, '$label.expected.assistantMessages[$index]');
      if (item['id'] is! String ||
          item['text'] is! String ||
          !const {'completed', 'stopped', 'errored'}.contains(item['status'])) {
        throw FormatException(
          '$label.expected.assistantMessages[$index] requires text and '
          'a valid status',
        );
      }
    }

    final streamedOutput = _readMapList(
      json['streamedOutput'],
      '$label.expected.streamedOutput',
    );
    for (var index = 0; index < streamedOutput.length; index++) {
      final item = streamedOutput[index];
      _checkKeys(item, const {
        'eventId',
        'text',
      }, '$label.expected.streamedOutput[$index]');
      if (item['eventId'] is! String || item['text'] is! String) {
        throw FormatException(
          '$label.expected.streamedOutput[$index] requires eventId and text',
        );
      }
    }

    final toolDispatches = _readMapList(
      json['toolDispatches'],
      '$label.expected.toolDispatches',
    );
    final expectedDispatchIds = <String>[];
    for (var index = 0; index < toolDispatches.length; index++) {
      final item = toolDispatches[index];
      _checkKeys(item, const {
        'id',
        'name',
        'arguments',
      }, '$label.expected.toolDispatches[$index]');
      if (item['id'] is! String ||
          item['name'] is! String ||
          item['arguments'] is! Map) {
        throw FormatException(
          '$label.expected.toolDispatches[$index] requires id, name, '
          'and object arguments',
        );
      }
      expectedDispatchIds.add(item['id']! as String);
    }

    final toolResults = _readOptionalValueMap(
      json['toolResults'],
      '$label.expected.toolResults',
    );
    final sideEffects = _readIntMap(
      json['toolSideEffectCounts'],
      '$label.expected.toolSideEffectCounts',
    );
    if (!_listEquals(expectedDispatchIds, executedToolCallIds) ||
        !_setEquals(toolResults.keys.toSet(), executedToolCallIds.toSet()) ||
        !_setEquals(sideEffects.keys.toSet(), executedToolCallIds.toSet()) ||
        sideEffects.values.any((count) => count != 1)) {
      throw FormatException(
        '$label.expected tool dispatches, results, and exactly-once '
        'counts must match fixture calls',
      );
    }

    return AgentRunReplayExpectation(
      decision: decision as String?,
      errorType: errorType as String?,
      eventOrder: _readStringList(
        json['eventOrder'],
        '$label.expected.eventOrder',
      ),
      assistantMessages: List.unmodifiable(assistantMessages),
      streamedOutput: List.unmodifiable(streamedOutput),
      toolDispatches: List.unmodifiable(toolDispatches),
      toolResults: Map.unmodifiable(toolResults),
      toolSideEffectCounts: Map.unmodifiable(sideEffects),
      sentUserMessageIds: _readStringList(
        json['sentUserMessageIds'],
        '$label.expected.sentUserMessageIds',
      ),
      erroredUserMessageIds: _readStringList(
        json['erroredUserMessageIds'],
        '$label.expected.erroredUserMessageIds',
      ),
      retryEvents: _readStringList(
        json['retryEvents'],
        '$label.expected.retryEvents',
      ),
    );
  }

  Map<String, Object?> toJson() => {
    'decision': decision,
    'errorType': errorType,
    'eventOrder': eventOrder,
    'assistantMessages': assistantMessages,
    'streamedOutput': streamedOutput,
    'toolDispatches': toolDispatches,
    'toolResults': toolResults,
    'toolSideEffectCounts': toolSideEffectCounts,
    'sentUserMessageIds': sentUserMessageIds,
    'erroredUserMessageIds': erroredUserMessageIds,
    'retryEvents': retryEvents,
  };
}

/// Runs a fixture through the production engine turn and stream services.
class AgentRunReplayHarness(final AgentRunReplayFixture fixture) {
  Future<AgentRunReplayResult> replay() async {
    final trace = <String>[];
    final cursor = _ReplayEventCursor(fixture);
    final cancellation = FakeCancellationEffects();
    final data = _ReplayDataProvider();
    final streamProvider = _ReplayStreamProvider(data);
    final streamService = AgentStreamService<_ReplayChunk>(
      cancellationEffects: cancellation,
      provider: streamProvider,
    );
    final models = _ReplayModelProvider(
      cursor: cursor,
      cancellation: cancellation,
      streamService: streamService,
      streamProvider: streamProvider,
      trace: trace,
    );
    final tools = _ReplayLoopTools(cursor, models, trace);
    var currentTime = DateTime.utc(2026);
    final retryEvents = <String>[];
    final agent = AgentService(
      data: data,
      models: models,
      tools: tools,
      sendQueueRuntime: const _ReplaySendQueue(),
      cancellationEffects: cancellation,
      rateLimitRetryRuntime: AgentRateLimitRetryRuntime(
        start: (conversationId, retryAt) {
          final delay = retryAt.difference(currentTime).inMilliseconds;
          retryEvents.add('start:$delay');
          trace.add('retry-start:$delay');
        },
        clear: (_) {
          retryEvents.add('clear');
          trace.add('retry-clear');
        },
      ),
      now: () => currentTime,
      sleep: (duration) async {
        final millis = duration.inMilliseconds;
        trace.add('retry-sleep:$millis');
        currentTime = currentTime.add(duration);
      },
    );

    AgentIterationDecision? decision;
    Object? runError;
    try {
      decision = await agent(
        conversationId: 'conversation-1',
        context: const AgentIterationContext(
          origin: AgentIterationOrigin.userMessage,
          ackMessageIds: ['user-1'],
        ),
      );
    } on Object catch (error) {
      runError = error;
    }

    return AgentRunReplayResult(
      decision: decision?.name,
      errorType: runError?.runtimeType.toString(),
      eventOrder: List.unmodifiable(trace),
      assistantMessages: List.unmodifiable(streamProvider.assistantMessages),
      streamedOutput: List.unmodifiable(streamProvider.streamedOutput),
      toolDispatches: List.unmodifiable(tools.dispatches),
      toolResults: Map.unmodifiable(tools.results),
      toolSideEffectCounts: Map.unmodifiable(tools.sideEffectCounts),
      sentUserMessageIds: List.unmodifiable(data.sentUserMessageIds),
      erroredUserMessageIds: List.unmodifiable(data.erroredUserMessageIds),
      retryEvents: List.unmodifiable(retryEvents),
    );
  }
}

class const AgentRunReplayResult({
  required final String? decision,
  required final String? errorType,
  required final List<String> eventOrder,
  required final List<Map<String, Object?>> assistantMessages,
  required final List<Map<String, Object?>> streamedOutput,
  required final List<Map<String, Object?>> toolDispatches,
  required final Map<String, Object?> toolResults,
  required final Map<String, int> toolSideEffectCounts,
  required final List<String> sentUserMessageIds,
  required final List<String> erroredUserMessageIds,
  required final List<String> retryEvents,
}) {
  Map<String, Object?> toJson() => {
    'decision': decision,
    'errorType': errorType,
    'eventOrder': eventOrder,
    'assistantMessages': assistantMessages,
    'streamedOutput': streamedOutput,
    'toolDispatches': toolDispatches,
    'toolResults': toolResults,
    'toolSideEffectCounts': toolSideEffectCounts,
    'sentUserMessageIds': sentUserMessageIds,
    'erroredUserMessageIds': erroredUserMessageIds,
    'retryEvents': retryEvents,
  };
}

class _ReplayModelProvider({
  required final _ReplayEventCursor cursor,
  required final FakeCancellationEffects cancellation,
  required final AgentStreamService<_ReplayChunk> streamService,
  required final _ReplayStreamProvider streamProvider,
  required final List<String> trace,
}) implements AgentModelProvider {
  int _requestCount = 0;
  List<_ReplayToolCall> _lastToolCalls = const [];

  List<_ReplayToolCall> takeToolCalls() {
    final calls = _lastToolCalls;
    _lastToolCalls = const [];
    return calls;
  }

  @override
  Future<ContinueAgentResult> continueAgent({
    required String conversationId,
    AgentIterationContext? context,
  }) async {
    _requestCount++;
    trace.add('request:$_requestCount');
    final first = cursor.take();
    if (first.type == _ReplayEventType.failure) {
      trace.add('failure:${first.id}');
      _throwFailure(first);
    }
    if (first.type != _ReplayEventType.chunk) {
      throw cursor.diverged(
        first,
        'provider request expected a chunk or failure',
      );
    }

    streamProvider.resetResponse();
    final response = await streamService.call(
      conversationId: conversationId,
      responseStream: _responseEvents(first, conversationId),
      pendingUserMessageIds: context?.ackMessageIds ?? const [],
    );
    _lastToolCalls = response.hasToolCalls
        ? List.unmodifiable(streamProvider.currentToolCalls)
        : const [];

    return response;
  }

  Stream<_ReplayChunk> _responseEvents(
    _ReplayEvent first,
    String conversationId,
  ) async* {
    var event = first;
    while (true) {
      switch (event.type) {
        case _ReplayEventType.chunk:
          trace.add('chunk:${event.id}');
          yield _ReplayChunk(
            text: event.text!,
            toolCalls: event.toolCalls,
            eventIds: [event.id],
          );
          event = cursor.take();
        case _ReplayEventType.response:
          trace.add('complete:${event.id}');
          return;
        case _ReplayEventType.cancel:
          trace.add('cancel:${event.id}');
          cancellation.requestStop(conversationId);
          return;
        case _ReplayEventType.failure:
          trace.add('failure:${event.id}');
          _throwFailure(event);
        case _ReplayEventType.toolResult:
          throw cursor.diverged(
            event,
            'provider response ended before tool results',
          );
      }
    }
  }

  Never _throwFailure(_ReplayEvent event) {
    if (event.failureCategory == _ReplayFailureCategory.rateLimit) {
      throw AgentRateLimitRetryException(
        providerException: GenkitException(
          'Synthetic fixture rate limit.',
          status: .resourceExhausted,
        ),
        retryAfter: Duration(milliseconds: event.retryAfterMs!),
      );
    }

    throw StateError('Synthetic non-retryable fixture failure.');
  }
}

class _ReplayLoopTools(
  final _ReplayEventCursor cursor,
  final _ReplayModelProvider models,
  final List<String> trace,
) implements AgentLoopToolProvider {
  final dispatches = <Map<String, Object?>>[];
  final results = <String, Object?>{};
  final sideEffectCounts = <String, int>{};

  @override
  Future<AgentIterationDecision> runAllowedTools({
    required String conversationId,
    required String workspaceId,
  }) async {
    final calls = models.takeToolCalls();
    if (calls.isEmpty) {
      throw StateError('Replay requested tool execution without tool calls.');
    }

    for (final call in calls) {
      if (sideEffectCounts.containsKey(call.id)) {
        throw cursor.diverged(
          cursor.peek,
          'tool "${call.id}" would execute a duplicate side effect',
        );
      }
      trace.add('dispatch:${call.id}');
      dispatches.add(call.toJson());
      sideEffectCounts[call.id] = 1;
      trace.add('effect:${call.id}');

      final resultEvent = cursor.take();
      if (resultEvent.type != _ReplayEventType.toolResult ||
          resultEvent.callId != call.id) {
        throw cursor.diverged(
          resultEvent,
          'expected the result for tool "${call.id}"',
        );
      }

      trace.add('result:${resultEvent.id}');
      results[call.id] = resultEvent.value;
    }

    return AgentIterationDecision.continueIteration;
  }
}

class _ReplayStreamProvider(final _ReplayDataProvider data)
    implements AgentStreamProvider<_ReplayChunk> {
  final assistantMessages = <Map<String, Object?>>[];
  final streamedOutput = <Map<String, Object?>>[];
  final currentToolCalls = <_ReplayToolCall>[];
  int _assistantCount = 0;

  void resetResponse() {
    currentToolCalls.clear();
  }

  @override
  void startConversationStreaming(String conversationId) {}

  @override
  void removeConversationStreaming(String conversationId) {}

  @override
  AgentChunkSink<_ReplayChunk> createPersistenceSink(
    CurrentAgentMessageId currentMessageId,
  ) => _ReplayChunkSink((_) {});

  @override
  AgentChunkSink<_ReplayChunk> createUiStreamingSink(String messageId) =>
      _ReplayChunkSink((chunk) {
        streamedOutput.add({
          'eventId': chunk.eventIds.last,
          'text': chunk.text,
        });
      });

  @override
  Future<String> createAssistantMessage({
    required String conversationId,
    required _ReplayChunk chunk,
  }) async {
    _assistantCount++;
    final messageId = 'assistant-$_assistantCount';
    assistantMessages.add({
      'id': messageId,
      'text': chunk.text,
      'status': 'streaming',
    });
    return messageId;
  }

  @override
  Future<void> startMessageStreaming(String messageId) async {}

  @override
  Future<void> removeMessageStreaming(String messageId) async {}

  @override
  Future<void> markPendingUsersSent(List<String> messageIds) =>
      data.markMessagesSent(messageIds);

  @override
  Future<void> markPendingUsersErrored(List<String> messageIds) =>
      data.markMessagesErrored(messageIds);

  @override
  Future<void> persistStoppedAssistantMessage(
    String? messageId,
    _ReplayChunk? result,
  ) async {
    if (messageId == null) return;
    _updateAssistantMessage(
      messageId,
      text: result?.text ?? '',
      status: 'stopped',
    );
  }

  @override
  Future<void> persistCompletedAssistantMessage(
    String messageId,
    _ReplayChunk result,
  ) async {
    _updateAssistantMessage(messageId, text: result.text, status: 'completed');
  }

  @override
  Future<void> markAssistantErrored(String messageId) async {
    _updateAssistantMessage(messageId, text: '', status: 'errored');
  }

  @override
  _ReplayChunk concatChunks(_ReplayChunk current, _ReplayChunk delta) {
    currentToolCalls
      ..clear()
      ..addAll(current.toolCalls)
      ..addAll(delta.toolCalls);
    return _ReplayChunk(
      text: current.text + delta.text,
      toolCalls: [...current.toolCalls, ...delta.toolCalls],
      eventIds: [...current.eventIds, ...delta.eventIds],
    );
  }

  @override
  bool shouldCreateAssistantMessage(_ReplayChunk chunk) {
    currentToolCalls
      ..clear()
      ..addAll(chunk.toolCalls);

    return chunk.text.isNotEmpty || chunk.toolCalls.isNotEmpty;
  }

  @override
  bool hasToolCalls(_ReplayChunk chunk) => chunk.toolCalls.isNotEmpty;

  @override
  void trackResponseStreamError(Object error, StackTrace stackTrace) {}

  @override
  void trackCancellationStreamError(Object error, StackTrace stackTrace) {}

  void _updateAssistantMessage(
    String messageId, {
    required String text,
    required String status,
  }) {
    final index = int.parse(messageId.substring('assistant-'.length)) - 1;
    assistantMessages[index] = {
      'id': messageId,
      'text': text,
      'status': status,
    };
  }
}

class _ReplayDataProvider implements AgentDataProvider {
  final sentUserMessageIds = <String>[];
  final erroredUserMessageIds = <String>[];

  @override
  Future<String?> getWorkspaceId(String conversationId) async => 'workspace-1';

  @override
  Future<List<AgentConversationMessage>> getMessages(String conversationId) {
    throw StateError('Replay must not load persisted conversation messages.');
  }

  @override
  Future<AgentCreatedMessage> createQueuedUserMessage({
    required String conversationId,
    required String content,
    Object? payload,
  }) async => const AgentCreatedMessage(id: 'unused-queue-message');

  @override
  Future<void> markMessagesSent(List<String> messageIds) async {
    for (final id in messageIds) {
      if (erroredUserMessageIds.contains(id)) continue;
      if (!sentUserMessageIds.contains(id)) sentUserMessageIds.add(id);
    }
  }

  @override
  Future<void> markMessagesErrored(List<String> messageIds) async {
    for (final id in messageIds) {
      if (!erroredUserMessageIds.contains(id)) erroredUserMessageIds.add(id);
      sentUserMessageIds.remove(id);
    }
  }

  @override
  Future<void> autoCompactConversation({
    required String conversationId,
  }) async {}

  @override
  Future<void> stopLatestPendingTools(String conversationId) async {}
}

class const _ReplaySendQueue() implements AgentSendQueueRuntime {
  @override
  List<AgentQueuedDraft> dequeueAll(String conversationId) => const [];

  @override
  void clear(String conversationId) {}
}

class _ReplayChunkSink(final void Function(_ReplayChunk chunk) onAdd)
    implements AgentChunkSink<_ReplayChunk> {
  @override
  void add(_ReplayChunk chunk) => onAdd(chunk);

  @override
  Future<void> close() async {}
}

class const _ReplayChunk({
  required final String text,
  required final List<String> eventIds,
  final List<_ReplayToolCall> toolCalls = const [],
});

class _ReplayToolCall({
  required final String id,
  required final String name,
  required final Map<String, Object?> arguments,
}) {
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'arguments': arguments,
  };
}

class const _ReplayEvent({
  required final _ReplayEventType type,
  required final String id,
  final String? text,
  final List<_ReplayToolCall> toolCalls = const [],
  final String? callId,
  final Object? value,
  final _ReplayFailureCategory? failureCategory,
  final int? retryAfterMs,
}) {
  factory fromJson(Object? value, String label) {
    final json = _asStringMap(value, label);
    final typeValue = json['type'];
    final idValue = json['id'];
    if (typeValue is! String || idValue is! String || idValue.trim().isEmpty) {
      throw const FormatException('requires non-empty type and id strings');
    }

    final type = switch (typeValue) {
      'chunk' => _ReplayEventType.chunk,
      'response' => _ReplayEventType.response,
      'cancel' => _ReplayEventType.cancel,
      'failure' => _ReplayEventType.failure,
      'toolResult' => _ReplayEventType.toolResult,
      _ => throw FormatException('unknown event type "$typeValue"'),
    };
    switch (type) {
      case _ReplayEventType.chunk:
        _checkKeys(json, const {'type', 'id', 'text', 'toolCalls'}, label);
        final text = json['text'];
        if (text is! String) {
          throw const FormatException('chunk text must be a string');
        }
        final calls = <_ReplayToolCall>[];
        final rawCalls = json['toolCalls'] ?? const <Object?>[];
        if (rawCalls is! List) {
          throw const FormatException('chunk toolCalls must be a list');
        }
        for (var index = 0; index < rawCalls.length; index++) {
          final rawCall = _asStringMap(
            rawCalls[index],
            '$label.toolCalls[$index]',
          );
          _checkKeys(rawCall, const {
            'id',
            'name',
            'arguments',
          }, '$label.toolCalls[$index]');
          final callId = rawCall['id'];
          final name = rawCall['name'];
          final rawArguments = rawCall['arguments'];
          if (callId is! String ||
              callId.trim().isEmpty ||
              name is! String ||
              name.trim().isEmpty ||
              rawArguments is! Map) {
            throw FormatException('$label.toolCalls[$index] is invalid');
          }
          calls.add(
            _ReplayToolCall(
              id: callId,
              name: name,
              arguments: _asStringMap(
                rawArguments,
                '$label.toolCalls[$index].arguments',
              ),
            ),
          );
        }
        if (text.isEmpty && calls.isEmpty) {
          throw const FormatException(
            'chunk needs text or at least one tool call',
          );
        }

        return _ReplayEvent(
          type: type,
          id: idValue,
          text: text,
          toolCalls: calls,
        );
      case _ReplayEventType.response || _ReplayEventType.cancel:
        _checkKeys(json, const {'type', 'id'}, label);
        return _ReplayEvent(type: type, id: idValue);
      case _ReplayEventType.failure:
        _checkKeys(json, const {
          'type',
          'id',
          'category',
          'retryAfterMs',
        }, label);
        final categoryValue = json['category'];
        final category = switch (categoryValue) {
          'rateLimit' => _ReplayFailureCategory.rateLimit,
          'unknown' => _ReplayFailureCategory.unknown,
          _ => throw const FormatException(
            'failure category must be rateLimit or unknown',
          ),
        };
        final retryAfterMs = json['retryAfterMs'];
        if (category == _ReplayFailureCategory.rateLimit &&
            (retryAfterMs is! int || retryAfterMs <= 0)) {
          throw const FormatException(
            'rateLimit failure requires positive retryAfterMs',
          );
        }
        if (category == _ReplayFailureCategory.unknown &&
            retryAfterMs != null) {
          throw const FormatException(
            'unknown failure cannot have retryAfterMs',
          );
        }

        return _ReplayEvent(
          type: type,
          id: idValue,
          failureCategory: category,
          retryAfterMs: retryAfterMs as int?,
        );
      case _ReplayEventType.toolResult:
        _checkKeys(json, const {'type', 'id', 'callId', 'value'}, label);
        final callId = json['callId'];
        if (callId is! String ||
            callId.trim().isEmpty ||
            !json.containsKey('value')) {
          throw const FormatException('toolResult requires callId and value');
        }

        return _ReplayEvent(
          type: type,
          id: idValue,
          callId: callId,
          value: json['value'],
        );
    }
  }
}

class _ReplayEventCursor(final AgentRunReplayFixture fixture) {
  int _index = 0;

  _ReplayEvent get peek => _index < fixture._events.length
      ? fixture._events[_index]
      : const _ReplayEvent(
          type: _ReplayEventType.response,
          id: '<end-of-fixture>',
        );

  _ReplayEvent take() {
    if (_index >= fixture._events.length) {
      throw FormatException(
        'Scenario "${fixture.scenario}" diverged at event[$_index]: '
        'fixture ended early',
      );
    }

    return fixture._events[_index++];
  }

  FormatException diverged(_ReplayEvent event, String message) {
    final index = _index == 0 ? 0 : _index - 1;
    return FormatException(
      '${_eventLabel(fixture.scenario, index, event.id)}: $message',
    );
  }
}

Map<String, Object?> _asStringMap(Object? value, String label) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$label must be an object with string keys');
  }

  return Map<String, Object?>.from(value);
}

void _checkKeys(Map<String, Object?> value, Set<String> allowed, String label) {
  final unexpected = value.keys.where((key) => !allowed.contains(key)).toList();
  if (unexpected.isNotEmpty) {
    throw FormatException('$label has unknown field "${unexpected.first}"');
  }
}

String _eventLabel(String scenario, int index, String? id) =>
    'Fixture "$scenario" event[$index]${id == null ? '' : ' "$id"'}';

List<String> _readStringList(Object? value, String label) {
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$label must be a string list');
  }

  return value.cast<String>();
}

List<Map<String, Object?>> _readMapList(Object? value, String label) {
  if (value is! List) throw FormatException('$label must be a list');

  return [
    for (var index = 0; index < value.length; index++)
      _asStringMap(value[index], '$label[$index]'),
  ];
}

Map<String, Object?> _readOptionalValueMap(Object? value, String label) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$label must be an object with string keys');
  }

  return Map<String, Object?>.from(value);
}

Map<String, int> _readIntMap(Object? value, String label) {
  if (value is! Map ||
      value.keys.any((key) => key is! String) ||
      value.values.any((item) => item is! int || item < 0)) {
    throw FormatException(
      '$label must map string keys to non-negative integers',
    );
  }

  return value.cast<String, int>();
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

bool _setEquals<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);

List<AgentRunReplayFixture> loadAgentRunReplayFixtures({
  String fixtureDirectory = 'test/fixtures/agent_run_replay',
}) {
  final directory = Directory(fixtureDirectory);
  if (!directory.existsSync()) {
    throw StateError(
      'Replay fixture directory does not exist: $fixtureDirectory',
    );
  }
  final files =
      directory
          .listSync()
          .where((entry) => entry is File && entry.path.endsWith('.json'))
          .cast<File>()
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  return [
    for (final file in files)
      AgentRunReplayFixture.fromJson(
        jsonDecode(file.readAsStringSync()),
        sourceName: file.uri.pathSegments.last,
      ),
  ];
}
