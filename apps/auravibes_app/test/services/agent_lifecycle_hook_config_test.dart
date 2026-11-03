import 'dart:convert';

import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('configuration accepts its exact byte limit and rejects one more', () {
    const minimal = '{"version":1,"hooks":[]}';
    final bounded = minimal +
        ' ' *
            (AgentLifecycleHookConfig.maxAgentLifecycleHookConfigBytes -
                minimal.length);
    expect(AgentLifecycleHookConfig.parse(bounded).hooks, isEmpty);
    expect(
      () => AgentLifecycleHookConfig.parse('$bounded '),
      _configError('config_too_large'),
    );
  });

  test('configuration and arguments use UTF-8 byte limits', () {
    final accented = String.fromCharCode(0xe9);
    final emoji = String.fromCharCode(0x1f600);
    final oversizedConfig = jsonEncode({
      'version': 1,
      'hooks': <Object?>[],
      'sourceFiles': [accented * 16384],
    });
    expect(
      oversizedConfig.length,
      lessThan(AgentLifecycleHookConfig.maxAgentLifecycleHookConfigBytes),
    );
    expect(
      () => AgentLifecycleHookConfig.parse(oversizedConfig),
      _configError('config_too_large'),
    );
    final valid = _configWithHook(args: [emoji * 512]);
    expect(
      AgentLifecycleHookConfig.parse(valid).hooks.single.args.single,
      emoji * 512,
    );
    expect(
      () => AgentLifecycleHookConfig.parse(
        _configWithHook(args: [emoji * 513]),
      ),
      _configError('invalid_hook_argument'),
    );
  });

  final invalidConfigs = <String, String>{
    '{': 'invalid_json',
    '{"version":2,"hooks":[]}': 'invalid_config',
    '{"version":1,"hooks":[],"shell":true}': 'invalid_config',
    '{"version":1,"hooks":[{},{},{}]}': 'too_many_hooks',
    '{"version":1,"hooks":[],"sourceFiles":[null]}': 'invalid_source_files',
    jsonEncode({
      'version': 1,
      'hooks': <Object?>[],
      'sourceFiles': List.filled(9, 'file'),
    }): 'invalid_source_files',
    _configWithHook(event: 'beforeTurn'): 'unsupported_event',
    _configWithHook(command: 'a\u0000b'): 'invalid_hook',
    _configWithHook(args: ['a\u0000b']): 'invalid_hook_argument',
    _configWithHook(args: .filled(17, 'arg')): 'invalid_hook',
    _configWithHook(extra: {'result': 'replacement'}): 'invalid_hook',
  };
  for (final entry in invalidConfigs.entries) {
    test('rejects invalid configuration with ${entry.value}: ${entry.key}', () {
      expect(
        () => AgentLifecycleHookConfig.parse(entry.key),
        _configError(entry.value),
      );
    });
  }

  test('parses one hook for each supported lifecycle event', () {
    final config = AgentLifecycleHookConfig.parse('''
      {
        "version": 1,
        "sourceFiles": ["hooks/policy.py"],
        "hooks": [
          {"event": "beforeTool", "command": "./before", "args": []},
          {"event": "afterTool", "command": "/usr/bin/after", "args": ["--json"]}
        ]
      }
    ''');

    expect(config.hooks, hasLength(2));
    expect(config.hooks.first.event, AgentLifecycleHookEvent.beforeTool);
    expect(config.hooks.last.args, ['--json']);
    expect(config.sourceFiles, ['hooks/policy.py']);
  });

  test('rejects duplicate events and unsupported fields', () {
    expect(
      () => AgentLifecycleHookConfig.parse('''
        {"version":1,"hooks":[
          {"event":"beforeTool","command":"a","args":[]},
          {"event":"beforeTool","command":"b","args":[]}
        ]}
      '''),
      throwsA(
        isA<AgentLifecycleHookConfigException>().having(
          (error) => error.code,
          'code',
          'duplicate_event',
        ),
      ),
    );
    expect(
      () => AgentLifecycleHookConfig.parse(
        '{"version":1,"hooks":[],"shell":true}',
      ),
      throwsA(isA<AgentLifecycleHookConfigException>()),
    );
  });

  test('rejects command and argument bounds', () {
    expect(
      () => AgentLifecycleHookConfig.parse('''
        {"version":1,"hooks":[
          {"event":"beforeTool","command":"a","args":["${'x' * (AgentLifecycleHookConfig.maxAgentLifecycleHookArgBytes + 1)}"]}
        ]}
      '''),
      throwsA(isA<AgentLifecycleHookConfigException>()),
    );
    expect(
      () => AgentLifecycleHookConfig.parse('''
        {"version":1,"hooks":[
          {"event":"beforeTurn","command":"a","args":[]}
        ]}
      '''),
      throwsA(isA<AgentLifecycleHookConfigException>()),
    );
  });
}

Matcher _configError(String code) => throwsA(
  isA<AgentLifecycleHookConfigException>().having(
    (error) => error.code,
    'code',
    code,
  ),
);

String _configWithHook({
  String event = 'beforeTool',
  String command = './hook',
  List<String> args = const [],
  Map<String, Object?> extra = const {},
}) => jsonEncode({
  'version': 1,
  'hooks': [
    {'event': event, 'command': command, 'args': args, ...extra},
  ],
});
