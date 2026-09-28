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
}
