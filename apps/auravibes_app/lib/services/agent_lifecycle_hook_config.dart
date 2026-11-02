import 'dart:convert';

const int maxAgentLifecycleHookConfigBytes = 32 * 1024;
const maxAgentLifecycleHooks = 2;
const maxAgentLifecycleHookArgs = 16;
const maxAgentLifecycleHookArgBytes = 2048;
const maxAgentLifecycleHookSourceFiles = 8;
const agentLifecycleHookTimeout = Duration(seconds: 5);
const maxAgentLifecycleHookOutputBytes = 8192;

class const AgentLifecycleHookConfig({
  required final List<AgentLifecycleHookDefinition> hooks,
  final List<String> sourceFiles = const [],
}) {
  AgentLifecycleHookDefinition? hookFor(AgentLifecycleHookEvent event) {
    for (final hook in hooks) {
      if (hook.event == event) return hook;
    }

    return null;
  }
}

enum AgentLifecycleHookEvent { beforeTool, afterTool }

class const AgentLifecycleHookDefinition({
  required final AgentLifecycleHookEvent event,
  required final String command,
  required final List<String> args,
});

class AgentLifecycleHookConfigException implements Exception {
  const new(this.code);

  final String code;

  @override
  String toString() => code;
}

AgentLifecycleHookConfig parseAgentLifecycleHookConfig(String source) {
  final decoded = _decodeConfig(source);
  final rawHooks = decoded['hooks'] as List<Object?>;
  if (rawHooks.length > maxAgentLifecycleHooks) {
    throw const AgentLifecycleHookConfigException('too_many_hooks');
  }
  final sourceFiles = _parseSourceFiles(decoded['sourceFiles']);

  return .new(hooks: _parseHooks(rawHooks), sourceFiles: sourceFiles);
}

Map<String, dynamic> _decodeConfig(String source) {
  _validateConfigSize(source);
  final decoded = _decodeJson(source);
  if (decoded is! Map<String, dynamic> || !_isConfigShape(decoded)) {
    throw const AgentLifecycleHookConfigException('invalid_config');
  }

  return decoded;
}

void _validateConfigSize(String source) {
  if (source.length > maxAgentLifecycleHookConfigBytes ||
      utf8.encode(source).length > maxAgentLifecycleHookConfigBytes) {
    throw const AgentLifecycleHookConfigException('config_too_large');
  }
}

Object? _decodeJson(String source) {
  try {
    return jsonDecode(source);
  } on FormatException catch (_, stackTrace) {
    Error.throwWithStackTrace(
      const AgentLifecycleHookConfigException('invalid_json'),
      stackTrace,
    );
  }
}

bool _isConfigShape(Map<String, dynamic> value) =>
    _hasOnlyKeys(value, const {'version', 'hooks', 'sourceFiles'}) &&
    value['version'] == 1 &&
    value['hooks'] is List<Object?>;

bool _hasOnlyKeys(Map<String, dynamic> value, Set<String> keys) =>
    value.keys.toSet().difference(keys).isEmpty;

List<String> _parseSourceFiles(Object? raw) {
  final sources = raw ?? const <Object?>[];
  if (sources is! List<Object?> ||
      sources.length > maxAgentLifecycleHookSourceFiles) {
    throw const AgentLifecycleHookConfigException('invalid_source_files');
  }
  if (!sources.every(_isSourcePath)) {
    throw const AgentLifecycleHookConfigException('invalid_source_files');
  }

  return sources.cast<String>();
}

bool _isSourcePath(Object? value) =>
    value is String && value.trim().isNotEmpty && !value.contains('\u0000');

List<AgentLifecycleHookDefinition> _parseHooks(List<Object?> rawHooks) {
  final hooks = <AgentLifecycleHookDefinition>[];
  final events = <AgentLifecycleHookEvent>{};
  for (final raw in rawHooks) {
    final hook = _parseHook(raw);
    if (!events.add(hook.event)) {
      throw const AgentLifecycleHookConfigException('duplicate_event');
    }
    hooks.add(hook);
  }

  return hooks;
}

AgentLifecycleHookDefinition _parseHook(Object? raw) {
  if (raw is! Map<String, dynamic> ||
      !_hasOnlyKeys(raw, const {'event', 'command', 'args'})) {
    throw const AgentLifecycleHookConfigException('invalid_hook');
  }
  final event = _parseEvent(raw['event']);
  final command = _parseCommand(raw['command']);

  return .new(
    event: event,
    command: command,
    args: _parseArguments(raw['args']),
  );
}

AgentLifecycleHookEvent _parseEvent(Object? raw) => switch (raw) {
  'beforeTool' => .beforeTool,
  'afterTool' => .afterTool,
  _ => throw const AgentLifecycleHookConfigException('unsupported_event'),
};

String _parseCommand(Object? raw) {
  if (raw is! String || !_isSourcePath(raw)) {
    throw const AgentLifecycleHookConfigException('invalid_hook');
  }

  return raw;
}

List<String> _parseArguments(Object? raw) {
  if (raw is! List<Object?> || raw.length > maxAgentLifecycleHookArgs) {
    throw const AgentLifecycleHookConfigException('invalid_hook');
  }

  return raw.map(_parseArgument).toList();
}

String _parseArgument(Object? raw) {
  if (raw is! String || raw.contains('\u0000')) {
    throw const AgentLifecycleHookConfigException('invalid_hook_argument');
  }
  if (utf8.encode(raw).length > maxAgentLifecycleHookArgBytes) {
    throw const AgentLifecycleHookConfigException('invalid_hook_argument');
  }

  return raw;
}
