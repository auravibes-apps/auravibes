import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime_api.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime_io.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final runtime = const IoAgentLifecycleHookRuntime();
  final supported = Platform.isLinux || Platform.isMacOS;
  final pythonAvailable = supported && File('/usr/bin/python3').existsSync();

  test('stderr secrets are discarded on both success and failure', () async {
    for (final exitCode in [0, 1]) {
      final fixture = await _HookFixture.create('/usr/bin/python3');
      addTearDown(fixture.dispose);
      final result = await fixture.invoke(
        runtime,
        args: [
          '-c',
          'import sys; print(\'{"decision":"allow"}\'); '
              'sys.stderr.write("token=private-stderr-secret"); sys.exit($exitCode)',
        ],
      );
      expect(
        result.outcome,
        exitCode == 0
            ? AgentToolHookOutcome.success
            : AgentToolHookOutcome.failed,
      );
      expect(result.stdout, exitCode == 0 ? '{"decision":"allow"}\n' : isNull);
      expect(result.stdout, isNot(contains('private-stderr-secret')));
    }
  }, skip: !pythonAvailable);

  for (final count in [8192, 8193]) {
    test('combined stdout and stderr boundary $count bytes', () async {
      final fixture = await _HookFixture.create('/usr/bin/python3');
      addTearDown(fixture.dispose);
      final result = await fixture.invoke(
        runtime,
        args: [
          '-c',
          'import sys; sys.stdout.buffer.write(b"x" * 4096); '
              'sys.stderr.buffer.write(b"y" * ${count - 4096})',
        ],
      );

      expect(
        result.outcome,
        count == 8192
            ? AgentToolHookOutcome.success
            : AgentToolHookOutcome.outputLimitExceeded,
      );
      expect(result.stdout, count == 8192 ? 'x' * 4096 : isNull);
    }, skip: !pythonAvailable);
  }

  test('UTF-8 output is counted in bytes rather than characters', () async {
    final fixture = await _HookFixture.create('/usr/bin/python3');
    addTearDown(fixture.dispose);
    final result = await fixture.invoke(
      runtime,
      args: [
        '-c',
        'import sys; sys.stdout.buffer.write(bytes([240,159,152,128]) * 2049)',
      ],
    );
    expect(result.outcome, AgentToolHookOutcome.outputLimitExceeded);
    expect(result.stdout, isNull);
  }, skip: !pythonAvailable);

  test('invalid UTF-8 is a failure without captured output', () async {
    final fixture = await _HookFixture.create('/usr/bin/python3');
    addTearDown(fixture.dispose);
    final result = await fixture.invoke(
      runtime,
      args: ['-c', 'import sys; sys.stdout.buffer.write(bytes([255]))'],
    );
    expect(result.outcome, AgentToolHookOutcome.failed);
    expect(result.stdout, isNull);
  }, skip: !pythonAvailable);

  test('pre-cancelled invocation never launches the command', () async {
    final fixture = await _HookFixture.create('/usr/bin/python3');
    addTearDown(fixture.dispose);
    final marker = File('${fixture.directory.path}/executed');
    final result = await fixture.invoke(
      runtime,
      args: [
        '-c',
        'from pathlib import Path; Path(${jsonEncode(marker.path)}).touch()',
      ],
      isCancelled: () => true,
    );
    expect(result.outcome, AgentToolHookOutcome.cancelled);
    expect(await marker.exists(), isFalse);
    expect(result.stdout, isNull);
  }, skip: !pythonAvailable);

  test('output after cancellation cannot replace the cancelled outcome', () async {
    final fixture = await _HookFixture.create('/usr/bin/python3');
    addTearDown(fixture.dispose);
    final ready = File('${fixture.directory.path}/ready');
    final result = await fixture.invoke(
      runtime,
      args: [
        '-c',
        'import signal,sys,time; from pathlib import Path; '
            'signal.signal(signal.SIGTERM, lambda *_: '
            '(sys.stdout.write("x" * 9000), sys.stdout.flush(), sys.exit(0))); '
            'Path(${jsonEncode(ready.path)}).touch(); time.sleep(10)',
      ],
      isCancelled: ready.existsSync,
    );
    expect(result.outcome, AgentToolHookOutcome.cancelled);
    expect(result.stdout, isNull);
  }, skip: !pythonAvailable);

  test('unclosed child output pipes do not return partial success', () async {
    final fixture = await _HookFixture.create('/usr/bin/python3');
    addTearDown(fixture.dispose);
    final childPid = File('${fixture.directory.path}/child-pid');
    addTearDown(() async {
      if (await childPid.exists()) {
        final _ = Process.killPid(
          int.parse(await childPid.readAsString()),
          ProcessSignal.sigkill,
        );
      }
    });
    final stopwatch = Stopwatch()..start();
    final result = await fixture.invoke(
      runtime,
      args: [
        '-c',
        'import subprocess; from pathlib import Path; '
            'child = subprocess.Popen(["/usr/bin/python3", "-c", '
            '"import time; time.sleep(10)"]); '
            'Path(${jsonEncode(childPid.path)}).write_text(str(child.pid)); '
            'print(\'{"decision":"allow"}\', flush=True)',
      ],
    );
    expect(result.outcome, AgentToolHookOutcome.failed);
    expect(result.stdout, isNull);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
  }, skip: !pythonAvailable);

  for (final change in ['config', 'executable', 'symlink', 'missing']) {
    test('changed $change is rejected before command launch', () async {
      final fixture = await _HookFixture.create(
        '/usr/bin/printf',
        copyCommand: true,
      );
      addTearDown(fixture.dispose);
      final configFile = File(fixture.snapshot.canonicalPath);
      switch (change) {
        case 'config':
          await configFile.writeAsString('{"version":1,"hooks":[]}');
        case 'executable':
          await File(fixture.hook.command).writeAsString('changed executable');
        case 'symlink':
          final target = File('${fixture.directory.path}/replacement.json');
          await configFile.copy(target.path);
          await configFile.delete();
          await Link(configFile.path).create(target.path);
        case 'missing':
          await File(fixture.hook.command).delete();
      }
      final result = await runtime.invoke(
        snapshot: fixture.snapshot,
        hook: fixture.hook,
        input: '{}',
        isCancellationRequested: (_) => false,
        conversationId: 'conversation-1',
      );
      expect(
        result.outcome,
        change == 'missing'
            ? AgentToolHookOutcome.failed
            : AgentToolHookOutcome.unavailable,
      );
      expect(result.stdout, isNull);
    }, skip: !supported || !File('/usr/bin/printf').existsSync());
  }

  test('executes trusted argv hook without rewriting its command', () async {
    final fixture = await _HookFixture.create('/usr/bin/printf');
    addTearDown(fixture.dispose);
    if (!supported || !File('/usr/bin/printf').existsSync()) return;

    final result = await fixture.invoke(
      runtime,
      args: ['{"decision":"allow"}'],
    );

    expect(result.outcome, AgentToolHookOutcome.success);
    expect(result.stdout, '{"decision":"allow"}');
  }, skip: !supported || !File('/usr/bin/printf').existsSync());

  test(
    'does not inherit process environment or evaluate shell syntax',
    () async {
      if (!supported || !File('/usr/bin/printf').existsSync()) return;
      final marker = File(
        '${Directory.systemTemp.path}/aura-hook-shell-marker',
      );
      if (await marker.exists()) await marker.delete();
      final fixture = await _HookFixture.create('/usr/bin/printf');
      addTearDown(fixture.dispose);
      final shellSyntax = r'$(touch ' + marker.path + ')';

      final result = await fixture.invoke(runtime, args: [shellSyntax]);

      expect(result.stdout, shellSyntax);
      expect(await marker.exists(), isFalse);
    },
    skip: !supported || !File('/usr/bin/printf').existsSync(),
  );

  test('starts commands with an empty inherited environment', () async {
    if (!supported || !File('/usr/bin/env').existsSync()) return;
    final fixture = await _HookFixture.create('/usr/bin/env');
    addTearDown(fixture.dispose);

    final result = await fixture.invoke(runtime, args: const []);

    expect(result.outcome, AgentToolHookOutcome.success);
    expect(result.stdout, isEmpty);
  }, skip: !supported || !File('/usr/bin/env').existsSync());

  test('rejects non-file command sources while inspecting config', () async {
    if (!runtime.isSupported) return;
    final directory = await Directory.systemTemp.createTemp('aura-hooks-');
    addTearDown(() async {
      await directory.delete(recursive: true);
    });
    final config = File('${directory.path}/hooks.json');
    await config.writeAsString(
      jsonEncode({
        'version': 1,
        'hooks': [
          {'event': 'beforeTool', 'command': directory.path, 'args': []},
        ],
      }),
    );

    await expectLater(
      runtime.inspect(config.path),
      throwsA(isA<AgentLifecycleHookConfigException>()),
    );
  });

  test('bounds combined process output while reading it', () async {
    if (!supported || !File('/usr/bin/yes').existsSync()) return;
    final fixture = await _HookFixture.create('/usr/bin/yes');
    addTearDown(fixture.dispose);

    final result = await fixture.invoke(runtime, args: const []);

    expect(result.outcome, AgentToolHookOutcome.outputLimitExceeded);
    expect(result.stdout, isNull);
  }, skip: !supported || !File('/usr/bin/yes').existsSync());

  test('stderr counts toward the combined output limit', () async {
    if (!supported || !File('/usr/bin/python3').existsSync()) return;
    final fixture = await _HookFixture.create('/usr/bin/python3');
    addTearDown(fixture.dispose);

    final result = await fixture.invoke(
      runtime,
      args: ['-c', 'import sys; sys.stderr.write("x" * 9000)'],
    );

    expect(result.outcome, AgentToolHookOutcome.outputLimitExceeded);
    expect(result.stdout, isNull);
  }, skip: !supported || !File('/usr/bin/python3').existsSync());

  test('reports a non-zero process exit as a hook failure', () async {
    if (!supported || !File('/usr/bin/false').existsSync()) return;
    final fixture = await _HookFixture.create('/usr/bin/false');
    addTearDown(fixture.dispose);

    final result = await fixture.invoke(runtime, args: const []);

    expect(result.outcome, AgentToolHookOutcome.failed);
  }, skip: !supported || !File('/usr/bin/false').existsSync());

  test('kills a timed out hook', () async {
    if (!supported || !File('/usr/bin/sleep').existsSync()) return;
    final fixture = await _HookFixture.create('/usr/bin/sleep');
    addTearDown(fixture.dispose);

    final stopwatch = Stopwatch()..start();
    final result = await fixture.invoke(runtime, args: const ['10']);

    expect(result.outcome, AgentToolHookOutcome.timedOut);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 6)));
  }, skip: !supported || !File('/usr/bin/sleep').existsSync());

  test('cancellation terminates an active hook process', () async {
    if (!supported || !File('/usr/bin/sleep').existsSync()) return;
    final fixture = await _HookFixture.create('/usr/bin/sleep');
    addTearDown(fixture.dispose);
    var cancelled = false;
    final cancellation = Timer(
      const Duration(milliseconds: 100),
      () => cancelled = true,
    );

    final result = await fixture.invoke(
      runtime,
      args: const ['10'],
      isCancelled: () => cancelled,
    );
    cancellation.cancel();

    expect(result.outcome, AgentToolHookOutcome.cancelled);
  }, skip: !supported || !File('/usr/bin/sleep').existsSync());

  test(
    'cancellation force-kills a hook that ignores graceful termination',
    () async {
      if (!supported || !File('/usr/bin/python3').existsSync()) return;
      final fixture = await _HookFixture.create('/usr/bin/python3');
      addTearDown(fixture.dispose);
      var cancelled = false;
      final cancellation = Timer(
        const Duration(milliseconds: 100),
        () => cancelled = true,
      );
      final stopwatch = Stopwatch()..start();

      final result = await fixture.invoke(
        runtime,
        args: [
          '-c',
          'import signal,time; signal.signal(signal.SIGTERM, signal.SIG_IGN); '
              'time.sleep(10)',
        ],
        isCancelled: () => cancelled,
      );
      cancellation.cancel();

      expect(result.outcome, AgentToolHookOutcome.cancelled);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    },
    skip: !supported || !File('/usr/bin/python3').existsSync(),
  );

  test(
    'changing a source file invalidates the inspected fingerprint',
    () async {
      if (!supported || !File('/usr/bin/printf').existsSync()) return;
      final fixture = await _HookFixture.create(
        '/usr/bin/printf',
        sourceFiles: const ['policy.json'],
      );
      addTearDown(fixture.dispose);
      final changedSource = File('${fixture.directory.path}/policy.json');
      await changedSource.writeAsString('{"version":2}');

      final result = await runtime.invoke(
        snapshot: fixture.snapshot,
        hook: fixture.hook,
        input: '{}',
        isCancellationRequested: (_) => false,
        conversationId: 'conversation-1',
      );

      expect(result.outcome, AgentToolHookOutcome.unavailable);
    },
    skip: !supported || !File('/usr/bin/printf').existsSync(),
  );
}

class _HookFixture {
  _HookFixture({
    required this.directory,
    required this.snapshot,
    required this.hook,
  });

  final Directory directory;
  final AgentLifecycleHookSourceSnapshot snapshot;
  final AgentLifecycleHookDefinition hook;

  static Future<_HookFixture> create(
    String command, {
    List<String> sourceFiles = const [],
    bool copyCommand = false,
  }) async {
    final directory = await Directory.systemTemp.createTemp('aura-hooks-');
    if (copyCommand) {
      command = (await File(command).copy('${directory.path}/command')).path;
    }
    final source = jsonEncode({
      'version': 1,
      'sourceFiles': sourceFiles,
      'hooks': [
        {'event': 'beforeTool', 'command': command, 'args': []},
      ],
    });
    final config = File('${directory.path}/hooks.json');
    await config.writeAsString(source);
    for (final sourceFile in sourceFiles) {
      await File('${directory.path}/$sourceFile').writeAsString('trusted');
    }
    final runtime = const IoAgentLifecycleHookRuntime();
    final snapshot = await runtime.inspect(config.path);

    return _HookFixture(
      directory: directory,
      snapshot: snapshot,
      hook: snapshot.config.hooks.single,
    );
  }

  Future<AgentLifecycleHookInvocationResult> invoke(
    IoAgentLifecycleHookRuntime runtime, {
    required List<String> args,
    bool Function()? isCancelled,
  }) async {
    final configuredHook = AgentLifecycleHookDefinition(
      event: hook.event,
      command: hook.command,
      args: args,
    );
    final configPath = File('${directory.path}/hooks.json');
    final source = jsonEncode({
      'version': 1,
      'hooks': [
        {'event': 'beforeTool', 'command': hook.command, 'args': args},
      ],
    });
    await configPath.writeAsString(source);
    final snapshot = await runtime.inspect(configPath.path);

    return await runtime.invoke(
      snapshot: snapshot,
      hook: configuredHook,
      input: '{}',
      isCancellationRequested: (_) => isCancelled?.call() ?? false,
      conversationId: 'conversation-1',
    );
  }

  Future<void> dispose() => directory.delete(recursive: true);
}
