import 'dart:convert';

const maxAgentLifecycleHookConfigBytes = 32 * 1024;
const maxAgentLifecycleHooks = 2;
const maxAgentLifecycleHookArgs = 16;
const maxAgentLifecycleHookArgBytes = 2048;
const maxAgentLifecycleHookSourceFiles = 8;
const agentLifecycleHookTimeout = Duration(seconds: 5);
const maxAgentLifecycleHookOutputBytes = 8192;

enum AgentLifecycleHookEvent { beforeTool, afterTool }

class const AgentLifecycleHookDefinition({
  required final AgentLifecycleHookEvent event,
  required final String command,
  required final List<String> args,
});

class const AgentLifecycleHookConfig({
  required final List<AgentLifecycleHookDefinition> hooks,
  final List<String> sourceFiles = const [],
}) {
  AgentLifecycleHookDefinition? hookFor(AgentLifecycleHookEvent event) =>
      hooks.where((hook) => hook.event == event).firstOrNull;
}

class AgentLifecycleHookConfigException implements Exception {
  const AgentLifecycleHookConfigException(this.code);

  final String code;

  @override
  String toString() => code;
}

AgentLifecycleHookConfig parseAgentLifecycleHookConfig(String source) {
  if (source.length > maxAgentLifecycleHookConfigBytes) {
    throw const AgentLifecycleHookConfigException('config_too_large');
  }
  if (utf8.encode(source).length > maxAgentLifecycleHookConfigBytes) {
    throw const AgentLifecycleHookConfigException('config_too_large');
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    throw const AgentLifecycleHookConfigException('invalid_json');
  }
  if (decoded is! Map<String, dynamic> ||
      decoded.keys.toSet().difference({
        'version',
        'hooks',
        'sourceFiles',
      }).isNotEmpty ||
      decoded['version'] != 1 ||
      decoded['hooks'] is! List<Object?>) {
    throw const AgentLifecycleHookConfigException('invalid_config');
  }

  final rawHooks = decoded['hooks']! as List<Object?>;
  if (rawHooks.length > maxAgentLifecycleHooks) {
    throw const AgentLifecycleHookConfigException('too_many_hooks');
  }

  final rawSourceFiles = decoded['sourceFiles'] ?? const <Object?>[];
  if (rawSourceFiles is! List<Object?> ||
      rawSourceFiles.length > maxAgentLifecycleHookSourceFiles ||
      rawSourceFiles.any(
        (path) =>
            path is! String || path.trim().isEmpty || path.contains('\u0000'),
      )) {
    throw const AgentLifecycleHookConfigException('invalid_source_files');
  }

  final hooks = <AgentLifecycleHookDefinition>[];
  final events = <AgentLifecycleHookEvent>{};
  for (final rawHook in rawHooks) {
    final hook = _parseHook(rawHook);
    if (!events.add(hook.event)) {
      throw const AgentLifecycleHookConfigException('duplicate_event');
    }
    hooks.add(hook);
  }

  return AgentLifecycleHookConfig(
    hooks: hooks,
    sourceFiles: rawSourceFiles.cast<String>(),
  );
}

AgentLifecycleHookDefinition _parseHook(Object? rawHook) {
  if (rawHook is! Map<String, dynamic> ||
      rawHook.keys.toSet().difference({
        'event',
        'command',
        'args',
      }).isNotEmpty) {
    throw const AgentLifecycleHookConfigException('invalid_hook');
  }

  final event = switch (rawHook['event']) {
    'beforeTool' => AgentLifecycleHookEvent.beforeTool,
    'afterTool' => AgentLifecycleHookEvent.afterTool,
    _ => throw const AgentLifecycleHookConfigException('unsupported_event'),
  };
  final command = rawHook['command'];
  final rawArgs = rawHook['args'];
  if (command is! String ||
      command.trim().isEmpty ||
      command.contains('\u0000') ||
      rawArgs is! List<Object?> ||
      rawArgs.length > maxAgentLifecycleHookArgs) {
    throw const AgentLifecycleHookConfigException('invalid_hook');
  }
  final args = <String>[];
  for (final rawArg in rawArgs) {
    if (rawArg is! String ||
        rawArg.contains('\u0000') ||
        utf8.encode(rawArg).length > maxAgentLifecycleHookArgBytes) {
      throw const AgentLifecycleHookConfigException('invalid_hook_argument');
    }
    args.add(rawArg);
  }

  return AgentLifecycleHookDefinition(
    event: event,
    command: command,
    args: args,
  );
}

extension on Iterable<AgentLifecycleHookDefinition> {
  AgentLifecycleHookDefinition? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;

    return iterator.current;
  }
}
