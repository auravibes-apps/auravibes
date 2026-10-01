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

  void _appendWireMessage(Message message, _WireMessages wire) {
    if (message.role != Role.system) {
      wire.messages.add(AnthropicMessageCodec.encode(message));
    } else if (_isLeading(message, wire.messages)) {
      wire.leading.add(_text(message));
    } else {
      wire.messages.add(sdk.InputMessage.systemBlocks(_systemBlocks(message)));
    }
  }

  bool _isLeading(Message message, List<sdk.InputMessage> messages) =>
      messages.isEmpty ||
      (!supportsMidConversationSystemMessages && _changes(message).isEmpty);

  List<sdk.InputContentBlock> _systemBlocks(Message message) => [
    if (supportsMidConversationSystemMessages && _text(message).isNotEmpty)
      sdk.TextInputBlock(_text(message)),
    ..._changes(message),
  ];

  List<sdk.InputContentBlock> _changes(Message message) {
    if (!supportsToolDeltas) return const [];
    final blocks = message.metadata?['anthropicToolChanges'];
    if (blocks is! List<Map<String, dynamic>>) return const [];

    return blocks.map(sdk.InputContentBlock.fromJson).toList();
  }
}

extension on AnthropicRequestEncoder {
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

extension on AnthropicRequestEncoder {
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
      for (final entry in _entriesAfterMessage(history, index)) {
        _appendUpdate(messages, _updateMessage(entry.update, seen));
        final _ = applied.add(entry);
      }
    }
    _checkPositionCount(applied.length);
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

  void _appendUpdate(List<Message> messages, Message update) {
    if (_text(update).isEmpty && _changes(update).isEmpty) return;
    if (messages.last.role != Role.system) {
      messages.add(update);

      return;
    }
    final previous = messages.removeLast();
    messages.add(_mergeUpdates(previous, update));
  }

  Message _mergeUpdates(Message previous, Message update) => Message(
    role: .system,
    content: [
      TextPart(
        text: [
          _text(previous),
          _text(update),
        ].where((text) => text.isNotEmpty).join('\n'),
      ),
    ],
    metadata: {
      'anthropicToolChanges': [
        ..._changes(previous),
        ..._changes(update),
      ].map((block) => block.toJson()).toList(),
    },
  );

  Message _updateMessage(
    AgentTranscriptContextUpdate update,
    Map<String, ToolSpec> seen,
  ) {
    final knownNames = seen.keys.toSet();
    _checkDefinitions(update.toolsAdded, seen);

    return Message(
      role: .system,
      content: [TextPart(text: _contextText(update))],
      metadata: {
        'anthropicToolChanges': supportsToolDeltas
            ? _toolChanges(update, knownNames)
            : <Map<String, dynamic>>[],
      },
    );
  }

  String _contextText(AgentTranscriptContextUpdate update) =>
      supportsMidConversationSystemMessages
      ? update.contextMessages?.map((message) => message.content).join('\n') ??
            ''
      : '';
}

_Projection _fallback(ModelRequest request) => (
  messages: request.messages,
  tools: [
    for (final tool in request.tools ?? <ToolDefinition>[]) _genkitTool(tool),
  ],
  hasDeltas: false,
);

Message _contextMessage(AgentContextMessage message) => Message(
  role: message.role == .system ? Role.system : Role.user,
  content: [TextPart(text: message.content)],
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

Map<String, dynamic>? _toolChoice(String? choice) {
  if (choice == null) return null;
  if (['auto', 'any', 'none'].contains(choice)) return {'type': choice};

  return {'type': 'tool', 'name': choice};
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
