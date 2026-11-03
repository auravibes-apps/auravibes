import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('persisted defaults require a separate explicit enable action', () {
    final settings = ScopedVerificationSettings();
    final restored = ScopedVerificationSettings.decode(settings.encode());
    expect(restored.enabled, isFalse);
    expect(restored.checks, isEmpty);
    expect(restored.timeout, const Duration(seconds: 30));
    expect(restored.maxOutputBytes, 16384);
    expect(restored.maxRepairAttempts, 1);
  });

  test('enabled settings need all owner-configured bindings', () {
    expect(
      () => ScopedVerificationSettings(enabled: true),
      throwsFormatException,
    );
    expect(
      () => ScopedVerificationSettings(
        enabled: true,
        runnerToolId: 'runner',
        mcpServerId: 'server',
        workspaceRoot: 'root',
        editToolIds: const {'edit'},
      ),
      throwsFormatException,
    );
    expect(
      () => _settings(editToolIds: const {'runner'}),
      throwsFormatException,
    );
  });

  test(
    'round-trips saved argv separately from paths without interpolation',
    () {
      final settings = _settings();
      final restored = ScopedVerificationSettings.decode(settings.encode());
      expect(restored.enabled, isTrue);
      expect(restored.workspaceRoot, 'checkout');
      expect(restored.checks.single.arguments, ['analyze', '--fatal-infos']);
      expect(restored.checks.single.executable, 'dart');
      expect(restored.editToolIds, {'edit'});
    },
  );

  test('freezes settings and check collections at construction', () {
    final args = ['analyze'];
    final suffixes = ['.dart'];
    final check = ScopedVerificationCheck(
      id: 'dart',
      executable: 'dart',
      arguments: args,
      pathSuffixes: suffixes,
    );
    final checks = [check];
    final ids = {'edit'};
    final settings = ScopedVerificationSettings(
      editToolIds: ids,
      checks: checks,
    );
    args.add('malicious');
    suffixes.add('.sh');
    checks.clear();
    ids.clear();
    expect(settings.checks.single.arguments, ['analyze']);
    expect(settings.checks.single.pathSuffixes, ['.dart']);
    expect(settings.editToolIds, {'edit'});
    expect(settings.checks.clear, throwsUnsupportedError);
  });

  test(
    'rejects invalid or excessive runtime, output, repair and check limits',
    () {
      for (final milliseconds in [0, -1, 120001]) {
        expect(
          () => ScopedVerificationSettings(
            timeout: Duration(milliseconds: milliseconds),
          ),
          throwsFormatException,
        );
      }
      for (final bytes in [0, -1, 65537]) {
        expect(
          () => ScopedVerificationSettings(maxOutputBytes: bytes),
          throwsFormatException,
        );
      }
      for (final attempts in [-1, 3]) {
        expect(
          () => ScopedVerificationSettings(maxRepairAttempts: attempts),
          throwsFormatException,
        );
      }
      expect(
        () => ScopedVerificationSettings(
          checks: [
            for (var i = 0; i < 9; i++)
              ScopedVerificationCheck(id: 'c$i', executable: 'check'),
          ],
        ),
        throwsFormatException,
      );
      expect(
        () => ScopedVerificationSettings(
          checks: [
            ScopedVerificationCheck(id: 'same', executable: 'check'),
            ScopedVerificationCheck(id: 'same', executable: 'other'),
          ],
        ),
        throwsFormatException,
      );
    },
  );

  test('rejects unrecognized configuration and malformed scalar types', () {
    final json = jsonDecode(_settings().encode()) as Map<String, dynamic>;
    expect(
      () => ScopedVerificationSettings.decode(
        jsonEncode({...json, 'shell': true}),
      ),
      throwsFormatException,
    );
    for (final entry in <String, Object?>{
      'enabled': 'true',
      'timeoutMs': 1.5,
      'checks': 'dart',
      'editToolIds': [false],
      'revision': -1,
    }.entries) {
      expect(
        () => ScopedVerificationSettings.decode(
          jsonEncode({...json, entry.key: entry.value}),
        ),
        throwsFormatException,
      );
    }
    expect(
      () => ScopedVerificationSettings.decode(' ' * 32769),
      throwsFormatException,
    );
  });

  test('rejects shell strings masquerading as argv and unsafe check data', () {
    for (final executable in ['', 'dart\u0000', 'dart\n']) {
      expect(
        () => ScopedVerificationCheck(id: 'check', executable: executable),
        throwsFormatException,
      );
    }
    expect(
      () => ScopedVerificationCheck(
        id: 'check',
        executable: 'dart',
        arguments: const ['a\u0000b'],
      ),
      throwsFormatException,
    );
    expect(
      () => ScopedVerificationCheck.fromJson({
        'id': 'check',
        'executable': 'dart',
        'arguments': 'analyze && touch marker',
        'pathSuffixes': <String>[],
      }),
      throwsFormatException,
    );
  });

  test('all result states survive bounded model and storage serialization', () {
    for (final state in ScopedVerificationOutcome.values) {
      final result = ScopedVerificationResult(
        outcome: state,
        reason: 'fixture',
        output: 'diagnostic',
        checkIds: const ['dart'],
        paths: const ['lib/main.dart'],
      );
      final json = result.toJson();
      expect(json['state'], state.name);
      expect(json['output'], 'diagnostic');
      expect(json['checkIds'], ['dart']);
      expect(json['repairAllowed'], isFalse);
      expect(json['repairAttemptsRemaining'], 0);
      final restored = ScopedVerificationResult.fromJson(json);
      expect(restored.outcome, state);
      expect(restored.toJson(), json);
    }
  });

  test('bounds UTF-8 output without breaking a code point', () {
    final result = ScopedVerificationResult(
      outcome: .fail,
      reason: 'nonzero_exit',
      output: 'éé🙂tail',
      maxOutputBytes: 7,
      repairAttemptsRemaining: 1,
    );
    expect(result.output, 'éé');
    expect(utf8.encode(result.output).length, lessThanOrEqualTo(7));
    expect(result.originalOutputBytes, 12);
    expect(result.outputTruncated, isTrue);
    expect(result.repairAllowed, isTrue);
    expect(result.toJson()['output'], 'éé');
  });

  test('a result never grants repair for cancelled or incomplete work', () {
    for (final state in <ScopedVerificationOutcome>[
      .pass,
      .skipped,
      .cancelled,
      .incomplete,
    ]) {
      final result = ScopedVerificationResult(
        outcome: state,
        reason: 'fixture',
        repairAttemptsRemaining: 1,
      );
      expect(result.repairAllowed, isFalse);
    }
  });

  test('stored results cannot forge repair authority or truncation state', () {
    final json = ScopedVerificationResult(
      outcome: .incomplete,
      reason: 'timeout',
    ).toJson();
    for (final entry in <String, Object?>{
      'state': 'success',
      'repairAllowed': true,
      'originalOutputBytes': -1,
      'outputTruncated': 'false',
      'command': 'execute',
    }.entries) {
      expect(
        () => ScopedVerificationResult.fromJson({
          ...json,
          entry.key: entry.value,
        }),
        throwsFormatException,
      );
    }
  });
}

ScopedVerificationSettings _settings({
  Set<String> editToolIds = const {'edit'},
}) => ScopedVerificationSettings(
  enabled: true,
  runnerToolId: 'runner',
  mcpServerId: 'server',
  workspaceRoot: 'checkout',
  editToolIds: editToolIds,
  checks: [
    ScopedVerificationCheck(
      id: 'dart',
      executable: 'dart',
      arguments: const ['analyze', '--fatal-infos'],
      pathSuffixes: const ['.dart'],
    ),
  ],
);
