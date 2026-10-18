import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('suppresses output on success and preserves spaced arguments', () async {
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'tool/run_quiet.dart',
      '--',
      Platform.resolvedExecutable,
      'run',
      'tool/run_quiet_fixture.dart',
      'success',
      'argument with spaces',
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(result.stdout, contains('Command succeeded.'));
    expect(result.stdout, isNot(contains('fixture stdout')));
    expect(result.stderr, isNot(contains('fixture stderr')));
  });

  test('replays both streams and preserves failure exit code', () async {
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'tool/run_quiet.dart',
      '--',
      Platform.resolvedExecutable,
      'run',
      'tool/run_quiet_fixture.dart',
      'failure',
      'argument with spaces',
    ]);

    expect(result.exitCode, 7);
    expect(result.stdout, contains('fixture stdout'));
    expect(result.stderr, contains('fixture stderr'));
  });

  test('rejects malformed wrapper arguments', () async {
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'tool/run_quiet.dart',
      '--',
    ]);

    expect(result.exitCode, isNot(0));
    expect(result.stderr, isNotEmpty);
  });

  test('keeps only the last 64 KiB of each failing stream', () async {
    final process = await _startFixture('large-failure');
    final output = process.stdout.transform(utf8.decoder).join();
    final errors = process.stderr.transform(utf8.decoder).join();

    expect(await process.exitCode, 7);
    final outputText = await output;
    final errorText = await errors;
    expect(outputText.length, 64 * 1024);
    expect(errorText.length, 64 * 1024);
    expect(outputText, '${'o' * (64 * 1024 - 11)}stdout end\n');
    expect(errorText, '${'e' * (64 * 1024 - 11)}stderr end\n');
  });

  test('streams both channels before exit without replay on failure', () async {
    final root = await Directory.systemTemp.createTemp('run-quiet-stream-');
    addTearDown(() => root.delete(recursive: true));
    final gate = File('${root.path}/continue');
    final process = await _startFixture(
      'stream',
      stream: true,
      args: [gate.path],
    );
    addTearDown(process.kill);
    final stdoutReady = Completer<void>();
    final stderrReady = Completer<void>();
    var output = '';
    var errors = '';
    final outputDone = process.stdout.transform(utf8.decoder).forEach((chunk) {
      output += chunk;
      if (output.contains('stdout ready') && !stdoutReady.isCompleted) {
        stdoutReady.complete();
      }
    });
    final errorsDone = process.stderr.transform(utf8.decoder).forEach((chunk) {
      errors += chunk;
      if (errors.contains('stderr ready') && !stderrReady.isCompleted) {
        stderrReady.complete();
      }
    });
    var exited = false;
    final exit = process.exitCode.then((code) {
      exited = true;

      return code;
    });
    await Future.wait([stdoutReady.future, stderrReady.future])
        .timeout(const Duration(seconds: 10));
    expect(exited, isFalse);
    await gate.writeAsString('continue');
    expect(await exit, 7);
    await Future.wait([outputDone, errorsDone]);
    expect(output, 'stdout ready\nstdout end\n');
    expect(errors, 'stderr ready\nstderr end\n');
  });

  for (final signal in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
    test(
      'forwards ${signal.name}, waits for child cleanup and preserves its code',
      () async {
        final root = await Directory.systemTemp.createTemp('run-quiet-signal-');
        addTearDown(() => root.delete(recursive: true));
        final ready = File('${root.path}/ready');
        final process = await _startFixture(
          'interrupt',
          args: [signal.name, ready.path],
        );
        final output = process.stdout.transform(utf8.decoder).join();
        final errors = process.stderr.transform(utf8.decoder).join();
        addTearDown(() async {
          process.kill(.sigkill);
          if (ready.existsSync()) {
            Process.killPid(int.parse(await ready.readAsString()), .sigkill);
          }
        });
        await (() async {
          while (!ready.existsSync()) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        })().timeout(const Duration(seconds: 10));

        expect(process.kill(signal), isTrue);
        expect(await process.exitCode.timeout(const Duration(seconds: 10)), 23);
        expect(await output, 'received ${signal.name}\n');
        expect(await errors, 'child cleanup\n');
      },
      skip: Platform.isWindows ? 'POSIX signal semantics' : false,
    );
  }

  test('closes child stdin like Process.run', () async {
    final process = await _startFixture('stdin-eof');
    addTearDown(process.kill);
    final output = process.stdout.transform(utf8.decoder).join();
    final errors = process.stderr.transform(utf8.decoder).join();

    expect(await process.exitCode.timeout(const Duration(seconds: 10)), 0);
    expect(await output, 'Command succeeded.\n');
    expect(await errors, isEmpty);
  });
}

Future<Process> _startFixture(
  String mode, {
  bool stream = false,
  List<String> args = const [],
}) => Process.start(Platform.resolvedExecutable, [
  'tool/run_quiet.dart',
  if (stream) '--stream',
  '--',
  Platform.resolvedExecutable,
  'tool/run_quiet_fixture.dart',
  mode,
  ...args,
]);
