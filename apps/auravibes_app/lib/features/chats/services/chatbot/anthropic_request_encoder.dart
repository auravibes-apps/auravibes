import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as sdk;
import 'package:auravibes_app/features/chats/services/chatbot/anthropic_message_codec.dart';
import 'package:auravibes_app/features/chats/services/chatbot/anthropic_request_exception.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:genkit/genkit.dart';

export 'anthropic_request_exception.dart';

typedef AnthropicEncodedRequest = ({
  sdk.MessageCreateRequest request,
  List<String> betas,
});
typedef _Projection = ({
  List<Message> messages,
  List<Map<String, dynamic>> tools,
  bool hasDeltas,
});
typedef _WireMessages = ({
  List<sdk.InputMessage> messages,
  List<String> leading,
});
typedef _UpdatesAfterMessageRequest = ({
  List<Message> history,
  int index,
  List<Message> messages,
  Map<String, ToolSpec> seen,
  Set<AgentTranscriptContextEntry> applied,
});

class const AnthropicRequestEncoder({
  final bool supportsPromptCacheMarkers = false,
  final bool supportsMidConversationSystemMessages = false,
  final bool supportsToolDeltas = false,
  final List<AgentTranscriptContextEntry> entries = const [],
}) {
  AnthropicEncodedRequest encode(String model, ModelRequest request) {
    try {
      return _encode(model, request);
    } on AgentTranscriptContextException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const AnthropicRequestException('invalid_transcript_context'),
        stackTrace,
      );
    } on FormatException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const AnthropicRequestException('invalid_request'),
        stackTrace,
      );
    }
  }

  AnthropicEncodedRequest _encode(String model, ModelRequest request) {
    final projection = _project(request);
    final wire = _wireMessages(projection.messages);
    _validatePlacement(wire.messages);

    return (
      request: sdk.MessageCreateRequest.fromJson(
        _requestBody(model, request, projection, wire),
      ),
      betas: projection.hasDeltas
          ? const ['inline-tools-2026-09-15']
          : const [],
    );
  }

  Map<String, dynamic> _requestBody(
    String model,
    ModelRequest request,
    _Projection projection,
    _WireMessages wire,
  ) => {
    'model': model,
    ..._generationOptions(request),
    if (projection.tools.isNotEmpty) 'tools': projection.tools,
    if (wire.leading.isNotEmpty) 'system': wire.leading.join('\n'),
    'messages': wire.messages.map((message) => message.toJson()).toList(),
    if (supportsPromptCacheMarkers) 'cache_control': {'type': 'ephemeral'},
  };

  _WireMessages _wireMessages(List<Message> source) {
    final wire = (messages: <sdk.InputMessage>[], leading: <String>[]);
    for (final message in source) {
      _appendWireMessage(message, wire);
    }

    return wire;
  }

  void _appendWireMessage(Message message, _WireMessages wire) =>
      _appendSafeWireMessage(_safeMessage(message), wire);

  void _appendSafeWireMessage(Message safeMessage, _WireMessages wire) {
    if (safeMessage.role != Role.system) {
      wire.messages.add(AnthropicMessageCodec.encode(safeMessage));
    } else if (_isLeading(safeMessage, wire.messages)) {
      wire.leading.add(_text(safeMessage));
    } else {
      wire.messages.add(
        sdk.InputMessage.systemBlocks(_systemBlocks(safeMessage)),
      );
    }
  }

  bool _isLeading(Message message, List<sdk.InputMessage> messages) =>
      messages.isEmpty ||
      (!supportsMidConversationSystemMessages &&
          _changes(message, enabled: supportsToolDeltas).isEmpty);

  List<sdk.InputContentBlock> _systemBlocks(Message message) => [
    if (supportsMidConversationSystemMessages && _text(message).isNotEmpty)
      sdk.TextInputBlock(_text(message)),
    ..._changes(message, enabled: supportsToolDeltas),
  ];
}

Message _safeMessage(Message message) => _systemRoleIsAllowed(message)
    ? message
    : Message(
        role: .user,
        content: message.content,
        metadata: message.metadata,
      );

bool _systemRoleIsAllowed(Message message) =>
    message.role != Role.system ||
    AgentContextProvenance.fromMetadata(_messageMetadata(message))
        .mayUseSystemRole;

Map<String, Object?>? _messageMetadata(Message message) {
  final metadata = message.metadata;

  return metadata == null ? null : Map<String, Object?>.of(metadata);
}

List<sdk.InputContentBlock> _changes(
  Message message, {
  required bool enabled,
}) {
  if (!enabled) return const [];
  final blocks = message.metadata?['anthropicToolChanges'];
  if (blocks is! List<Map<String, dynamic>>) return const [];

  return blocks.map(sdk.InputContentBlock.fromJson).toList();
}

String _mergedUpdateText(Message previous, Message update) => [
  _text(previous),
  _text(update),
].where((text) => text.isNotEmpty).join('\n');

Map<String, Object?> _mergedUpdateMetadata(
  Message previous,
  Message update, {
  required bool supportsToolDeltas,
}) {
  final provenance = AgentContextProvenance.fromMetadata(
    _messageMetadata(previous),
  );
  final changes = [
    ..._changes(previous, enabled: supportsToolDeltas),
    ..._changes(update, enabled: supportsToolDeltas),
  ];

  return provenance.withMetadata({
    'anthropicToolChanges': changes.map((block) => block.toJson()).toList(),
  });
}

extension _AnthropicHistoryProjection on AnthropicRequestEncoder {
  _Projection _project(ModelRequest request) {
    if (entries.isEmpty ||
        (!supportsToolDeltas && !supportsMidConversationSystemMessages)) {
      return _fallback(request);
    }
    final initial = _initialContext();
    final history = _history(request.messages);
    final messages = _initialMessages(history, initial);
    _appendHistoryUpdates(history, messages, _toolsByName(initial.tools));

    return _projectionResult(request, messages, initial);
  }

  AgentTranscriptContextState _initialContext() {
    final first = entries.firstOrNull?.update;
    if (first == null) {
      throw const AnthropicRequestException('missing_initial_context');
    }
    final _ = foldAgentTranscriptContext(entries.map((entry) => entry.update));

    return foldAgentTranscriptContext([first]);
  }

  _Projection _projectionResult(
    ModelRequest request,
    List<Message> messages,
    AgentTranscriptContextState initial,
  ) => (
    messages: messages,
    tools: supportsToolDeltas
        ? initial.tools.map(_tool).toList()
        : _fallback(request).tools,
    hasDeltas: supportsToolDeltas && entries.skip(1).any(_hasToolChanges),
  );
}

extension _AnthropicTranscriptHistory on AnthropicRequestEncoder {
  List<Message> _history(List<Message> messages) => messages
      .where(
        (message) =>
            !supportsMidConversationSystemMessages ||
            message.metadata?['transcriptContext'] != true,
      )
      .toList();

  List<Message> _initialMessages(
    List<Message> history,
    AgentTranscriptContextState initial,
  ) {
    final fixedSystem = history
        .takeWhile((message) => message.role == Role.system)
        .toList();
    history.removeRange(0, fixedSystem.length);

    return [
      ...fixedSystem,
      if (supportsMidConversationSystemMessages)
        ...initial.contextMessages.map(_contextMessage),
    ];
  }

  void _appendHistoryUpdates(
    List<Message> history,
    List<Message> messages,
    Map<String, ToolSpec> seen,
  ) {
    final applied = <AgentTranscriptContextEntry>{};
    for (var index = 0; index < history.length; index++) {
      messages.add(history[index]);
      _appendUpdatesAfterMessage((
        history: history,
        index: index,
        messages: messages,
        seen: seen,
        applied: applied,
      ));
    }
    _checkPositionCount(applied.length);
  }

  void _appendUpdatesAfterMessage(_UpdatesAfterMessageRequest request) {
    for (final entry in _entriesAfterMessage(
      request.history,
      request.index,
    )) {
      _AnthropicUpdateProjection(this)._appendEntryUpdates(
        entry,
        request.messages,
        request.seen,
      );
      final _ = request.applied.add(entry);
    }
  }

  void _checkPositionCount(int applied) {
    if (applied != entries.length - 1) {
      throw const AnthropicRequestException('missing_change_position');
    }
  }

  Iterable<AgentTranscriptContextEntry> _entriesAfterMessage(
    List<Message> history,
    int index,
  ) {
    final id = history[index].metadata?['transcriptMessageId'];
    if (id == null) return const [];
    if (index + 1 < history.length &&
        history[index + 1].metadata?['transcriptMessageId'] == id) {
      return const [];
    }

    return entries.skip(1).where((entry) => entry.afterMessageId == id);
  }
}

extension _AnthropicUpdateProjection on AnthropicRequestEncoder {
  void _appendEntryUpdates(
    AgentTranscriptContextEntry entry,
    List<Message> messages,
    Map<String, ToolSpec> seen,
  ) {
    for (final update in _updateMessages(entry.update, seen)) {
      _appendUpdate(messages, update);
    }
  }

  void _appendUpdate(List<Message> messages, Message update) {
    if (_text(update).isEmpty &&
        _changes(update, enabled: supportsToolDeltas).isEmpty) {
      return;
    }
    if (messages.last.role != Role.system ||
        !_sameProvenance(messages.last, update)) {
      messages.add(update);

      return;
    }
    final previous = messages.removeLast();
    messages.add(_mergeUpdates(previous, update));
  }

  Message _mergeUpdates(Message previous, Message update) => Message(
    role: .system,
    content: [TextPart(text: _mergedUpdateText(previous, update))],
    metadata: _mergedUpdateMetadata(
      previous,
      update,
      supportsToolDeltas: supportsToolDeltas,
    ),
  );

  List<Message> _updateMessages(
    AgentTranscriptContextUpdate update,
    Map<String, ToolSpec> seen,
  ) {
    final knownNames = seen.keys.toSet();
    _checkDefinitions(update.toolsAdded, seen);
    final messages = _contextMessages(update);
    final toolDeltaMessage = _toolDeltaMessage(update, knownNames);
    if (toolDeltaMessage != null) messages.add(toolDeltaMessage);

    return messages;
  }

  List<Message> _contextMessages(AgentTranscriptContextUpdate update) {
    if (!supportsMidConversationSystemMessages) return const [];
    final contextMessages =
        update.contextMessages ?? const <AgentContextMessage>[];
    final messages = contextMessages.map(_contextMessage).toList();
    final orderedMessages = <Message>[];

    // Anthropic permits mid-conversation system messages only after user data.
    for (final message in messages) {
      if (message.role != Role.system) {
        orderedMessages.add(message);
      }
    }
    for (final message in messages) {
      if (message.role == Role.system) {
        orderedMessages.add(message);
      }
    }

    return orderedMessages;
  }

  Message? _toolDeltaMessage(
    AgentTranscriptContextUpdate update,
    Set<String> knownNames,
  ) {
    if (!supportsToolDeltas) return null;
    final changes = _toolChanges(update, knownNames);
    if (changes.isEmpty) return null;

    return Message(
      role: .system,
      content: const [],
      metadata: AgentContextProvenance.applicationPrompt.withMetadata({
        'anthropicToolChanges': changes,
      }),
    );
  }

  bool _sameProvenance(Message left, Message right) =>
      AgentContextProvenance.fromMetadata(_messageMetadata(left)) ==
      AgentContextProvenance.fromMetadata(_messageMetadata(right));
}

_Projection _fallback(ModelRequest request) => (
  messages: request.messages,
  tools: [
    for (final tool in request.tools ?? <ToolDefinition>[]) _genkitTool(tool),
  ],
  hasDeltas: false,
);

Message _contextMessage(AgentContextMessage message) => Message(
  role: message.role == .system && message.provenance.mayUseSystemRole
      ? Role.system
      : Role.user,
  content: [TextPart(text: message.content)],
  metadata: message.provenance.withMetadata(const {}),
);

bool _hasToolChanges(AgentTranscriptContextEntry entry) =>
    entry.update.toolsAdded.isNotEmpty || entry.update.toolsRemoved.isNotEmpty;

void _checkDefinitions(List<ToolSpec> added, Map<String, ToolSpec> seen) {
  for (final tool in added) {
    final previous = seen[tool.name];
    if (previous != null && previous != tool) {
      throw const AnthropicRequestException('tool_redefinition');
    }
    seen[tool.name] = tool;
  }
}

List<Map<String, dynamic>> _toolChanges(
  AgentTranscriptContextUpdate update,
  Set<String> knownNames,
) => [
  for (final name in update.toolsRemoved)
    {
      'type': 'tool_removal',
      'tool': {'type': 'tool_reference', 'name': name},
    },
  for (final tool in update.toolsAdded)
    {'type': 'tool_addition', 'tool': _addition(tool, knownNames)},
];

Map<String, dynamic> _addition(ToolSpec tool, Set<String> knownNames) =>
    knownNames.contains(tool.name)
    ? {'type': 'tool_reference', 'name': tool.name}
    : {'type': 'tool_definition', 'definition': _tool(tool)};

Map<String, dynamic> _tool(ToolSpec tool) => {
  'name': tool.name,
  'description': tool.description,
  'input_schema': tool.inputJsonSchema,
};
Map<String, dynamic> _genkitTool(ToolDefinition tool) => {
  'name': tool.name,
  'description': tool.description,
  'input_schema': {'type': 'object', ...?tool.inputSchema},
};
String _text(Message message) => message.content
    .where((part) => part.isText)
    .map((part) => part.text)
    .nonNulls
    .join('\n');

Map<String, dynamic> _generationOptions(ModelRequest request) {
  final config = request.config ?? const <String, dynamic>{};

  return {
    'max_tokens': config['maxTokens'] ?? 4096,
    'temperature': ?config['temperature'],
    'top_p': ?config['topP'],
    'top_k': ?config['topK'],
    'stop_sequences': ?config['stopSequences'],
    'thinking': ?_thinking(config['thinking']),
    'output_config': ?config['outputConfig'],
    'tool_choice': ?_toolChoice(request.toolChoice),
  };
}

Map<String, dynamic>? _toolChoice(ToolChoice? choice) {
  final value = choice?.value;
  if (value == null) return null;
  if (value == 'required') return {'type': 'any'};
  if (['auto', 'any', 'none'].contains(value)) return {'type': value};

  return {'type': 'tool', 'name': value};
}

Map<String, dynamic>? _thinking(Object? value) {
  if (value is! Map<String, dynamic>) return null;

  return {
    'type': value['type'] ?? 'enabled',
    'budget_tokens': ?value['budgetTokens'],
  };
}

void _validatePlacement(List<sdk.InputMessage> messages) {
  for (var index = 0; index < messages.length; index++) {
    if (messages[index].role != sdk.MessageRole.system) continue;
    if (!_validSystemPosition(messages, index)) {
      throw const AnthropicRequestException('invalid_system_position');
    }
  }
}

bool _validSystemPosition(List<sdk.InputMessage> messages, int index) =>
    index > 0 &&
    messages[index - 1].role == sdk.MessageRole.user &&
    (index + 1 == messages.length ||
        messages[index + 1].role == sdk.MessageRole.assistant);

Map<String, ToolSpec> _toolsByName(List<ToolSpec> tools) => {
  for (final tool in tools) tool.name: tool,
};
