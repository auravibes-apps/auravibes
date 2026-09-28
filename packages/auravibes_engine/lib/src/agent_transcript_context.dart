import 'package:auravibes_engine/src/tool_spec.dart';

enum AgentContextMessageRole { system, skill }

class const AgentContextMessage({
  required final AgentContextMessageRole role,
  required final String content,
  final String? kind,
});

/// One immutable change to the trusted prompt and model-visible tool catalog.
class AgentTranscriptContextUpdate({
  List<AgentContextMessage>? contextMessages,
  List<ToolSpec> toolsAdded = const [],
  List<String> toolsRemoved = const [],
  List<String>? toolOrder,
  Map<String, String>? approvalStates,
}) {
  final List<AgentContextMessage>? contextMessages = contextMessages == null
      ? null
      : List.unmodifiable(contextMessages);
  final List<ToolSpec> toolsAdded = List.unmodifiable(toolsAdded);
  final List<String> toolsRemoved = List.unmodifiable(toolsRemoved);
  final List<String>? toolOrder = toolOrder == null
      ? null
      : List.unmodifiable(toolOrder);
  final Map<String, String>? approvalStates = approvalStates == null
      ? null
      : Map.unmodifiable(approvalStates);
}

class AgentTranscriptContextState({
  List<AgentContextMessage> contextMessages = const [],
  List<ToolSpec> tools = const [],
  Map<String, String> approvalStates = const {},
}) {
  final List<AgentContextMessage> contextMessages = List.unmodifiable(
    contextMessages,
  );
  final List<ToolSpec> tools = List.unmodifiable(tools);
  final Map<String, String> approvalStates = Map.unmodifiable(approvalStates);
}

/// An update's position in the conversation, before the next model response.
class const AgentTranscriptContextEntry({
  required final String? afterMessageId,
  required final AgentTranscriptContextUpdate update,
});

class const AgentTranscriptContextException(final String reason)
    implements Exception {
  @override
  String toString() => 'Invalid transcript context: $reason';
}

AgentTranscriptContextUpdate? diffAgentTranscriptContext(
  AgentTranscriptContextState previous,
  AgentTranscriptContextState current,
) {
  final before = _uniqueTools(previous.tools);
  final after = _uniqueTools(current.tools);
  final removed = [
    for (final tool in previous.tools)
      if (after[tool.name] != tool) tool.name,
  ];
  final added = [
    for (final tool in current.tools)
      if (before[tool.name] != tool) tool,
  ];
  final beforeOrder = previous.tools.map((tool) => tool.name).toList();
  final afterOrder = current.tools.map((tool) => tool.name).toList();
  final toolsChanged =
      removed.isNotEmpty ||
      added.isNotEmpty ||
      !_sameStrings(beforeOrder, afterOrder);
  final messagesChanged = !_sameMessages(
    previous.contextMessages,
    current.contextMessages,
  );
  final approvalsChanged = !_sameApprovals(
    previous.approvalStates,
    current.approvalStates,
  );
  if (!toolsChanged && !messagesChanged && !approvalsChanged) return null;

  return AgentTranscriptContextUpdate(
    contextMessages: messagesChanged ? current.contextMessages : null,
    toolsAdded: added,
    toolsRemoved: removed,
    toolOrder: toolsChanged ? afterOrder : null,
    approvalStates: approvalsChanged ? current.approvalStates : null,
  );
}

AgentTranscriptContextState foldAgentTranscriptContext(
  Iterable<AgentTranscriptContextUpdate> updates,
) {
  var messages = const <AgentContextMessage>[];
  var approvalStates = const <String, String>{};
  final tools = <String, ToolSpec>{};
  for (final update in updates) {
    messages = update.contextMessages ?? messages;
    approvalStates = update.approvalStates ?? approvalStates;
    for (final name in update.toolsRemoved) {
      if (tools.remove(name) == null) {
        throw AgentTranscriptContextException('unknown tool removal: $name');
      }
    }
    for (final tool in update.toolsAdded) {
      if (tools.containsKey(tool.name)) {
        throw AgentTranscriptContextException('duplicate tool: ${tool.name}');
      }
      tools[tool.name] = tool;
    }
    final order = update.toolOrder;
    if (order != null) {
      if (order.length != tools.length ||
          order.toSet().length != order.length ||
          !order.every(tools.containsKey)) {
        throw const AgentTranscriptContextException('invalid tool order');
      }
      final ordered = {for (final name in order) name: tools[name]!};
      tools
        ..clear()
        ..addAll(ordered);
    }
  }
  return AgentTranscriptContextState(
    contextMessages: messages,
    tools: tools.values.toList(),
    approvalStates: approvalStates,
  );
}

AgentTranscriptContextUpdate snapshotAgentTranscriptContext(
  AgentTranscriptContextState state,
) => AgentTranscriptContextUpdate(
  contextMessages: state.contextMessages,
  toolsAdded: state.tools,
  toolOrder: state.tools.map((tool) => tool.name).toList(),
  approvalStates: state.approvalStates,
);

Map<String, ToolSpec> _uniqueTools(List<ToolSpec> tools) {
  final byName = <String, ToolSpec>{};
  for (final tool in tools) {
    if (byName.containsKey(tool.name)) {
      throw AgentTranscriptContextException('duplicate tool: ${tool.name}');
    }
    byName[tool.name] = tool;
  }
  return byName;
}

bool _sameMessages(
  List<AgentContextMessage> left,
  List<AgentContextMessage> right,
) =>
    left.length == right.length &&
    Iterable<int>.generate(left.length).every(
      (index) =>
          left[index].role == right[index].role &&
          left[index].content == right[index].content &&
          left[index].kind == right[index].kind,
    );

bool _sameStrings(List<String> left, List<String> right) =>
    left.length == right.length &&
    Iterable<int>.generate(left.length)
        .every((index) => left[index] == right[index]);

bool _sameApprovals(Map<String, String> left, Map<String, String> right) =>
    left.length == right.length &&
    left.entries.every((entry) => right[entry.key] == entry.value);
