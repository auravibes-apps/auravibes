import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses one hook for each supported lifecycle event', () {
    final config = parseAgentLifecycleHookConfig('''
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
      () => parseAgentLifecycleHookConfig('''
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
      () => parseAgentLifecycleHookConfig(
        '{"version":1,"hooks":[],"shell":true}',
      ),
      throwsA(isA<AgentLifecycleHookConfigException>()),
    );
  });

  test('rejects command and argument bounds', () {
    expect(
      () => parseAgentLifecycleHookConfig('''
        {"version":1,"hooks":[
          {"event":"beforeTool","command":"a","args":["${'x' * (maxAgentLifecycleHookArgBytes + 1)}"]}
        ]}
      '''),
      throwsA(isA<AgentLifecycleHookConfigException>()),
    );
    expect(
      () => parseAgentLifecycleHookConfig('''
        {"version":1,"hooks":[
          {"event":"beforeTurn","command":"a","args":[]}
        ]}
      '''),
      throwsA(isA<AgentLifecycleHookConfigException>()),
    );
  });
}
