import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter/widgets.dart';

/// Raw owner input remains editable when validation or a network probe fails.
class ScopedVerificationFormDraft {
  new(this.saved)
    : enabled = saved.enabled,
      runnerToolId = saved.runnerToolId,
      mcpServerId = saved.mcpServerId,
      editToolIds = Set.of(saved.editToolIds),
      root = TextEditingController(text: saved.workspaceRoot),
      timeout = TextEditingController(text: _seconds(saved.timeout)),
      output = TextEditingController(text: '${saved.maxOutputBytes}'),
      repairs = TextEditingController(text: '${saved.maxRepairAttempts}'),
      checks = [
        for (final check in saved.checks) ScopedVerificationCheckDraft(check),
      ] {
    _initialFingerprint = fingerprint;
  }

  final ScopedVerificationSettings saved;
  bool enabled;
  String runnerToolId;
  String mcpServerId;
  final Set<String> editToolIds;
  final TextEditingController root;
  final TextEditingController timeout;
  final TextEditingController output;
  final TextEditingController repairs;
  final List<ScopedVerificationCheckDraft> checks;
  String _initialFingerprint = '';

  bool get isDirty => fingerprint != _initialFingerprint;
  List<TextEditingController> get controllers => [
    root,
    timeout,
    output,
    repairs,
    for (final check in checks) ...check.controllers,
  ];
  String get fingerprint => jsonEncode({
    'enabled': enabled,
    'runner': runnerToolId,
    'server': mcpServerId,
    'edits': editToolIds.toList()..sort(),
    'root': root.text,
    'timeout': timeout.text,
    'output': output.text,
    'repairs': repairs.text,
    'checks': [
      for (final check in checks)
        [for (final controller in check.controllers) controller.text],
    ],
  });

  ScopedVerificationSettings read() => ScopedVerificationSettings(
    enabled: enabled,
    revision: saved.revision,
    runnerToolId: runnerToolId,
    mcpServerId: mcpServerId,
    workspaceRoot: root.text,
    editToolIds: editToolIds,
    checks: checks.map((check) => check.read()).toList(),
    timeout: _parseSeconds(timeout.text),
    maxOutputBytes: _integer(output.text),
    maxRepairAttempts: _integer(repairs.text),
  );

  void listen(VoidCallback edited) {
    for (final controller in controllers) {
      controller.addListener(edited);
    }
  }

  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
  }
}

class ScopedVerificationCheckDraft {
  new(ScopedVerificationCheck check)
    : id = TextEditingController(text: check.id),
      executable = TextEditingController(text: check.executable),
      arguments = TextEditingController(
        text: check.arguments.isEmpty ? '' : '${check.arguments.join('\n')}\n',
      ),
      suffixes = TextEditingController(text: check.pathSuffixes.join('\n'));

  new blank(String identifier)
    : id = TextEditingController(text: identifier),
      executable = TextEditingController(),
      arguments = TextEditingController(),
      suffixes = TextEditingController();

  final TextEditingController id;
  final TextEditingController executable;
  final TextEditingController arguments;
  final TextEditingController suffixes;

  List<TextEditingController> get controllers => [
    id,
    executable,
    arguments,
    suffixes,
  ];

  ScopedVerificationCheck read() => ScopedVerificationCheck(
    id: id.text,
    executable: executable.text,
    arguments: _arguments(arguments.text),
    pathSuffixes: suffixes.text
        .split('\n')
        .where((line) => line.isNotEmpty)
        .toList(),
  );

  void listen(VoidCallback edited) {
    for (final controller in controllers) {
      controller.addListener(edited);
    }
  }

  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
  }
}

int _integer(String source) =>
    int.tryParse(source.trim()) ??
    (throw const FormatException('Invalid verification number.'));

List<String> _arguments(String source) {
  if (source.isEmpty) return const [];
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  if (lines.lastOrNull == '') {
    final _ = lines.removeLast();
  }

  return lines;
}

String _seconds(Duration duration) {
  final seconds = duration.inMilliseconds ~/ Duration.millisecondsPerSecond;
  final fraction = (duration.inMilliseconds % Duration.millisecondsPerSecond)
      .toString()
      .padLeft(3, '0')
      .replaceFirst(RegExp(r'0+$'), '');

  return fraction.isEmpty ? '$seconds' : '$seconds.$fraction';
}

Duration _parseSeconds(String source) {
  final value = source.trim();
  if (!RegExp(r'^\d+(?:\.\d{1,3})?$').hasMatch(value))
    throw const FormatException('Invalid verification timeout.');
  final parts = value.split('.');
  final seconds = _integer(parts.firstOrNull ?? '');
  if (seconds > ScopedVerificationLimits.maxTimeout.inSeconds)
    throw const FormatException('Verification timeout exceeded.');
  final fraction = parts.length == 1
      ? 0
      : _integer(parts.last.padRight(3, '0'));

  return Duration(
    milliseconds: seconds * Duration.millisecondsPerSecond + fraction,
  );
}
